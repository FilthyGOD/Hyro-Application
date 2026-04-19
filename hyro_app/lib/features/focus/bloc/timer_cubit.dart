import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/pomodoro_constants.dart';
import '../../stats/stats_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../missions/missions_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notifications_service.dart';
import 'timer_state.dart';

/// Cubit that manages the Pomodoro timer logic.
class TimerCubit extends Cubit<TimerState> {
  Timer? _timer;
  int _secondsSinceLastQuiz = 0;
  final StatsProvider? statsProvider;
  final SettingsProvider? settingsProvider;
  final ProfileProvider? profileProvider;
  final MissionsProvider? missionsProvider;
  final TaskProvider? taskProvider;

  /// Optional reference to AuthProvider — set from outside after creation.
  AuthProvider? authProvider;

  TimerCubit({
    this.statsProvider,
    this.settingsProvider,
    this.profileProvider,
    this.missionsProvider,
    this.taskProvider,
  }) : super(const TimerState());

  /// Start the timer.
  void start({String? taskId, String? taskTitle}) {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(
      status: TimerStatus.running,
      activeTaskId: taskId ?? state.activeTaskId,
      activeTaskTitle: taskTitle ?? state.activeTaskTitle,
      quizDue: false,
    ));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    NotificationsService.instance.schedulePomodoroEndNotification(
      state.mode == TimerMode.pomodoro, 
      state.remainingSeconds
    );
  }

  /// Pause the timer.
  void pause() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    emit(state.copyWith(status: TimerStatus.paused));
  }

  /// Resume a paused timer.
  void resume() {
    if (state.status != TimerStatus.paused) return;
    start();
  }

  /// Reset the timer to the beginning of the current mode.
  void reset() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    final totalSec = _durationForMode(state.mode) * 60;
    emit(
      state.copyWith(
        status: TimerStatus.idle,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
      ),
    );
  }

  /// Refreshes the timer duration immediately if it's idle.
  void refreshIfIdle() {
    if (state.status == TimerStatus.idle) {
      reset();
    }
  }

  /// Stop the timer completely and go back to idle pomodoro.
  void stop() {
    _timer?.cancel();
    NotificationsService.instance.cancelPomodoroNotification();
    _secondsSinceLastQuiz = 0;
    final totalSec = (settingsProvider?.pomodoroDuration.toInt() ?? PomodoroConstants.pomodoroDuration) * 60;
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

  /// Switch timer mode (Pomodoro, Short Break, Long Break).
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

      // Check if quiz is due (only during pomodoro mode, quiz enabled, and has a task)
      final quizEnabled = settingsProvider?.focusQuizEnabled ?? false;
      final quizInterval = ((settingsProvider?.focusQuizIntervalMinutes ?? 5) * 60).toInt();
      bool triggerQuiz = false;

      if (quizEnabled &&
          state.mode == TimerMode.pomodoro &&
          state.activeTaskId != null &&
          !state.quizDue &&
          _secondsSinceLastQuiz >= quizInterval) {
        triggerQuiz = true;
        _secondsSinceLastQuiz = 0;
      }

      emit(state.copyWith(
        remainingSeconds: state.remainingSeconds - 1,
        quizDue: triggerQuiz ? true : null,
      ));
    }
  }

  /// Called by the FocusScreen after the quiz dialog is shown.
  void acknowledgeQuiz() {
    emit(state.copyWith(quizDue: false));
  }

  /// Records the result of a quiz question.
  void recordQuizResult(bool isCorrect) {
    emit(state.copyWith(
      quizCorrectCount: state.quizCorrectCount + (isCorrect ? 1 : 0),
      quizTotalCount: state.quizTotalCount + 1,
    ));
  }

  void _onTimerFinished() {
    if (state.mode == TimerMode.pomodoro) {
      final newSessions = state.completedSessions + 1;
      final focusMinutes = state.totalSeconds ~/ 60;
      final newFocusMinutes = state.totalFocusMinutes + focusMinutes;

      final userId = authProvider?.supabaseUserId;
      
      // Tell stats provider to record this session locally and sync to cloud
      statsProvider?.addFocusSession(focusMinutes, userId);

      Future.microtask(() {
         // After it updates local StatsBox, we capture the newest real dynamic streak
         final currentDynamicStreak = statsProvider?.currentStreak ?? 0;
         profileProvider?.syncDynamicStats(userId, currentDynamicStreak, focusMinutes);
      });

      // ── Gamification hooks ──
      // 10 XP per completed pomodoro (grantXP natively supports local accounts)
      profileProvider?.grantXP(userId, 10);
      // Update mission progress
      missionsProvider?.updateProgress('pomodoro_completed', 1);
      missionsProvider?.updateProgress('minutes_studied', focusMinutes);

      // ── Task Linking hook ──
      if (state.activeTaskId != null && taskProvider != null) {
        taskProvider?.incrementTaskPomodoro(state.activeTaskId!);
      }

      // Auto-transition: after 4 pomodoros → long break, else short break
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
        ),
      );
    } else {
      // Break finished → go back to pomodoro
      final nextDuration = (settingsProvider?.pomodoroDuration.toInt() ?? PomodoroConstants.pomodoroDuration) * 60;
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
        return settingsProvider?.pomodoroDuration.toInt() ?? PomodoroConstants.pomodoroDuration;
      case TimerMode.shortBreak:
        return settingsProvider?.shortBreakDuration.toInt() ?? PomodoroConstants.shortBreakDuration;
      case TimerMode.longBreak:
        return settingsProvider?.longBreakDuration.toInt() ?? PomodoroConstants.longBreakDuration;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
