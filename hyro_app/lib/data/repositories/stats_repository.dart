import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_stats.dart';
import 'package:intl/intl.dart';

class StatsRepository {
  final Box<DailyStats> _statsBox;

  StatsRepository(this._statsBox);

  /// Helper to format date consistently
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Add a completed session to today's stats
  Future<void> addSession(int durationMinutes) async {
    final todayStr = _formatDate(DateTime.now());
    var stats = _statsBox.get(todayStr);

    if (stats == null) {
      stats = DailyStats(
        date: todayStr,
        focusSessions: 1,
        focusMinutes: durationMinutes,
      );
      await _statsBox.put(todayStr, stats);
    } else {
      stats.focusSessions += 1;
      stats.focusMinutes += durationMinutes;
      await stats.save();
    }
  }

  /// Get stats for a specific date
  DailyStats? getStatsForDate(DateTime date) {
    return _statsBox.get(_formatDate(date));
  }

  /// Get stats for today specifically
  DailyStats? getTodaysStats() {
    return getStatsForDate(DateTime.now());
  }

  List<double> getLast7DaysFocusMinutesRelative() {
    List<double> result = [];
    final maxMinutesTarget = 120.0; // Two hours goal per day

    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      DailyStats? stats = getStatsForDate(date);

      if (stats != null) {
        double relative = stats.focusMinutes / maxMinutesTarget;
        result.add(relative > 1.0 ? 1.0 : relative);
      } else {
        result.add(0.0);
      }
    }
    return result;
  }

  /// Get the current week's focus minutes relative to goal (Monday to Sunday)
  List<double> getCurrentWeekFocusMinutesRelative() {
    List<double> result = [];
    final maxMinutesTarget = 120.0; // Two hours goal per day

    DateTime now = DateTime.now();
    // Dart DateTime.weekday is 1 for Monday, 7 for Sunday.
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      DailyStats? stats = getStatsForDate(date);

      if (stats != null) {
        double relative = stats.focusMinutes / maxMinutesTarget;
        result.add(relative > 1.0 ? 1.0 : relative);
      } else {
        result.add(0.0);
      }
    }
    return result;
  }

  /// Get stats for a specific month (for the calendar)
  Map<String, DailyStats> getStatsForMonth(int year, int month) {
    final Map<String, DailyStats> result = {};
    for (var key in _statsBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('$year-${month.toString().padLeft(2, '0')}')) {
        final stat = _statsBox.get(key);
        if (stat != null) {
          result[keyStr] = stat;
        }
      }
    }
    return result;
  }

  /// Calculate the current streak of consecutive days with at least 1 focus session
  int getCurrentStreak() {
    int streak = 0;
    DateTime dateToCheck = DateTime.now();

    while (true) {
      final dateStr = _formatDate(dateToCheck);
      final stats = _statsBox.get(dateStr);

      if (stats != null && stats.focusSessions > 0) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else {
        // If today has no stats yet, check yesterday to keep streak alive
        if (streak == 0 &&
            _formatDate(dateToCheck) == _formatDate(DateTime.now())) {
          dateToCheck = dateToCheck.subtract(const Duration(days: 1));
          final yesStr = _formatDate(dateToCheck);
          final yesStats = _statsBox.get(yesStr);
          if (yesStats != null && yesStats.focusSessions > 0) {
            streak++;
            dateToCheck = dateToCheck.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    }

    return streak;
  }

  /// Calculate total focus hours across all time
  double getTotalFocusHours() {
    int totalMinutes = 0;
    for (var stats in _statsBox.values) {
      totalMinutes += stats.focusMinutes;
    }
    return totalMinutes / 60.0;
  }
}
