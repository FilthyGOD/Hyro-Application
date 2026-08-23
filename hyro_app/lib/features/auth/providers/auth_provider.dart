import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hyro/data/models/user_profile.dart';

// Importación condicional para código que usa dart:io
import 'package:hyro/features/auth/providers/auth_native.dart'
    if (dart.library.html) 'package:hyro/features/auth/providers/auth_web.dart'
    as auth_platform;

class AuthProvider extends ChangeNotifier {
  final dynamic isar; // Isar en nativo, null en web
  UserProfile? _currentUser;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<dynamic>? _linkSubscription;

  AuthProvider(this.isar) {
    _listenAuthChanges();
    if (!kIsWeb) {
      _linkSubscription = auth_platform.listenForDeepLinksPC();
    }
    _loadUserSession();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.isActivelyLoggedIn;

  bool get isGuest => _currentUser?.usernameOrEmail == 'guest_local';

  /// Devuelve el UUID del usuario en Supabase, o null si no tiene sesión iniciada vía Supabase.
  String? get supabaseUserId => Supabase.instance.client.auth.currentUser?.id;

  // ─── Listener de Autenticación de Supabase ──────────────────────────────────

  void _listenAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;
      debugPrint(
        '🚨 [Hyro Auth] Estado de auth cambió: $event, session: ${session != null ? "SÍ" : "NO"}',
      );

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint(
          '🚨 [Hyro Auth] signedIn detectado, sincronizando usuario: ${session.user.email}',
        );
        await _syncSupabaseUserToIsar(session.user);
        debugPrint(
          '🚨 [Hyro Auth] Sync completado. isGuest=$isGuest, isAuthenticated=$isAuthenticated, isLoading=$isLoading',
        );
      }
    });
  }

  /// Después del inicio de sesión OAuth con Supabase, crea/actualiza el usuario local en Isar
  /// y sincroniza el progreso local de invitado a la nube (solo en el primer inicio de sesión).
  bool _isSyncingUser = false;

  Future<void> _syncSupabaseUserToIsar(User supabaseUser) async {
    if (_isSyncingUser) return;
    _isSyncingUser = true;

    try {
      final email = supabaseUser.email ?? supabaseUser.id;
      final name =
          supabaseUser.userMetadata?['full_name'] as String? ??
          supabaseUser.userMetadata?['name'] as String? ??
          email.split('@').first;

      if (kIsWeb) {
        // En web no hay Isar — solo creamos el usuario en memoria
        _currentUser = UserProfile()
          ..usernameOrEmail = email
          ..name = name
          ..type = UserType.personal
          ..isActivelyLoggedIn = true;

        // Sincronizar gamificación con Supabase
        final isConnected = await _hasInternet();
        if (isConnected) {
          try {
            await Supabase.instance.client.rpc(
              'sincronizar_perfil_local',
              params: {
                'p_nivel': 1,
                'p_experiencia': 0,
                'p_monedas': 0,
                'p_compras_ids': <int>[],
              },
            );
          } catch (e) {
            debugPrint('⚠️ Error sincronizando gamificación en web: $e');
          }
        }

        _currentUser = _currentUser;
        _isLoading = false;
        _isSyncingUser = false;
        notifyListeners();
        return;
      }

      // ── Ruta nativa con Isar ──
      await auth_platform.syncSupabaseUserToIsar(
        isar: isar,
        supabaseUser: supabaseUser,
        email: email,
        name: name,
        onUserReady: (user) {
          _currentUser = user;
        },
        onLoadingDone: () {
          _isLoading = false;
          _isSyncingUser = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error crítico en _syncSupabaseUserToIsar: $e');
      _isLoading = false;
      _isSyncingUser = false;
      notifyListeners();
    }
  }

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    return auth_platform.hasInternet();
  }

  // ─── Cargar Sesión ──────────────────────────────────────────────────────────

  Future<void> _loadUserSession() async {
    _isLoading = true;
    notifyListeners();

    // 1. Verificar primero si hay una sesión activa de Supabase
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    if (supabaseSession != null) {
      await _syncSupabaseUserToIsar(Supabase.instance.client.auth.currentUser!);
      return;
    }

    if (kIsWeb) {
      // En web sin sesión de Supabase → invitado (pero obligamos login)
      await _loginAsGuest();
      return;
    }

    // ── Ruta nativa ──
    final activeUser = await auth_platform.findActiveUser(isar);

    await Future.delayed(const Duration(milliseconds: 500));

    if (activeUser != null) {
      _currentUser = activeUser;
      _isLoading = false;
      notifyListeners();
    } else {
      await _loginAsGuest();
    }
  }

  Future<void> _loginAsGuest() async {
    if (kIsWeb) {
      // En web, creamos un guest solo en memoria
      _currentUser = UserProfile()
        ..usernameOrEmail = 'guest_local'
        ..name = 'Invitado'
        ..type = UserType.personal
        ..isActivelyLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // ── Ruta nativa con Isar ──
    final guest = await auth_platform.loginAsGuest(isar);
    _currentUser = guest;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Métodos de Inicio de Sesión ──────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.toString() : 'io.supabase.hyroapp://login-callback/',
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Inicio de sesión real con email/contraseña usando Supabase
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session != null) {
        await _syncSupabaseUserToIsar(res.session!.user);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Registro real con email/contraseña usando Supabase
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (res.session != null) {
        await _syncSupabaseUserToIsar(res.session!.user);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Inicio de sesión local con email (comportamiento existente).
  Future<void> loginPersonal(String email, String name) async {
    _isLoading = true;
    notifyListeners();

    if (kIsWeb) {
      _currentUser = UserProfile()
        ..usernameOrEmail = email
        ..name = name
        ..type = UserType.personal
        ..isActivelyLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final user = await auth_platform.loginPersonal(isar, email, name);
    _currentUser = user;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Cierre de Sesión ────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!kIsWeb) {
        await auth_platform.cleanupNativeLogout(isar);
      }
    } catch (e) {
      debugPrint('Error durante el logout: $e');
    }

    if (_currentUser != null) {
      if (!kIsWeb && isar != null) {
        await auth_platform.clearIsarProfiles(isar);
      }
      _currentUser = null;
    }

    // Volver al modo invitado
    await _loginAsGuest();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
