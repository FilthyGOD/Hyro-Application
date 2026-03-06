/// Pomodoro timer default durations and configuration.
class PomodoroConstants {
  PomodoroConstants._();

  /// Default Pomodoro duration in minutes.
  static const int pomodoroDuration = 25;

  /// Default short break duration in minutes.
  static const int shortBreakDuration = 5;

  /// Default long break duration in minutes.
  static const int longBreakDuration = 15;

  /// Number of pomodoros before a long break.
  static const int pomodorosBeforeLongBreak = 4;

  /// Maximum daily sessions to track.
  static const int maxDailySessions = 16;
}
