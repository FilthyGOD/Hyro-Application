import 'package:flutter/foundation.dart';

/// Stub de SpotifyAuthService para web — todas las operaciones son no-op.
class SpotifyAuthService extends ChangeNotifier {
  static final SpotifyAuthService _instance = SpotifyAuthService._internal();

  factory SpotifyAuthService() {
    return _instance;
  }

  SpotifyAuthService._internal();

  String? get accessToken => null;
  bool get isAuthenticated => false;

  Future<void> authenticate() async {
    debugPrint('[Spotify] Auth no disponible en web');
  }

  Future<void> logout() async {}

  void dispose() {
    super.dispose();
  }
}
