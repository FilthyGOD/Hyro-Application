import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/pomodoro_constants.dart';
import '../../stats/stats_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../missions/missions_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notifications_service.dart';
import '../../../core/services/strict_mode_service.dart';
import '../models/quiz_result_item.dart';
import 'timer_state.dart';

/// Cubit que gestiona la lógica del temporizador Pomodoro.
class TimerCubit extends Cubit<TimerState> {
  Timer? _timer;
  int _secondsSinceLastQuiz = 0;
  final StatsProvider? statsProvider;
  final SettingsProvider? settingsProvider;
  final ProfileProvider? profileProvider;
  final MissionsProvider? missionsProvider;
  final TaskProvider? taskProvider;

  /// Referencia opcional al AuthProvider — se establece desde afuera después de la creación.
  AuthProvider? authProvider;

  TimerCubit({
    this.statsProvider,
    this.settingsProvider,
    this.profileProvider,
    this.missionsProvider,
    this.taskProvider,
  }) : super(const TimerState());

  final StrictModeService _strictModeService = StrictModeService();

  /// Inicia el temporizador.
  void start({String? taskId, String? taskTitle, bool isStrictMode = false}) {
    if (state.status == TimerStatus.running) return;

    emit(
      state.copyWith(
        status: TimerStatus.running,
        activeTaskId: taskId ?? state.activeTaskId,
        activeTaskTitle: taskTitle ?? state.activeTaskTitle,
        quizDue: false,
        isStrictModeActive: isStrictMode || state.isStrictModeActive,
        clearViolationApp: true,
        quizHistory: (state.status == TimerStatus.paused) ? state.quizHistory : const [],
        quizCorrectCount: (state.status == TimerStatus.paused) ? state.quizCorrectCount : 0,
        quizTotalCount: (state.status == TimerStatus.paused) ? state.quizTotalCount : 0,
      ),
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationsService.instance.schedulePomodoroEndNotification(
      state.mode == TimerMode.pomodoro,
      state.remainingSeconds,
    );

    // Inicia el monitoreo del modo estricto si está habilitado
    if (state.isStrictModeActive) {
      debugPrint(
        '[StrictMode][TimerCubit] isStrictModeActive=true, calling _initStrictMode()',
      );
      _initStrictMode();
    } else {
      debugPrint(
        '[StrictMode][TimerCubit] isStrictModeActive=false, skipping strict mode',
      );
    }
  }

  Future<void> _initStrictMode() async {
    debugPrint('[StrictMode][TimerCubit] _initStrictMode() starting...');
    await _strictModeService.init();
    debugPrint(
      '[StrictMode][TimerCubit] Service initialized, starting monitoring...',
    );
    await _strictModeService.startStrictMonitoring((appName) {
      String formattedAppName = appName;
      final parts = appName.split('.');
      if (parts.length >= 2) {
        formattedAppName = parts[1];
      }
      // Llamado cuando el usuario sale de la aplicación durante el modo estricto
      debugPrint(
        '[StrictMode][TimerCubit] ⚠️ Violation callback! isRunning=${state.isRunning}, app: $formattedAppName',
      );
      if (state.isRunning ||
          (state.status == TimerStatus.paused && !state.isManualPause)) {
        debugPrint(
          '[StrictMode][TimerCubit] Registering strict mode violation',
        );
        _timer?.cancel();
        emit(
          state.copyWith(
            status: TimerStatus.paused,
            isManualPause: false,
            strictModeViolationApp: appName,
          ),
        );
      }
    });
    debugPrint('[StrictMode][TimerCubit] _initStrictMode() complete');
  }

  /// Pausa el temporizador. [manual] = true cuando el usuario presiona el botón de pausa.
  void pause({bool manual = true}) {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    emit(
      state.copyWith(
        status: TimerStatus.paused,
        isManualPause: manual,
        clearViolationApp: true,
      ),
    );
  }

  /// Reanuda un temporizador pausado.
  void resume() {
    if (state.status != TimerStatus.paused) return;
    start();
  }

  /// Reinicia el temporizador al comienzo del modo actual.
  void reset() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    // Detiene el monitoreo estricto si estaba activo
    if (state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    final totalSec = _durationForMode(state.mode) * 60;
    emit(
      state.copyWith(
        status: TimerStatus.idle,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        isStrictModeActive: false,
      ),
    );
  }

  /// Refresca la duración del temporizador inmediatamente si está inactivo.
  void refreshIfIdle() {
    if (state.status == TimerStatus.idle) {
      reset();
    }
  }

  /// Detiene el temporizador completamente y vuelve a pomodoro inactivo.
  void stop() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    // Detiene el monitoreo estricto si estaba activo
    if (state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    final totalSec =
        (settingsProvider?.pomodoroDuration.toInt() ??
            PomodoroConstants.pomodoroDuration) *
        60;
    emit(
      TimerState(
        completedSessions: state.completedSessions,
        totalFocusMinutes: state.totalFocusMinutes,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        activeTaskId: state.activeTaskId,
        activeTaskTitle: state.activeTaskTitle,
      ),
    );
  }

  /// Cambia el modo del temporizador (Pomodoro, Descanso Corto, Descanso Largo).
  void setMode(TimerMode mode) {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    final totalSec = _durationForMode(mode) * 60;
    emit(
      TimerState(
        mode: mode,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        completedSessions: state.completedSessions,
        totalFocusMinutes: state.totalFocusMinutes,
        activeTaskId: state.activeTaskId,
        activeTaskTitle: state.activeTaskTitle,
      ),
    );
  }

  void _tick() {
    if (state.remainingSeconds <= 1) {
      _timer?.cancel();
      _secondsSinceLastQuiz = 0;
      _onTimerFinished();
    } else {
      _secondsSinceLastQuiz++;

      // Verifica si es hora de un cuestionario (solo durante modo pomodoro, cuestionario habilitado, y tiene una tarea)
      final quizEnabled = settingsProvider?.focusQuizEnabled ?? false;
      final quizInterval =
          ((settingsProvider?.focusQuizIntervalMinutes ?? 5) * 60).toInt();
      bool triggerQuiz = false;

      if (quizEnabled &&
          state.mode == TimerMode.pomodoro &&
          state.activeTaskId != null &&
          !state.quizDue &&
          _secondsSinceLastQuiz >= quizInterval) {
        triggerQuiz = true;
        _secondsSinceLastQuiz = 0;
      }

      emit(
        state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          quizDue: triggerQuiz ? true : null,
        ),
      );
    }
  }

  /// Llamado por FocusScreen después de que se muestra el diálogo del cuestionario.
  void acknowledgeQuiz() {
    emit(state.copyWith(quizDue: false));
  }

  /// Registra el resultado de una pregunta de cuestionario.
  void recordQuizResult(bool isCorrect, QuizResultItem item) {
    emit(
      state.copyWith(
        quizCorrectCount: state.quizCorrectCount + (isCorrect ? 1 : 0),
        quizTotalCount: state.quizTotalCount + 1,
        quizHistory: [...state.quizHistory, item],
      ),
    );
  }

  void _onTimerFinished() {
    // Detiene el monitoreo de modo estricto cuando termina una sesión
    if (state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }

    if (state.mode == TimerMode.pomodoro) {
      final newSessions = state.completedSessions + 1;
      final focusMinutes = state.totalSeconds ~/ 60;
      final newFocusMinutes = state.totalFocusMinutes + focusMinutes;

      final userId = authProvider?.supabaseUserId;

      // Dile al proveedor de estadísticas que registre esta sesión localmente y la sincronice con la nube
      statsProvider?.addFocusSession(focusMinutes, userId);

      Future.microtask(() {
        // Después de que actualiza la caja local (StatsBox), capturamos la racha dinámica real más nueva
        final currentDynamicStreak = statsProvider?.currentStreak ?? 0;
        profileProvider?.syncDynamicStats(
          userId,
          currentDynamicStreak,
          focusMinutes,
        );
      });

      // ── Acciones de gamificación ──
      // 10 XP por cada pomodoro completado (grantXP soporta nativamente cuentas locales)
      profileProvider?.grantXP(userId, 10);
      // Actualiza progreso de la misión
      missionsProvider?.updateProgress('pomodoro_completed', 1);
      missionsProvider?.updateProgress('minutes_studied', focusMinutes);

      // ── Acción de Enlace de Tareas ──
      if (state.activeTaskId != null && taskProvider != null) {
        taskProvider?.incrementTaskPomodoro(state.activeTaskId!);
      }

      // Transición automática: después de 4 pomodoros → descanso largo, si no, descanso corto
      final nextMode =
          newSessions % PomodoroConstants.pomodorosBeforeLongBreak == 0
              ? TimerMode.longBreak
              : TimerMode.shortBreak;
      final nextDuration = _durationForMode(nextMode) * 60;

      emit(
        TimerState(
          status: TimerStatus.finished,
          mode: nextMode,
          remainingSeconds: nextDuration,
          totalSeconds: nextDuration,
          completedSessions: newSessions,
          totalFocusMinutes: newFocusMinutes,
          activeTaskId: state.activeTaskId,
          activeTaskTitle: state.activeTaskTitle,
          quizCorrectCount: state.quizCorrectCount,
          quizTotalCount: state.quizTotalCount,
          quizHistory:
              state.quizHistory, // Mantiene el historial para revisión en la pantalla final
        ),
      );
    } else {
      // Termina el descanso → vuelve a pomodoro
      final nextDuration =
          (settingsProvider?.pomodoroDuration.toInt() ??
              PomodoroConstants.pomodoroDuration) *
          60;
      emit(
        state.copyWith(
          status: TimerStatus.finished,
          mode: TimerMode.pomodoro,
          remainingSeconds: nextDuration,
          totalSeconds: nextDuration,
        ),
      );
    }
  }

  int _durationForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return settingsProvider?.pomodoroDuration.toInt() ??
            PomodoroConstants.pomodoroDuration;
      case TimerMode.shortBreak:
        return settingsProvider?.shortBreakDuration.toInt() ??
            PomodoroConstants.shortBreakDuration;
      case TimerMode.longBreak:
        return settingsProvider?.longBreakDuration.toInt() ??
            PomodoroConstants.longBreakDuration;
    }
  }

  /// Método de depuración para activar de inmediato la vista de sesión completada
  void debugForceSessionCompleted() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    emit(
      TimerState(
        status: TimerStatus.finished,
        mode: TimerMode.shortBreak,
        remainingSeconds: 5 * 60,
        totalSeconds: 5 * 60,
        completedSessions: state.completedSessions,
        totalFocusMinutes: state.totalFocusMinutes,
        activeTaskId: state.activeTaskId,
        activeTaskTitle: state.activeTaskTitle,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    if (state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    return super.close();
  }
}
