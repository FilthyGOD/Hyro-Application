/// Utilidades de formateo para la aplicación Hyro.
class FormatTime {
  FormatTime._();

  /// Formatea segundos en cadena MM:SS (ej., 1500 → "25:00").
  static String mmss(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formatea minutos totales en una cadena legible de horas (ej., 150 → "2.5h").
  static String hours(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes / 60;
    return '${h.toStringAsFixed(1)}h';
  }

  /// Formatea un Duration en una cadena legible.
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
