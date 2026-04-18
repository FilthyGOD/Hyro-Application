import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hyro_app/models/user_profile.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'package:hyro_app/data/sync/sync_service.dart';
import 'package:hyro_app/data/local/task_local_ds.dart';
import 'package:hyro_app/data/local/category_local_ds.dart';
import 'package:hyro_app/data/local/note_local_ds.dart';
import 'package:hyro_app/data/local/source_local_ds.dart';
import 'package:hyro_app/data/local/card_local_ds.dart';
import 'package:hyro_app/data/remote/task_remote_ds.dart';
import 'package:hyro_app/data/remote/category_remote_ds.dart';
import 'package:hyro_app/data/remote/note_remote_ds.dart';
import 'package:hyro_app/data/remote/source_remote_ds.dart';
import 'package:hyro_app/data/remote/card_remote_ds.dart';
import 'package:hyro_app/data/remote/file_storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyro_app/data/models/task_model.dart';
import 'package:hyro_app/data/models/daily_stats.dart';
import 'package:hyro_app/data/models/category_model.dart';
import 'package:hyro_app/data/models/tarea_nota_model.dart';
import 'package:hyro_app/data/models/tarea_fuente_model.dart';
import 'package:hyro_app/data/models/tarea_card_model.dart';

class AuthProvider extends ChangeNotifier {
  final Isar isar;
  UserProfile? _currentUser;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;

  AuthProvider(this.isar) {
    _listenAuthChanges();
    _listenForDeepLinksPC();
    _loadUserSession();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _currentUser != null && _currentUser!.isActivelyLoggedIn;
      
  bool get isGuest => _currentUser?.usernameOrEmail == 'guest_local';

  /// Returns the Supabase user UUID, or null if not signed in via Supabase.
  String? get supabaseUserId => Supabase.instance.client.auth.currentUser?.id;

  // ─── Supabase Auth Listener ───────────────────────────────────────

  void _listenAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        await _syncSupabaseUserToIsar(session.user);
      }
    });
  }

  /// After Supabase OAuth sign-in, create/update the local Isar user
  /// and sync local guest progress to the cloud (only on first sign-in).
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

      // 1. Capturar datos del guest local ANTES de cambiar usuarios
      final guestUser =
          await isar.userProfiles
              .filter()
              .usernameOrEmailEqualTo('guest_local')
              .findFirst();

      final localNivel = guestUser?.nivel ?? 1;
      final localExp = guestUser?.experiencia ?? 0;
      final localMonedas = guestUser?.monedas ?? 0;
      final localCompras = guestUser?.comprasLocales ?? [];

      // 2. Crear/actualizar el usuario Supabase en Isar
      final existingUser =
          await isar.userProfiles
              .filter()
              .usernameOrEmailEqualTo(email)
              .findFirst();

      final user =
          existingUser ?? UserProfile()
            ..usernameOrEmail = email
            ..name = name
            ..type = UserType.personal
            ..isActivelyLoggedIn = true;

      if (existingUser != null) {
        user.isActivelyLoggedIn = true;
        user.name = name;
      }

      await isar.writeTxn(() async {
        // Log out any other active users
        final activeUsers =
            await isar.userProfiles
                .filter()
                .isActivelyLoggedInEqualTo(true)
                .findAll();

        for (var u in activeUsers) {
          u.isActivelyLoggedIn = false;
          await isar.userProfiles.put(u);
        }

        await isar.userProfiles.put(user);
      });

      // 3. Sincronizar gamificación a Supabase (solo tiene efecto la primera vez)
      try {
        await Supabase.instance.client.rpc('sincronizar_perfil_local', params: {
          'p_nivel': localNivel,
          'p_experiencia': localExp,
          'p_monedas': localMonedas,
          'p_compras_ids': localCompras,
        });
        debugPrint('✅ Gamificación sincronizada (nivel: $localNivel)');
      } catch (e) {
        debugPrint('⚠️ Error sincronizando gamificación: $e');
      }

      // 4. Sincronizar tareas, categorías, notas, PDFs y flashcards
      try {
        final supabaseClient = Supabase.instance.client;
        final syncService = SyncService(
          categoryLocal: CategoryLocalDataSource(),
          taskLocal: TaskLocalDataSource(),
          noteLocal: NoteLocalDataSource(),
          sourceLocal: SourceLocalDataSource(),
          cardLocal: CardLocalDataSource(),
          categoryRemote: CategoryRemoteDataSource(supabaseClient),
          taskRemote: TaskRemoteDataSource(supabaseClient),
          noteRemote: NoteRemoteDataSource(supabaseClient),
          sourceRemote: SourceRemoteDataSource(supabaseClient),
          cardRemote: CardRemoteDataSource(supabaseClient),
          fileStorage: FileStorageService(supabaseClient),
        );

        final syncResult = await syncService.syncAllToRemote(supabaseUser.id);
        if (syncResult.success) {
          debugPrint('✅ Datos de tareas sincronizados: $syncResult');
        } else {
          debugPrint('⚠️ Sync parcial: ${syncResult.errors}');
        }

        final pullResult = await syncService.pullFromRemote(supabaseUser.id);
        if (pullResult.success) {
          debugPrint('✅ Datos remotos descargados: $pullResult');
        } else {
          debugPrint('⚠️ Pull parcial: ${pullResult.errors}');
        }
      } catch (e) {
        debugPrint('⚠️ Error sincronizando datos de tareas: $e');
      }

      _currentUser = user;
    } catch (e) {
      debugPrint('⚠️ Error crítico en _syncSupabaseUserToIsar: $e');
    } finally {
      _isLoading = false;
      _isSyncingUser = false;
      notifyListeners();
    }
  }

  // ─── Load Session ─────────────────────────────────────────────────

  Future<void> _loadUserSession() async {
    _isLoading = true;
    notifyListeners();

    // 1. Check for an active Supabase session first
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    if (supabaseSession != null) {
      await _syncSupabaseUserToIsar(Supabase.instance.client.auth.currentUser!);
      return; // _syncSupabaseUserToIsar already sets _isLoading = false
    }

    // 2. Fall back to local Isar user
    final activeUser =
        await isar.userProfiles
            .filter()
            .isActivelyLoggedInEqualTo(true)
            .findFirst();

    // Artificial delay for splash screen
    await Future.delayed(const Duration(seconds: 5));

    if (activeUser != null) {
      _currentUser = activeUser;
      _isLoading = false;
      notifyListeners();
    } else {
      await _loginAsGuest();
    }
  }

  Future<void> _loginAsGuest() async {
    final existingGuest = await isar.userProfiles
        .filter()
        .usernameOrEmailEqualTo('guest_local')
        .findFirst();

    final guest = existingGuest ?? UserProfile()
      ..usernameOrEmail = 'guest_local'
      ..name = 'Invitado'
      ..type = UserType.personal
      ..isActivelyLoggedIn = true;

    if (existingGuest != null) {
      guest.isActivelyLoggedIn = true;
    }

    await isar.writeTxn(() async {
      final activeUsers = await isar.userProfiles
          .filter()
          .isActivelyLoggedInEqualTo(true)
          .findAll();

      for (var u in activeUsers) {
        u.isActivelyLoggedIn = false;
        await isar.userProfiles.put(u);
      }
      await isar.userProfiles.put(guest);
    });

    _currentUser = guest;
    _isLoading = false;
    notifyListeners();
  }

  void _listenForDeepLinksPC() async {
    // Ignoramos móvil y web porque ahí jala nativo
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return;

    final appLinks = AppLinks();

    // 1. Radar inicial: Por si Windows abrió la app a través del link
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && initialUri.scheme == 'io.supabase.hyroapp') {
        debugPrint('🚨 [Hyro Debug] Link inicial atrapado: $initialUri');
        await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
      }
    } catch (e) {
      debugPrint('🚨 [Hyro Debug] Error leyendo link inicial: $e');
    }

    // 2. Radar de flujo: Por si Windows se lo manda a la app ya abierta
    _linkSubscription = appLinks.uriLinkStream.listen(
      (uri) async {
        if (uri.scheme != 'io.supabase.hyroapp') return;
        debugPrint('🚨 [Hyro Debug] Link atrapado en stream: $uri');
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        } catch (e) {
          debugPrint('🚨 [Hyro Debug] Error en Supabase con el link: $e');
        }
      },
      onError: (err) {
        debugPrint('🚨 [Hyro Debug] Error en el stream: $err');
      },
    );
  }

  // ─── Sign In Methods ──────────────────────────────────────────────

  /// Google Auth via Native Google Sign In
  /// Google Auth: Detecta si es PC o Móvil para usar el flujo correcto
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Checamos si estamos en PC (Windows) o en Web
      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS) {
        // 💻 FLUJO PARA ESCRITORIO: Abrir el navegador
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          // Este es el enlace personalizado que ya registraste en Supabase
          redirectTo: 'io.supabase.hyroapp://login-callback/',
        );
        // La redirección será atrapada por Supabase y _listenAuthChanges hará el resto.
      } else {
        // 📱 FLUJO PARA MÓVILES: Menú nativo (el que ya te funcionó)
        const webClientId =
            '19333866872-qv63mn5m7bjiaqfkk252p4sd646mhm9h.apps.googleusercontent.com';

        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
        );

        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return;
        }

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null || idToken == null) {
          throw 'Faltan los tokens de autenticación de Google.';
        }

        final res = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (res.session != null) {
          await _syncSupabaseUserToIsar(res.session!.user);
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Real email/password Login with Supabase
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

  /// Real email/password Signup with Supabase
  Future<void> signUpWithEmail(String email, String password, String name) async {
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

  /// Local email login (existing behavior).
  Future<void> loginPersonal(String email, String name) async {
    _isLoading = true;
    notifyListeners();

    final existingUser =
        await isar.userProfiles
            .filter()
            .usernameOrEmailEqualTo(email)
            .findFirst();

    final user =
        existingUser ?? UserProfile()
          ..usernameOrEmail = email
          ..name = name
          ..type = UserType.personal
          ..isActivelyLoggedIn = true;

    if (existingUser != null) {
      user.isActivelyLoggedIn = true;
    }

    await isar.writeTxn(() async {
      final activeUsers =
          await isar.userProfiles
              .filter()
              .isActivelyLoggedInEqualTo(true)
              .findAll();

      for (var u in activeUsers) {
        u.isActivelyLoggedIn = false;
        await isar.userProfiles.put(u);
      }

      await isar.userProfiles.put(user);
    });

    _currentUser = user;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Logout ───────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      // Limpiamos también la sesión nativa de Google solo en móvil (evita crash en Windows)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
    } catch (e) {
      debugPrint('Error durante el logout: $e');
    }

    if (_currentUser != null) {
      await isar.writeTxn(() async {
        // En vez de solo desloguear, limpiamos la base local de perfiles para evitar residuos
        await isar.userProfiles.clear();
      });
      _currentUser = null;
    }

    // Limpiamos las cajas de Hive
    try {
      if (Hive.isBoxOpen('tasksBox')) await Hive.box<TaskModel>('tasksBox').clear();
      if (Hive.isBoxOpen('statsBox')) await Hive.box<DailyStats>('statsBox').clear();
      if (Hive.isBoxOpen('categoriesBox')) await Hive.box<CategoryModel>('categoriesBox').clear();
      if (Hive.isBoxOpen('notasBox')) await Hive.box<TareaNotaModel>('notasBox').clear();
      if (Hive.isBoxOpen('fuentesBox')) await Hive.box<TareaFuenteModel>('fuentesBox').clear();
      if (Hive.isBoxOpen('cardsBox')) await Hive.box<TareaCardModel>('cardsBox').clear();
    } catch (e) {
      debugPrint('Error limpiando Hive en logout: $e');
    }
    
    // Fallback to guest mode
    await _loginAsGuest();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
