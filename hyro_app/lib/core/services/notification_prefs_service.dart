import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona las preferencias de notificaciones en-app mediante SharedPreferences.
/// Desacoplado de la UI para poder ser reutilizado en distintos widgets.
class NotificationPrefsService {
  static const String _keyUsernameFeatureCardDismissed =
      'notif_username_feature_dismissed';

  /// Retorna true si el usuario ya descarto la tarjeta de novedad de nombre de usuario.
  static Future<bool> isUsernameFeatureCardDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUsernameFeatureCardDismissed) ?? false;
  }

  /// Marca la tarjeta de novedad de nombre de usuario como descartada.
  static Future<void> dismissUsernameFeatureCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUsernameFeatureCardDismissed, true);
  }

  /// (Utilidad para desarrollo) Resetea todas las notificaciones descartadas.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsernameFeatureCardDismissed);
  }
}
