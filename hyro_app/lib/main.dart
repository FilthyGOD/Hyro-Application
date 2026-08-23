import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// Importaciones condicionales — solo se usan en nativo
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/task_model.dart';
import 'data/models/daily_stats.dart';
import 'data/models/category_model.dart';
import 'data/models/subtask_model.dart';
import 'data/models/tarea_nota_model.dart';
import 'data/models/tarea_fuente_model.dart';
import 'data/models/tarea_card_model.dart';
import 'data/models/user_profile.dart';

// Importación condicional de paquetes nativos
// En web no se importan dart:io ni paquetes nativos
import 'main_native.dart' if (dart.library.html) 'main_web.dart' as platform_main;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización específica de plataforma (notificaciones, ventana, single instance, etc.)
  await platform_main.platformInit(args);

  await Supabase.initialize(
    url: 'https://biuytttsqlevvrtbywxt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpdXl0dHRzcWxldnZydGJ5d3h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MzUxODYsImV4cCI6MjA4ODMxMTE4Nn0.HT523GGYw1vUR5Ip0LMcKslNFxQK3nVBoHW8WcOmPw8',
  );

  dynamic isar;

  if (!kIsWeb) {
    // ── Hive (solo nativo) ──
    await Hive.initFlutter();
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(SubTaskModelAdapter());
    Hive.registerAdapter(DailyStatsAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(TareaNotaModelAdapter());
    Hive.registerAdapter(TareaFuenteModelAdapter());
    Hive.registerAdapter(TareaCardModelAdapter());

    await Hive.openBox<TaskModel>('tasksBox');
    await Hive.openBox<DailyStats>('statsBox');
    await Hive.openBox<CategoryModel>('categoriesBox');
    await Hive.openBox<TareaNotaModel>('notasBox');
    await Hive.openBox<TareaFuenteModel>('fuentesBox');
    await Hive.openBox<TareaCardModel>('cardsBox');

    // ── Isar (solo nativo) ──
    isar = await platform_main.openIsar();
  }

  runApp(HyroApp(isar: isar));
}
// koko estuvo aquí
// koko estuvo aquí x2