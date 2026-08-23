/// Stubs para web — no hay window_manager ni tray_manager en el navegador.

void addDesktopListeners(dynamic state) {
  // No-op en web
}

void removeDesktopListeners(dynamic state) {
  // No-op en web
}

Future<void> scheduleNotifications({
  required int pendingTaskCount,
  required int currentStreak,
  required bool hadSessionToday,
  required List<dynamic> pendingTasks,
}) async {
  // No-op en web — no hay notificaciones locales
}
