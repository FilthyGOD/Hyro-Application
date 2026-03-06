/// Formatting utilities for the Hyro app.
class FormatTime {
  FormatTime._();

  /// Formats seconds into MM:SS string (e.g., 1500 → "25:00").
  static String mmss(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formats total minutes into a human-readable hours string (e.g., 150 → "2.5h").
  static String hours(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes / 60;
    return '${h.toStringAsFixed(1)}h';
  }

  /// Formats a Duration into a readable string.
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
