import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/daily_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/stats_repository.dart';

class StatsProvider extends ChangeNotifier {
  final StatsRepository _repository;

  StatsProvider()
    : _repository = StatsRepository(Hive.box<DailyStats>('statsBox'));

  int get currentStreak => _repository.getCurrentStreak();
  double get totalFocusHours => _repository.getTotalFocusHours();

  DailyStats? get todaysStats => _repository.getTodaysStats();
  List<double> get weeklyActivityData =>
      _repository.getCurrentWeekFocusMinutesRelative();

  /// Map of date string (yyyy-MM-dd) to DailyStats for the given month
  Map<String, DailyStats> getStatsForMonth(int year, int month) {
    return _repository.getStatsForMonth(year, month);
  }

  /// Called when a timer session is completed
  Future<void> addFocusSession(int durationMinutes, String? userId) async {
    await _repository.addSession(durationMinutes);
    notifyListeners();

    if (userId != null) {
      try {
        await Supabase.instance.client.from('sesiones_enfoque').insert({
          'usuario_id': userId,
          'duracion_minutos': durationMinutes,
          'completada_en': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('⚠️ Error sincronizando sesión a Supabase (offline-first safeguard): $e');
      }
    }
  }
}
