import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_stats.dart';
import 'package:intl/intl.dart';

class StatsRepository {
  final Box<DailyStats> _statsBox;

  StatsRepository(this._statsBox);

  /// Ayudante para formatear fecha consistentemente
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// A\u00f1ade una sesi\u00f3n completada a las estad\u00edsticas de hoy
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

  /// Obtiene las estad\u00edsticas de una fecha espec\u00edfica
  DailyStats? getStatsForDate(DateTime date) {
    return _statsBox.get(_formatDate(date));
  }

  /// Obtiene las estad\u00edsticas de hoy espec\u00edficamente
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

  /// Obtiene los minutos de enfoque de la semana actual relativo a la meta (lunes a domingo)
  List<double> getCurrentWeekFocusMinutesRelative() {
    List<double> result = [];
    final maxMinutesTarget = 120.0; // Two hours goal per day

    DateTime now = DateTime.now();
    // Dart DateTime.weekday es 1 para lunes, 7 para domingo.
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

  /// Obtiene las estad\u00edsticas de un mes espec\u00edfico (para el calendario)
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

  /// Calcula la racha actual de d\u00edas consecutivos con al menos 1 sesi\u00f3n de enfoque
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
        // Si hoy no tiene estad\u00edsticas a\u00fan, revisar ayer para mantener la racha viva
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

  /// Calcula el total de horas de enfoque de todos los tiempos
  double getTotalFocusHours() {
    int totalMinutes = 0;
    for (var stats in _statsBox.values) {
      totalMinutes += stats.focusMinutes;
    }
    return totalMinutes / 60.0;
  }
}
