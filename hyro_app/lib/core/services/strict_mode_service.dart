import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' hide NotificationVisibility;

import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';

/// The package name of our app — used to know when the user is inside Hyro.
const _hyroPackageName = 'com.hyro.hyro_app';

// ─── Foreground Task callback (must be top-level) ───────────────────────────

@pragma('vm:entry-point')
void strictModeTaskStartCallback() {
  debugPrint('[StrictMode][BG] strictModeTaskStartCallback() called');
  FlutterForegroundTask.setTaskHandler(StrictOverlayTaskHandler());
}

// ─── TaskHandler (runs in the foreground-service isolate) ───────────────────
// Runs in a SEPARATE Dart isolate. Platform channels like FlutterOverlayWindow
// do NOT work here. We use sendDataToMain() to talk to the main isolate,
// AND launchApp() to force the main engine back to life so it can process.

class StrictOverlayTaskHandler extends TaskHandler {
  String _lastForegroundPackage = '';
  DateTime _lastQueryTime = DateTime.now();
  bool _violationActive = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[StrictMode][BG] onStart() — starter: $starter');
    _lastQueryTime = DateTime.now();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final now = DateTime.now();
    final start = _lastQueryTime.subtract(const Duration(seconds: 2));
    _lastQueryTime = now;

    try {
      List<EventUsageInfo> events = await UsageStats.queryEvents(start, now);

      if (events.isEmpty) return;

      // Sort by timestamp descending to find the most recent event
      events.sort((a, b) => (b.timeStamp ?? '').compareTo(a.timeStamp ?? ''));

      for (var event in events) {
        // eventType '1' = MOVE_TO_FOREGROUND
        if (event.eventType == '1') {
          final pkg = event.packageName;
          if (pkg == null) break;

          final isHyro = pkg == _hyroPackageName;
          final isSystemUI = pkg.contains('launcher') ||
              pkg.contains('systemui') ||
              pkg.contains('inputmethod');

          if (!isHyro && !isSystemUI) {
            // User opened a different app
            if (_lastForegroundPackage != pkg) {
              _lastForegroundPackage = pkg;

              // Resolve human-readable name
              String appName = pkg;
              try {
                Application? app = await DeviceApps.getApp(pkg);
                if (app != null) appName = app.appName;
              } catch (_) {}

              debugPrint('[StrictMode][BG] ⚠️ VIOLATION! App: $appName ($pkg)');
              _violationActive = true;

              // Send violation to main isolate
              FlutterForegroundTask.sendDataToMain({
                'action': 'VIOLATION',
                'appName': appName,
                'packageName': pkg,
              });

              // Mandamos la app de vuelta al frente
              try {
                FlutterForegroundTask.wakeUpScreen();
                Future.delayed(const Duration(milliseconds: 200), () {
                  FlutterForegroundTask.launchApp();
                });
              } catch (e) {
                debugPrint('[StrictMode][BG] Error launching app: $e');
              }
            }
          } else if (isHyro && _violationActive) {
            debugPrint('[StrictMode][BG] User returned to Hyro');
            _lastForegroundPackage = pkg;
            _violationActive = false;
            FlutterForegroundTask.sendDataToMain({
              'action': 'RETURNED',
            });
          }
          _lastForegroundPackage = pkg;
          break; // only process the most recent foreground event
        }
      }
    } catch (e, stack) {
      debugPrint('[StrictMode][BG] ERROR: $e\n$stack');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[StrictMode][BG] onDestroy()');
  }
}

// ─── Service singleton (called from UI isolate) ─────────────────────────────

class StrictModeService {
  static final StrictModeService _instance = StrictModeService._internal();
  factory StrictModeService() => _instance;
  StrictModeService._internal();

  bool _isInitialized = false;
  void Function(Object)? _taskDataCallback;

  /// Initialise the foreground-task engine. Safe to call multiple times.
  Future<void> init() async {
    debugPrint('[StrictMode][UI] init() — isInitialized=$_isInitialized');
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'hyro_strict_mode',
        channelName: 'Hyro Modo Estricto',
        channelDescription: 'Monitorea tu enfoque para evitar distracciones.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(2000),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );
    _isInitialized = true;
    debugPrint('[StrictMode][UI] init() complete');
  }

  /// Returns `true` when both Usage Stats and Overlay permissions are granted.
  Future<bool> checkAndRequestPermissions() async {
    debugPrint('[StrictMode][UI] checkAndRequestPermissions()');
    if (!Platform.isAndroid) return false;

    // 1. Usage Stats
    bool? isUsageGranted = await UsageStats.checkUsagePermission();
    debugPrint('[StrictMode][UI] Usage Stats permission: $isUsageGranted');
    if (isUsageGranted != true) {
      debugPrint('[StrictMode][UI] Requesting Usage Stats permission...');
      await UsageStats.grantUsagePermission();
      return false;
    }

    // 2. System Alert Window (Required for Android 10+ to launch app from background)
    bool isOverlayGranted = await Permission.systemAlertWindow.isGranted;
    debugPrint('[StrictMode][UI] Overlay permission: $isOverlayGranted');
    if (!isOverlayGranted) {
      debugPrint('[StrictMode][UI] Requesting System Alert Window permission...');
      await Permission.systemAlertWindow.request();
      return false;
    }

    // 3. Ignore Battery Optimizations (required for background stability like Forest)
    bool isBatteryIgnoring = await Permission.ignoreBatteryOptimizations.isGranted;
    debugPrint('[StrictMode][UI] Battery Optimization Ignoring: $isBatteryIgnoring');
    if (!isBatteryIgnoring) {
      debugPrint('[StrictMode][UI] Requesting Ignore Battery Optimizations...');
      await Permission.ignoreBatteryOptimizations.request();
      // Usually battery optimizations popup takes you to settings, 
      // we return false so the user has to toggle again next time to verify
      return false;
    }
    
    debugPrint('[StrictMode][UI] ✅ All permissions granted!');
    return true;
  }

  /// Starts the foreground service that monitors app usage.
  /// [onViolationDetected] fires in the main isolate when the user leaves Hyro.
  Future<void> startStrictMonitoring(void Function(String appName) onViolationDetected) async {
    debugPrint('[StrictMode][UI] startStrictMonitoring()');
    if (!Platform.isAndroid) return;

    // Initialize the communication port BEFORE starting the service
    // This is REQUIRED for sendDataToMain() / addTaskDataCallback() to work
    FlutterForegroundTask.initCommunicationPort();
    debugPrint('[StrictMode][UI] Communication port initialized');

    await FlutterForegroundTask.startService(
      notificationTitle: 'Modo Estricto Activo',
      notificationText: 'Monitoreando para evitar distracciones.',
      callback: strictModeTaskStartCallback,
    );
    debugPrint('[StrictMode][UI] Foreground service started');

    // Listen for messages from the background TaskHandler.
    _taskDataCallback = (data) {
      debugPrint('[StrictMode][UI] 📩 Received data from BG: $data');

      if (data is Map) {
        final action = data['action'];

        if (action == 'VIOLATION') {
          final appName = data['appName'] as String? ?? 'otra app';
          debugPrint('[StrictMode][UI] ⚠️ Violation received — app: $appName');

          // Pause the timer when UI catches up
          onViolationDetected(appName);

        } else if (action == 'RETURNED') {
          debugPrint('[StrictMode][UI] User returned to Hyro.');
        }
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
    debugPrint('[StrictMode][UI] ✅ Task data callback registered, monitoring active!');
  }

  /// Stops the foreground service and dismisses any visible overlay.
  Future<void> stopStrictMonitoring() async {
    debugPrint('[StrictMode][UI] stopStrictMonitoring()');
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
      _taskDataCallback = null;
    }
    debugPrint('[StrictMode][UI] Stopped and cleaned up');
  }
}
