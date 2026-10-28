import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona las preferencias de notificaciones mediante SharedPreferences.
/// Desacoplado de la UI para poder ser reutilizado en servicios y providers.
class NotificationPrefsService {
  static const String _keyNotificationHour = 'notif_reminder_hour';
  static const String _keyNotificationMinute = 'notif_reminder_minute';
  static const String _keyNotificationsEnabled = 'notificationsEnabled';

  static const int defaultHour = 20; // 8:00 PM por defecto
  static const int defaultMinute = 0;

  /// Retorna la hora configurada para las notificaciones diarias (0-23).
  static Future<int> getNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNotificationHour) ?? defaultHour;
  }

  /// Retorna el minuto configurado para las notificaciones diarias (0-59).
  static Future<int> getNotificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNotificationMinute) ?? defaultMinute;
  }

  /// Guarda la hora y minuto para la notificación diaria.
  static Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotificationHour, hour);
    await prefs.setInt(_keyNotificationMinute, minute);
  }

  /// Retorna si las notificaciones están habilitadas.
  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Activa o desactiva las notificaciones.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// (Utilidad para desarrollo) Resetea todas las configuraciones de notificación.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotificationHour);
    await prefs.remove(_keyNotificationMinute);
    await prefs.remove(_keyNotificationsEnabled);
  }
}
