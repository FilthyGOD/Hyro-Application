import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// unused import removed
import '../../core/theme/app_typography.dart';
import 'bloc/timer_cubit.dart';
import 'bloc/timer_state.dart';
import 'widgets/circular_timer.dart';
import 'widgets/timer_controls.dart';
import 'widgets/mode_selector.dart';
import 'widgets/session_info_card.dart';
import 'widgets/completed_session_view.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/mini_task_list.dart';
import 'widgets/activity_chart.dart';
import 'widgets/task_selection_dialog.dart';
import '../stats/stats_provider.dart';
import '../mascot/mascot_controller.dart';
import '../settings/settings_provider.dart';
import '../../providers/ui_provider.dart';
import 'widgets/focus_quiz_dialog.dart';
import '../../data/local/card_local_ds.dart';
import '../../data/local/note_local_ds.dart';

/// The main Focus screen with the Pomodoro timer and sidebar widgets.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerCubit, TimerState>(
      listenWhen: (prev, curr) => (prev.status != curr.status) || (prev.quizDue != curr.quizDue),
      listener: (context, state) {
        final mascot = context.read<MascotController>();
        if (state.quizDue && state.isRunning) {
           final cardLocal = CardLocalDataSource();
           final noteLocal = NoteLocalDataSource();
           final cards = cardLocal.getCardsForTask(state.activeTaskId!);
           final notes = noteLocal.getNotesForTask(state.activeTaskId!);
           
           if (cards.isNotEmpty || notes.isNotEmpty) {
             context.read<TimerCubit>().pause();
             showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FocusQuizDialog(flashcards: cards, notas: notes),
             ).then((_) {
                 // only resume if it's currently paused
                 if (context.read<TimerCubit>().state.isPaused) {
                    context.read<TimerCubit>().resume();
                 }
             });
           } else {
             context.read<TimerCubit>().acknowledgeQuiz();
           }
        } else if (state.isRunning && state.mode == TimerMode.pomodoro) {
          mascot.triggerEstudiando();
        } else if (state.isRunning &&
            (state.mode == TimerMode.shortBreak ||
                state.mode == TimerMode.longBreak)) {
          mascot.triggerHueva();
        } else if (state.isPaused) {
          mascot.triggerVolver();
        } else if (state.isIdle) {
          mascot.triggerVolver();
        }
      },
      child: BlocBuilder<TimerCubit, TimerState>(
        builder: (context, state) {
          final statsProvider = context.watch<StatsProvider>();
          final streak = statsProvider.currentStreak;
          final todaysStats = statsProvider.todaysStats;
          final sessionsToday = todaysStats?.focusSessions ?? 0;
          final minutesToday = todaysStats?.focusMinutes ?? 0;

          final isPomodoroFinished =
              state.isFinished &&
              (state.mode == TimerMode.shortBreak ||
                  state.mode == TimerMode.longBreak);

          if (isPomodoroFinished) {
            return CompletedSessionView(streak: streak);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _DesktopLayout(
                  state: state,
                  streak: streak,
                  sessionsToday: sessionsToday,
                  minutesToday: minutesToday,
                );
              }
              return _MobileLayout(
                state: state,
                streak: streak,
                sessionsToday: sessionsToday,
                minutesToday: minutesToday,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Desktop: two-column layout ──
class _DesktopLayout extends StatelessWidget {
  final TimerState state;
  final int streak;
  final int sessionsToday;
  final int minutesToday;

  const _DesktopLayout({
    required this.state,
    required this.streak,
    required this.sessionsToday,
    required this.minutesToday,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimerCubit>();
    final settings = context.watch<SettingsProvider>();

    final isCentered = state.isRunning || settings.hideFocusCards;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isCentered ? 32 : 72,
            top: 32,
            right: 32,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!state.isRunning) ...[
                _buildHeader(context, streak),
                const SizedBox(height: 32),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left column: timer (SCROLLABLE IF NEEDED) ──
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: isCentered ? 1 : 3),
                          Expanded(
                            flex: 10,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate a dynamic size based on available height,
                                // ensuring it leaves room for controls and spacing.
                                // Max size 460, Min size 160 (to force it to fit without scroll).
                                final availableHeight = constraints.maxHeight;
                                final desiredTimerSize =
                                    availableHeight -
                                    240; // 240px reserved for controls and padding
                                final settings =
                                    context.watch<SettingsProvider>();
                                final timerSize =
                                    desiredTimerSize.clamp(160.0, 460.0) *
                                    settings.timerSizeMultiplier;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // The content (Timer, Controls, Scroller)
                                    CircularTimer(
                                      remainingSeconds: state.remainingSeconds,
                                      progress: state.progress,
                                      label: _getTimerLabel(state.mode),
                                      size: timerSize,
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.isRunning &&
                                        state.activeTaskTitle != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Text(
                                          'Enfocando en: ${state.activeTaskTitle}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.primary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    if (state.isRunning && state.quizTotalCount > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Quiz: ${state.quizCorrectCount}/${state.quizTotalCount} ✅',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.breakGreen),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    TimerControls(
                                      isRunning: state.isRunning,
                                      isPaused: state.isPaused,
                                      onStart:
                                          () => _handleStart(context, cubit),
                                      onPause: cubit.pause,
                                      onResume: cubit.resume,
                                      onReset: cubit.reset,
                                      onStop: cubit.stop,
                                    ),
                                    const SizedBox(height: 24),
                                    ModeSelector(
                                      currentMode: state.mode,
                                      onModeChanged: cubit.setMode,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Spacer(flex: isCentered ? 1 : 2),
                        ],
                      ),
                    ),
                    // ── Right column: info cards (SCROLLABLE) ──
                    if (!state.isRunning && !settings.hideFocusCards) ...[
                      const SizedBox(width: 48),
                      SizedBox(
                        width:
                            320, // Fixed width so data cards aren't stretched
                        child: ListView(
                          children: [
                            SessionInfoCard(
                              completedSessions: sessionsToday,
                              totalFocusMinutes: minutesToday,
                            ),
                            const SizedBox(height: 16),
                            const MiniTaskList(),
                            const SizedBox(height: 16),
                            const ActivityChart(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 32,
          right: 32,
          child: Tooltip(
            message: 'Keep on top',
            child: IconButton(
              icon: const Icon(
                Icons.picture_in_picture_alt,
                color: Colors.white70,
              ),
              onPressed: () {
                context.read<UiProvider>().setMiniMode(true);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int streak) {
    final now = DateTime.now();
    final dayNames = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final monthNames = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesión de Trabajo Profundo', style: AppTypography.h1),
            const SizedBox(height: 4),
            Text(
              '${dayNames[now.weekday - 1]}, ${now.day} de ${monthNames[now.month - 1]} • Racha de Enfoque: $streak días 🔥',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  String _getTimerLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'TIEMPO HASTA EL DESCANSO';
      case TimerMode.shortBreak:
        return 'DESCANSO CORTO';
      case TimerMode.longBreak:
        return 'DESCANSO LARGO';
    }
  }
}

// ── Mobile: single-column scrollable layout ──
class _MobileLayout extends StatelessWidget {
  final TimerState state;
  final int streak;
  final int sessionsToday;
  final int minutesToday;

  const _MobileLayout({
    required this.state,
    required this.streak,
    required this.sessionsToday,
    required this.minutesToday,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimerCubit>();
    final settings = context.watch<SettingsProvider>();

    // When timer is running, use Center layout instead of scroll
    if (state.isRunning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final size =
                        (availableWidth * 0.75).clamp(160.0, 260.0) *
                        settings.timerSizeMultiplier;
                    return CircularTimer(
                      remainingSeconds: state.remainingSeconds,
                      progress: state.progress,
                      label: _getTimerLabel(state.mode),
                      size: size,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (state.activeTaskTitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Enfocando en: ${state.activeTaskTitle}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (state.isRunning && state.quizTotalCount > 0)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Text(
                     'Quiz: ${state.quizCorrectCount}/${state.quizTotalCount} ✅',
                     style: AppTypography.bodySmall.copyWith(color: AppColors.breakGreen),
                     textAlign: TextAlign.center,
                   ),
                 ),
              const SizedBox(height: 8),
              TimerControls(
                isRunning: state.isRunning,
                isPaused: state.isPaused,
                onStart: () => _handleStart(context, cubit),
                onPause: cubit.pause,
                onResume: cubit.resume,
                onReset: cubit.reset,
                onStop: cubit.stop,
              ),
              const SizedBox(height: 24),
              ModeSelector(
                currentMode: state.mode,
                onModeChanged: cubit.setMode,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 20,
      ).copyWith(top: 64),
      child: Container(
        width: double.infinity,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!state.isRunning) ...[
              // Header
              Text('Sesión de Trabajo Profundo', style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                'Racha de Enfoque: $streak días 🔥',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              // Session info
              if (!settings.hideFocusCards) ...[
                SessionInfoCard(
                  completedSessions: sessionsToday,
                  totalFocusMinutes: minutesToday,
                ),
                const SizedBox(height: 24),
              ],
            ],
            // Timer
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final settings = context.watch<SettingsProvider>();
                  final size =
                      (availableWidth * 0.75).clamp(160.0, 260.0) *
                      settings.timerSizeMultiplier;
                  return CircularTimer(
                    remainingSeconds: state.remainingSeconds,
                    progress: state.progress,
                    label: _getTimerLabel(state.mode),
                    size: size,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            // Controls
            TimerControls(
              isRunning: state.isRunning,
              isPaused: state.isPaused,
              onStart: () => _handleStart(context, cubit),
              onPause: cubit.pause,
              onResume: cubit.resume,
              onReset: cubit.reset,
              onStop: cubit.stop,
            ),
            const SizedBox(height: 24),
            ModeSelector(currentMode: state.mode, onModeChanged: cubit.setMode),
            if (!state.isRunning && !settings.hideFocusCards) ...[
              const SizedBox(height: 24),
              const MiniTaskList(),
              const SizedBox(height: 16),
              const ActivityChart(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _getTimerLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'TIEMPO HASTA EL DESCANSO';
      case TimerMode.shortBreak:
        return 'DESCANSO CORTO';
      case TimerMode.longBreak:
        return 'DESCANSO LARGO';
    }
  }
}

void _handleStart(BuildContext context, TimerCubit cubit) {
  showDialog<dynamic>(
    context: context,
    builder: (ctx) => const TaskSelectionDialog(),
  ).then((result) {
    if (result == 'NO_TASK') {
      cubit.start();
    } else if (result != null && result is Map) {
      final taskId = result['id'] as String;
      final taskTitle = result['title'] as String;
      cubit.start(taskId: taskId, taskTitle: taskTitle);
    }
  });
}
