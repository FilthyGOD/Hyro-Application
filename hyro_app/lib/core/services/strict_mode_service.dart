import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;

import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';

/// El package name de nuestra aplicación — usado para saber cuándo el usuario está dentro de Hyro.
const _hyroPackageName = 'com.hyro.hyro_app';

// ─── Callback de Foreground Task (debe ser de nivel superior) ───────────────────────────

@pragma('vm:entry-point')
void strictModeTaskStartCallback() {
  debugPrint('[StrictMode][BG] strictModeTaskStartCallback() called');
  FlutterForegroundTask.setTaskHandler(StrictOverlayTaskHandler());
}

// ─── TaskHandler (se ejecuta en el isolate del servicio en primer plano) ───────────────────
// Se ejecuta en un isolate Dart SEPARADO. Los platform channels como FlutterOverlayWindow
// NO funcionan aquí. Usamos sendDataToMain() para hablar con el isolate principal,
// Y launchApp() para forzar al motor principal a revivir para que pueda procesar.

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

      // Ordenar por marca de tiempo descendente para encontrar el evento más reciente
      events.sort((a, b) => (b.timeStamp ?? '').compareTo(a.timeStamp ?? ''));

      for (var event in events) {
        // eventType '1' = MOVE_TO_FOREGROUND (MOVER_AL_FRENTE)
        if (event.eventType == '1') {
          final pkg = event.packageName;
          if (pkg == null) break;

          final isHyro = pkg == _hyroPackageName;
          final isSystemUI =
              pkg.contains('launcher') ||
              pkg.contains('systemui') ||
              pkg.contains('inputmethod');

          if (!isHyro && !isSystemUI) {
            // El usuario abrió una app diferente
            if (_lastForegroundPackage != pkg) {
              _lastForegroundPackage = pkg;

              // Resolver nombre legible por humanos
              String appName = pkg;
              try {
                Application? app = await DeviceApps.getApp(pkg);
                if (app != null) appName = app.appName;
              } catch (_) {}

              debugPrint('[StrictMode][BG] ⚠️ VIOLATION! App: $appName ($pkg)');
              _violationActive = true;

              // Enviar violación al isolate principal
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
            FlutterForegroundTask.sendDataToMain({'action': 'RETURNED'});
          }
          _lastForegroundPackage = pkg;
          break; // solo procesar el evento de primer plano más reciente
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

// ─── Singleton del servicio (llamado desde el isolate de la UI) ─────────────────────────────

class StrictModeService {
  static final StrictModeService _instance = StrictModeService._internal();
  factory StrictModeService() => _instance;
  StrictModeService._internal();

  bool _isInitialized = false;
  void Function(Object)? _taskDataCallback;

  /// Inicializa el motor de tareas en primer plano. Seguro de llamar múltiples veces.
  Future<void> init() async {
    debugPrint('[StrictMode][UI] init() — isInitialized=$_isInitialized');
    if (_isInitialized) return;
    if (kIsWeb) return;

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

  /// Devuelve `true` cuando se otorgan los permisos de Estadísticas de Uso y Superposición.
  Future<bool> checkAndRequestPermissions() async {
    debugPrint('[StrictMode][UI] checkAndRequestPermissions()');
    if (kIsWeb || !Platform.isAndroid) return false;

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
      debugPrint(
        '[StrictMode][UI] Requesting System Alert Window permission...',
      );
      await Permission.systemAlertWindow.request();
      return false;
    }

    // 3. Ignore Battery Optimizations (required for background stability like Forest)
    bool isBatteryIgnoring =
        await Permission.ignoreBatteryOptimizations.isGranted;
    debugPrint(
      '[StrictMode][UI] Battery Optimization Ignoring: $isBatteryIgnoring',
    );
    if (!isBatteryIgnoring) {
      debugPrint('[StrictMode][UI] Requesting Ignore Battery Optimizations...');
      await Permission.ignoreBatteryOptimizations.request();
      // Usualmente el popup de optimización de batería te lleva a ajustes,
      // devolvemos falso para que el usuario tenga que alternar de nuevo la próxima vez para verificar
      return false;
    }

    debugPrint('[StrictMode][UI] ✅ All permissions granted!');
    return true;
  }

  /// Inicia el servicio en primer plano que monitorea el uso de la aplicación.
  /// [onViolationDetected] se dispara en el isolate principal cuando el usuario deja Hyro.
  Future<void> startStrictMonitoring(
    void Function(String appName) onViolationDetected,
  ) async {
    debugPrint('[StrictMode][UI] startStrictMonitoring()');
    if (kIsWeb || !Platform.isAndroid) return;

    // Inicializar el puerto de comunicación ANTES de iniciar el servicio
    // Esto es REQUERIDO para que sendDataToMain() / addTaskDataCallback() funcionen
    FlutterForegroundTask.initCommunicationPort();
    debugPrint('[StrictMode][UI] Communication port initialized');

    await FlutterForegroundTask.startService(
      notificationTitle: 'Modo Estricto Activo',
      notificationText: 'Monitoreando para evitar distracciones.',
      callback: strictModeTaskStartCallback,
    );
    debugPrint('[StrictMode][UI] Foreground service started');

    // Escuchar mensajes del TaskHandler en segundo plano.
    _taskDataCallback = (data) {
      debugPrint('[StrictMode][UI] 📩 Received data from BG: $data');

      if (data is Map) {
        final action = data['action'];

        if (action == 'VIOLATION') {
          final appName = data['appName'] as String? ?? 'otra app';
          debugPrint('[StrictMode][UI] ⚠️ Violation received — app: $appName');

          // Pausar el temporizador cuando la UI se ponga al día
          onViolationDetected(appName);
        } else if (action == 'RETURNED') {
          debugPrint('[StrictMode][UI] User returned to Hyro.');
        }
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
    debugPrint(
      '[StrictMode][UI] ✅ Task data callback registered, monitoring active!',
    );
  }

  /// Detiene el servicio en primer plano y descarta cualquier superposición visible.
  Future<void> stopStrictMonitoring() async {
    debugPrint('[StrictMode][UI] stopStrictMonitoring()');
    if (kIsWeb || !Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
      _taskDataCallback = null;
    }
    debugPrint('[StrictMode][UI] Stopped and cleaned up');
  }
}
