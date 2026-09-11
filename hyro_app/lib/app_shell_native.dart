import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';
import 'core/services/notifications_service.dart';

/// Agrega listeners de escritorio (window_manager, tray_manager) al estado.
void addDesktopListeners(dynamic state) {
  windowManager.addListener(state as WindowListener);
  trayManager.addListener(state as TrayListener);
  _initTray();
}

/// Quita listeners de escritorio.
void removeDesktopListeners(dynamic state) {
  windowManager.removeListener(state as WindowListener);
  trayManager.removeListener(state as TrayListener);
}

Future<void> _initTray() async {
  try {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/app_icon.ico'
          : 'assets/images/app_icon.png',
    );
    await trayManager.setToolTip('Hyro');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Abrir Hyro'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Salir (Cerrar notificaciones)'),
      ],
    );
    await trayManager.setContextMenu(menu);
  } catch (e) {
    debugPrint('Tray initialization error: $e');
  }
}

/// Programa notificaciones diarias (solo nativo).
Future<void> scheduleNotifications({
  required int pendingTaskCount,
  required int currentStreak,
  required bool hadSessionToday,
  required List<dynamic> pendingTasks,
}) async {
  await NotificationsService.instance.scheduleDailyNotifications(
    pendingTaskCount: pendingTaskCount,
    currentStreak: currentStreak,
    hadSessionToday: hadSessionToday,
  );

  // Programar recordatorios para tareas que vencen en 1-2 días
  final taskDueData =
      pendingTasks
          .where((t) => t.dueDate != null)
          .map((t) => {'id': t.id, 'title': t.title, 'dueDate': t.dueDate!})
          .toList();
  await NotificationsService.instance.scheduleTaskDueReminders(taskDueData);
}
