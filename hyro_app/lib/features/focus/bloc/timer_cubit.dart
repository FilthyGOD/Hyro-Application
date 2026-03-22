import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/pomodoro_constants.dart';
import '../../stats/stats_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../missions/missions_provider.dart';
import '../../../providers/auth_provider.dart';
import 'timer_state.dart';

/// Cubit that manages the Pomodoro timer logic.
class TimerCubit extends Cubit<TimerState> {
  Timer? _timer;
  final StatsProvider? statsProvider;
  final SettingsProvider? settingsProvider;
  final ProfileProvider? profileProvider;
  final MissionsProvider? missionsProvider;

  /// Optional reference to AuthProvider — set from outside after creation.
  AuthProvider? authProvider;

  TimerCubit({
    this.statsProvider,
    this.settingsProvider,
    this.profileProvider,
    this.missionsProvider,
  }) : super(const TimerState());

  /// Start the timer.
  void start() {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(status: TimerStatus.running));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Pause the timer.
  void pause() {
    _timer?.cancel();
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
    final totalSec = (settingsProvider?.pomodoroDuration.toInt() ?? PomodoroConstants.pomodoroDuration) * 60;
    emit(
      TimerState(
        completedSessions: state.completedSessions,
        totalFocusMinutes: state.totalFocusMinutes,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
      ),
    );
  }

  /// Switch timer mode (Pomodoro, Short Break, Long Break).
  void setMode(TimerMode mode) {
    _timer?.cancel();
    final totalSec = _durationForMode(mode) * 60;
    emit(
      TimerState(
        mode: mode,
        remainingSeconds: totalSec,
        totalSeconds: totalSec,
        completedSessions: state.completedSessions,
        totalFocusMinutes: state.totalFocusMinutes,
      ),
    );
  }

  void _tick() {
    if (state.remainingSeconds <= 1) {
      _timer?.cancel();
      _onTimerFinished();
    } else {
      emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
    }
  }

  void _onTimerFinished() {
    if (state.mode == TimerMode.pomodoro) {
      final newSessions = state.completedSessions + 1;
      final focusMinutes = state.totalSeconds ~/ 60;
      final newFocusMinutes = state.totalFocusMinutes + focusMinutes;

      // Tell stats provider to record this session
      statsProvider?.addFocusSession(focusMinutes);

      // ── Gamification hooks ──
      final userId = authProvider?.supabaseUserId;
      if (userId != null) {
        // 10 XP per completed pomodoro
        profileProvider?.grantXP(userId, 10);
      }
      // Update mission progress
      missionsProvider?.updateProgress('pomodoro_completed', 1);
      missionsProvider?.updateProgress('minutes_studied', focusMinutes);

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
