import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hyro/data/models/user_profile.dart';
import 'dart:io' show Platform, InternetAddress;
import 'package:app_links/app_links.dart';
import 'package:hyro/data/sync/sync_service.dart';
import 'package:hyro/data/local/task_local_ds.dart';
import 'package:hyro/data/local/category_local_ds.dart';
import 'package:hyro/data/local/note_local_ds.dart';
import 'package:hyro/data/local/source_local_ds.dart';
import 'package:hyro/data/local/card_local_ds.dart';
import 'package:hyro/data/remote/task_remote_ds.dart';
import 'package:hyro/data/remote/category_remote_ds.dart';
import 'package:hyro/data/remote/note_remote_ds.dart';
import 'package:hyro/data/remote/source_remote_ds.dart';
import 'package:hyro/data/remote/card_remote_ds.dart';
import 'package:hyro/data/remote/file_storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyro/data/models/task_model.dart';
import 'package:hyro/data/models/daily_stats.dart';
import 'package:hyro/data/models/category_model.dart';
import 'package:hyro/data/models/tarea_nota_model.dart';
import 'package:hyro/data/models/tarea_fuente_model.dart';
import 'package:hyro/data/models/tarea_card_model.dart';

/// Escucha deep links en escritorio (Windows, macOS, Linux).
StreamSubscription<Uri>? listenForDeepLinksPC() {
  if (Platform.isAndroid || Platform.isIOS) return null;

  final appLinks = AppLinks();
  StreamSubscription<Uri>? sub;

  () async {
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && initialUri.scheme == 'io.supabase.hyroapp') {
        debugPrint('🚨 [Hyro Debug] Link inicial atrapado: $initialUri');
        await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
      }
    } catch (e) {
      debugPrint('🚨 [Hyro Debug] Error leyendo link inicial: $e');
    }
  }();

  sub = appLinks.uriLinkStream.listen(
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

  return sub;
}

/// Verifica si hay conexión a internet (solo nativo).
Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 2));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Sincroniza el usuario de Supabase a Isar (solo nativo).
Future<void> syncSupabaseUserToIsar({
  required dynamic isar,
  required User supabaseUser,
  required String email,
  required String name,
  required void Function(UserProfile user) onUserReady,
  required void Function() onLoadingDone,
}) async {
  final db = isar as Isar;
  
  // 1. Capturar datos del guest local ANTES de cambiar usuarios
  final guestUser =
      await db.userProfiles
          .filter()
          .usernameOrEmailEqualTo('guest_local')
          .findFirst();

  final localNivel = guestUser?.nivel ?? 1;
  final localExp = guestUser?.experiencia ?? 0;
  final localMonedas = guestUser?.monedas ?? 0;
  final localCompras = guestUser?.comprasLocales ?? [];

  // 2. Crear/actualizar el usuario Supabase en Isar
  final existingUser =
      await db.userProfiles
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

  await db.writeTxn(() async {
    final activeUsers =
        await db.userProfiles
            .filter()
            .isActivelyLoggedInEqualTo(true)
            .findAll();

    for (var u in activeUsers) {
      u.isActivelyLoggedIn = false;
      await db.userProfiles.put(u);
    }

    await db.userProfiles.put(user);
  });

  final isConnected = await hasInternet();
  if (!isConnected) {
    debugPrint('⚠️ No internet connection detected. Skipping sync.');
    onUserReady(user);
    onLoadingDone();
    return;
  }

  // Sincronizar gamificación
  try {
    await Supabase.instance.client.rpc(
      'sincronizar_perfil_local',
      params: {
        'p_nivel': localNivel,
        'p_experiencia': localExp,
        'p_monedas': localMonedas,
        'p_compras_ids': localCompras,
      },
    );
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

  onUserReady(user);
  onLoadingDone();
}

/// Busca un usuario activo en Isar.
Future<UserProfile?> findActiveUser(dynamic isar) async {
  final db = isar as Isar;
  return await db.userProfiles
      .filter()
      .isActivelyLoggedInEqualTo(true)
      .findFirst();
}

/// Login como invitado en Isar.
Future<UserProfile> loginAsGuest(dynamic isar) async {
  final db = isar as Isar;
  
  final existingGuest =
      await db.userProfiles
          .filter()
          .usernameOrEmailEqualTo('guest_local')
          .findFirst();

  final guest =
      existingGuest ?? UserProfile()
        ..usernameOrEmail = 'guest_local'
        ..name = 'Invitado'
        ..type = UserType.personal
        ..isActivelyLoggedIn = true;

  if (existingGuest != null) {
    guest.isActivelyLoggedIn = true;
  }

  await db.writeTxn(() async {
    final activeUsers =
        await db.userProfiles
            .filter()
            .isActivelyLoggedInEqualTo(true)
            .findAll();

    for (var u in activeUsers) {
      u.isActivelyLoggedIn = false;
      await db.userProfiles.put(u);
    }
    await db.userProfiles.put(guest);
  });

  return guest;
}

/// Login personal local en Isar.
Future<UserProfile> loginPersonal(dynamic isar, String email, String name) async {
  final db = isar as Isar;
  
  final existingUser =
      await db.userProfiles
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

  await db.writeTxn(() async {
    final activeUsers =
        await db.userProfiles
            .filter()
            .isActivelyLoggedInEqualTo(true)
            .findAll();

    for (var u in activeUsers) {
      u.isActivelyLoggedIn = false;
      await db.userProfiles.put(u);
    }

    await db.userProfiles.put(user);
  });

  return user;
}

/// Limpieza nativa durante el logout (Google Sign-In, etc.)
Future<void> cleanupNativeLogout(dynamic isar) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
  }

  // Limpiamos las cajas de Hive
  try {
    if (Hive.isBoxOpen('tasksBox'))
      await Hive.box<TaskModel>('tasksBox').clear();
    if (Hive.isBoxOpen('statsBox'))
      await Hive.box<DailyStats>('statsBox').clear();
    if (Hive.isBoxOpen('categoriesBox'))
      await Hive.box<CategoryModel>('categoriesBox').clear();
    if (Hive.isBoxOpen('notasBox'))
      await Hive.box<TareaNotaModel>('notasBox').clear();
    if (Hive.isBoxOpen('fuentesBox'))
      await Hive.box<TareaFuenteModel>('fuentesBox').clear();
    if (Hive.isBoxOpen('cardsBox'))
      await Hive.box<TareaCardModel>('cardsBox').clear();
  } catch (e) {
    debugPrint('Error limpiando Hive en logout: $e');
  }
}

/// Limpia los perfiles de Isar.
Future<void> clearIsarProfiles(dynamic isar) async {
  final db = isar as Isar;
  await db.writeTxn(() async {
    await db.userProfiles.clear();
  });
}
