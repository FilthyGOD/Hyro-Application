import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/pomodoro_constants.dart';
import '../../stats/stats_provider.dart';
import '../../settings/settings_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../missions/missions_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/services/strict_mode_service.dart';
import '../models/quiz_result_item.dart';
import 'focus_state.dart';

/// Provider que gestiona la lógica del temporizador Pomodoro.
/// Reemplaza a TimerCubit (BLoC) para estandarizar el patrón de estado.
class FocusProvider extends ChangeNotifier {
  Timer? _timer;
  int _secondsSinceLastQuiz = 0;
  final StatsProvider? statsProvider;
  final SettingsProvider? settingsProvider;
  final ProfileProvider? profileProvider;
  final MissionsProvider? missionsProvider;
  final TaskProvider? taskProvider;

  /// Referencia opcional al AuthProvider — se establece desde afuera después de la creación.
  AuthProvider? authProvider;

  TimerState _state = const TimerState();
  TimerState get state => _state;

  FocusProvider({
    this.statsProvider,
    this.settingsProvider,
    this.profileProvider,
    this.missionsProvider,
    this.taskProvider,
  });

  final StrictModeService _strictModeService = StrictModeService();

  void _emit(TimerState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Inicia el temporizador.
  void start({String? taskId, String? taskTitle, bool isStrictMode = false}) {
    if (_state.status == TimerStatus.running) return;

    _emit(
      _state.copyWith(
        status: TimerStatus.running,
        activeTaskId: taskId ?? _state.activeTaskId,
        activeTaskTitle: taskTitle ?? _state.activeTaskTitle,
        quizDue: false,
        isStrictModeActive: isStrictMode || _state.isStrictModeActive,
        clearViolationApp: true,
        quizHistory: (_state.status == TimerStatus.paused) ? _state.quizHistory : const [],
        quizCorrectCount: (_state.status == TimerStatus.paused) ? _state.quizCorrectCount : 0,
        quizTotalCount: (_state.status == TimerStatus.paused) ? _state.quizTotalCount : 0,
      ),
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationsService.instance.schedulePomodoroEndNotification(
      _state.mode == TimerMode.pomodoro,
      _state.remainingSeconds,
    );

    // Inicia el monitoreo del modo estricto si está habilitado
    if (_state.isStrictModeActive) {
      debugPrint(
        '[StrictMode][FocusProvider] isStrictModeActive=true, calling _initStrictMode()',
      );
      _initStrictMode();
    } else {
      debugPrint(
        '[StrictMode][FocusProvider] isStrictModeActive=false, skipping strict mode',
      );
    }
  }

  Future<void> _initStrictMode() async {
    debugPrint('[StrictMode][FocusProvider] _initStrictMode() starting...');
    await _strictModeService.init();
    debugPrint(
      '[StrictMode][FocusProvider] Service initialized, starting monitoring...',
    );
    await _strictModeService.startStrictMonitoring((appName) {
      String formattedAppName = appName;
      final parts = appName.split('.');
      if (parts.length >= 2) {
        formattedAppName = parts[1];
      }
      // Llamado cuando el usuario sale de la aplicación durante el modo estricto
      debugPrint(
        '[StrictMode][FocusProvider] ⚠️ Violation callback! isRunning=${_state.isRunning}, app: $formattedAppName',
      );
      if (_state.isRunning ||
          (_state.status == TimerStatus.paused && !_state.isManualPause)) {
        debugPrint(
          '[StrictMode][FocusProvider] Registering strict mode violation',
        );
        _timer?.cancel();
        _emit(
          _state.copyWith(
            status: TimerStatus.paused,
            isManualPause: false,
            strictModeViolationApp: appName,
          ),
        );
      }
    });
    debugPrint('[StrictMode][FocusProvider] _initStrictMode() complete');
  }

  /// Pausa el temporizador. [manual] = true cuando el usuario presiona el botón de pausa.
  void pause({bool manual = true}) {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _emit(
      _state.copyWith(
        status: TimerStatus.paused,
        isManualPause: manual,
        clearViolationApp: true,
      ),
    );
  }

  /// Reanuda un temporizador pausado.
  void resume() {
    if (_state.status != TimerStatus.paused) return;
    start();
  }

  /// Reinicia el temporizador al comienzo del modo actual.
  void reset() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    // Detiene el monitoreo estricto si estaba activo
    if (_state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    final totalSec = _durationForMode(_state.mode) * 60;
    _emit(
      _state.copyWith(
        status: TimerStatus.idle,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        isStrictModeActive: false,
      ),
    );
  }

  /// Refresca la duración del temporizador inmediatamente si está inactivo.
  void refreshIfIdle() {
    if (_state.status == TimerStatus.idle) {
      reset();
    }
  }

  /// Detiene el temporizador completamente y vuelve a pomodoro inactivo.
  void stop() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    // Detiene el monitoreo estricto si estaba activo
    if (_state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    final totalSec =
        (settingsProvider?.pomodoroDuration.toInt() ??
            PomodoroConstants.pomodoroDuration) *
        60;
    _emit(
      TimerState(
        completedSessions: _state.completedSessions,
        totalFocusMinutes: _state.totalFocusMinutes,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        activeTaskId: _state.activeTaskId,
        activeTaskTitle: _state.activeTaskTitle,
      ),
    );
  }

  /// Cambia el modo del temporizador (Pomodoro, Descanso Corto, Descanso Largo).
  void setMode(TimerMode mode) {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    final totalSec = _durationForMode(mode) * 60;
    _emit(
      TimerState(
        mode: mode,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        completedSessions: _state.completedSessions,
        totalFocusMinutes: _state.totalFocusMinutes,
        activeTaskId: _state.activeTaskId,
        activeTaskTitle: _state.activeTaskTitle,
      ),
    );
  }

  void _tick() {
    if (_state.remainingSeconds <= 1) {
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
          _state.mode == TimerMode.pomodoro &&
          _state.activeTaskId != null &&
          !_state.quizDue &&
          _secondsSinceLastQuiz >= quizInterval) {
        triggerQuiz = true;
        _secondsSinceLastQuiz = 0;
      }

      _emit(
        _state.copyWith(
          remainingSeconds: _state.remainingSeconds - 1,
          quizDue: triggerQuiz ? true : null,
        ),
      );
    }
  }

  /// Llamado por FocusScreen después de que se muestra el diálogo del cuestionario.
  void acknowledgeQuiz() {
    _emit(_state.copyWith(quizDue: false));
  }

  /// Registra el resultado de una pregunta de cuestionario.
  void recordQuizResult(bool isCorrect, QuizResultItem item) {
    _emit(
      _state.copyWith(
        quizCorrectCount: _state.quizCorrectCount + (isCorrect ? 1 : 0),
        quizTotalCount: _state.quizTotalCount + 1,
        quizHistory: [..._state.quizHistory, item],
      ),
    );
  }

  void _onTimerFinished() {
    // Detiene el monitoreo de modo estricto cuando termina una sesión
    if (_state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }

    if (_state.mode == TimerMode.pomodoro) {
      final newSessions = _state.completedSessions + 1;
      final focusMinutes = _state.totalSeconds ~/ 60;
      final newFocusMinutes = _state.totalFocusMinutes + focusMinutes;

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
      // Experiencia por pomodoro: 1 min = 1 XP (evita farmear)
      profileProvider?.grantXP(userId, focusMinutes);
      // Monedas por pomodoro: 10 monedas por completar sesión
      profileProvider?.modificarMonedas(userId, 10);
      // Actualiza progreso de la misión
      missionsProvider?.updateProgress('pomodoro_completed', 1);
      missionsProvider?.updateProgress('minutes_studied', focusMinutes);

      // ── Acción de Enlace de Tareas ──
      if (_state.activeTaskId != null && taskProvider != null) {
        taskProvider?.incrementTaskPomodoro(_state.activeTaskId!);
      }

      // Transición automática: después de 4 pomodoros → descanso largo, si no, descanso corto
      final nextMode =
          newSessions % PomodoroConstants.pomodorosBeforeLongBreak == 0
              ? TimerMode.longBreak
              : TimerMode.shortBreak;
      final nextDuration = _durationForMode(nextMode) * 60;

      _emit(
        TimerState(
          status: TimerStatus.finished,
          mode: nextMode,
          remainingSeconds: nextDuration,
          totalSeconds: nextDuration,
          completedSessions: newSessions,
          totalFocusMinutes: newFocusMinutes,
          activeTaskId: _state.activeTaskId,
          activeTaskTitle: _state.activeTaskTitle,
          quizCorrectCount: _state.quizCorrectCount,
          quizTotalCount: _state.quizTotalCount,
          quizHistory:
              _state.quizHistory, // Mantiene el historial para revisión en la pantalla final
        ),
      );
    } else {
      // Termina el descanso → vuelve a pomodoro
      final nextDuration =
          (settingsProvider?.pomodoroDuration.toInt() ??
              PomodoroConstants.pomodoroDuration) *
          60;
      _emit(
        _state.copyWith(
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
    _emit(
      TimerState(
        status: TimerStatus.finished,
        mode: TimerMode.shortBreak,
        remainingSeconds: 5 * 60,
        totalSeconds: 5 * 60,
        completedSessions: _state.completedSessions,
        totalFocusMinutes: _state.totalFocusMinutes,
        activeTaskId: _state.activeTaskId,
        activeTaskTitle: _state.activeTaskTitle,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_state.isStrictModeActive) {
      _strictModeService.stopStrictMonitoring();
    }
    super.dispose();
  }
}
