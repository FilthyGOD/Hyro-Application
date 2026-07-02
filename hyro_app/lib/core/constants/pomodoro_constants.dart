/// Duraciones y configuración por defecto del temporizador Pomodoro.
class PomodoroConstants {
  PomodoroConstants._();

  /// Duración por defecto del Pomodoro en minutos.
  static const int pomodoroDuration = 25;

  /// Duración por defecto del descanso corto en minutos.
  static const int shortBreakDuration = 5;

  /// Duración por defecto del descanso largo en minutos.
  static const int longBreakDuration = 15;

  /// Número de pomodoros antes de un descanso largo.
  static const int pomodorosBeforeLongBreak = 4;

  /// Máximo de sesiones diarias para rastrear.
  static const int maxDailySessions = 16;
}
