import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'core/services/notifications_service.dart';
import 'data/models/user_profile.dart';

/// Inicialización específica de plataforma nativa (Windows, Android, iOS, etc.)
Future<void> platformInit(List<String> args) async {
  // Inicializar notificaciones y solicitar permisos
  await NotificationsService.instance.init();
  await NotificationsService.instance.requestPermissions();

  // ─── REGISTRAR PROTOCOLO EN WINDOWS (Para Deep Links) ────────────
  if (Platform.isWindows) {
    try {
      final String executable = Platform.resolvedExecutable;
      const String scheme = 'io.supabase.hyroapp';
      Process.runSync('reg', [
        'add',
        'HKCU\\Software\\Classes\\$scheme',
        '/ve',
        '/d',
        'URL:$scheme Protocol',
        '/f',
      ]);
      Process.runSync('reg', [
        'add',
        'HKCU\\Software\\Classes\\$scheme',
        '/v',
        'URL Protocol',
        '/d',
        '',
        '/f',
      ]);
      Process.runSync('reg', [
        'add',
        'HKCU\\Software\\Classes\\$scheme\\shell\\open\\command',
        '/ve',
        '/d',
        '"$executable" "%1"',
        '/f',
      ]);
      debugPrint('🚨 [Hyro Debug] Protocolo $scheme registrado en Windows.');
    } catch (e) {
      debugPrint('🚨 [Hyro Debug] Error registrando protocolo: $e');
    }
  }

  // ─── EL CADENERO OFICIAL (PARCHADO PARA NULLS) ───────────────────
  if (Platform.isWindows) {
    // Le ponemos "bool?" y "??" para que nunca sea nulo
    bool? resultadoInstancia = await WindowsSingleInstance.ensureSingleInstance(
      args,
      "hyro_app_instancia_unica",
      onSecondWindow: (List<String> nuevosArgs) async {
        debugPrint(
          '🚨 [Hyro Debug] onSecondWindow llamado con ${nuevosArgs.length} args',
        );
        for (var arg in nuevosArgs) {
          debugPrint('🚨 [Hyro Debug] Arg: $arg');
        }
        if (nuevosArgs.isNotEmpty) {
          final enlace = nuevosArgs.first;
          debugPrint('🚨 [Hyro Debug] ¡Link robado del clon!: $enlace');
          try {
            final response = await Supabase.instance.client.auth
                .getSessionFromUrl(Uri.parse(enlace));
            debugPrint(
              '🚨 [Hyro Debug] getSessionFromUrl exitoso! User: ${response.session?.user.email}',
            );
          } catch (e) {
            debugPrint(
              '🚨 [Hyro Debug] Error en Supabase getSessionFromUrl: $e',
            );
          }
        } else {
          debugPrint('🚨 [Hyro Debug] onSecondWindow: sin args');
        }
      },
    );

    // Si es falso (o sea, es el clon), se cierra. Si es nulo, sigue adelante.
    if (resultadoInstancia == false) {
      exit(0);
    }
  }
  // ──────────────────────────────────────────────────────────────────

  // Gestión de la ventana en escritorio
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(600, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 100));
      await windowManager.maximize();
    });
  }

  await RiveNative.init();
}

/// Abre la base de datos Isar para la plataforma nativa.
Future<dynamic> openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([UserProfileSchema], directory: dir.path);
  return isar;
}
