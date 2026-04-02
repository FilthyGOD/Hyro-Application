import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rive/rive.dart';
import 'app.dart';
import 'data/models/task_model.dart';
import 'data/models/daily_stats.dart';
import 'data/models/category_model.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/user_profile.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:windows_single_instance/windows_single_instance.dart'; // <-- Vuelve el salvador

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── EL CADENERO OFICIAL (PARCHADO PARA NULLS) ───────────────────
  if (Platform.isWindows) {
    // Le ponemos "bool?" y "??" para que nunca sea nulo
    bool? resultadoInstancia = await WindowsSingleInstance.ensureSingleInstance(
      args,
      "hyro_app_instancia_unica",
      onSecondWindow: (List<String> nuevosArgs) async {
        if (nuevosArgs.isNotEmpty) {
          final enlace = nuevosArgs.first;
          debugPrint('🚨 [Hyro Debug] ¡Link robado del clon!: $enlace');
          try {
            await Supabase.instance.client.auth.getSessionFromUrl(
              Uri.parse(enlace),
            );
          } catch (e) {
            debugPrint('Error en Supabase: $e');
          }
        }
      },
    );

    // Si es falso (o sea, es el clon), se cierra. Si es nulo, sigue adelante.
    if (resultadoInstancia == false) {
      exit(0);
    }
  }
  // ──────────────────────────────────────────────────────────────────

  // Desktop window management
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(600, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await RiveNative.init();

  await Supabase.initialize(
    url: 'https://biuytttsqlevvrtbywxt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpdXl0dHRzcWxldnZydGJ5d3h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MzUxODYsImV4cCI6MjA4ODMxMTE4Nn0.HT523GGYw1vUR5Ip0LMcKslNFxQK3nVBoHW8WcOmPw8',
  );

  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(DailyStatsAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  await Hive.openBox<TaskModel>('tasksBox');
  await Hive.openBox<DailyStats>('statsBox');
  await Hive.openBox<CategoryModel>('categoriesBox');

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([UserProfileSchema], directory: dir.path);

  runApp(HyroApp(isar: isar));
}
// koko was here
// koko was here x2