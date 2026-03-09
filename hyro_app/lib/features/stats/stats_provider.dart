import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/daily_stats.dart';
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
  Future<void> addFocusSession(int durationMinutes) async {
    await _repository.addSession(durationMinutes);
    notifyListeners();
  }
}
