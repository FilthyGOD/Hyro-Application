import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rive/rive.dart';
import 'app.dart';
import 'data/models/task_model.dart';
import 'data/models/daily_stats.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/user_profile.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Pre-open the box to avoid async issues later if wanted, or let repository handle it.
  await Hive.openBox<TaskModel>('tasksBox');
  await Hive.openBox<DailyStats>('statsBox');

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([UserProfileSchema], directory: dir.path);

  runApp(HyroApp(isar: isar));
}
// koko was here
// koko was here x2