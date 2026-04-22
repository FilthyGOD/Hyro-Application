import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_typography.dart';
import 'bloc/timer_cubit.dart';
import 'bloc/timer_state.dart';
import 'widgets/circular_timer.dart';
import 'widgets/timer_controls.dart';
import 'widgets/mode_selector.dart';
import 'widgets/completed_session_view.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/mini_task_list.dart';
import 'widgets/task_selection_dialog.dart';
import '../stats/stats_provider.dart';
import '../tasks/tasks_provider.dart';
import '../settings/settings_provider.dart';
import '../../providers/ui_provider.dart';
import '../mascot/mascot_controller.dart';
import 'widgets/focus_quiz_dialog.dart';
import 'widgets/pause_clock.dart';
import '../../data/local/card_local_ds.dart';
import '../../data/local/note_local_ds.dart';
import '../../data/local/note_local_ds.dart';
import 'widgets/strict_mode_violation_card.dart';

/// The main Focus screen with the Pomodoro timer and sidebar widgets.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerCubit, TimerState>(
      listenWhen: (prev, curr) => (prev.status != curr.status) || (prev.quizDue != curr.quizDue) || (prev.strictModeViolationApp != curr.strictModeViolationApp),
      listener: (context, state) {
        final mascot = context.read<MascotController>();
        
        if (state.strictModeViolationApp != null) {
          mascot.triggerPensando();
          showDialog(
             context: context,
             barrierDismissible: false,
             builder: (_) => StrictModeViolationCard(appName: state.strictModeViolationApp!),
          ).then((_) {
             mascot.resumeEstudio();
             if (!context.mounted) return;
             if (context.read<TimerCubit>().state.isPaused) {
                context.read<TimerCubit>().resume();
             }
          });
          return;
        }

        if (state.quizDue && state.isRunning) {
           final cardLocal = CardLocalDataSource();
           final noteLocal = NoteLocalDataSource();
           final cards = cardLocal.getCardsForTask(state.activeTaskId!);
           final notes = noteLocal.getNotesForTask(state.activeTaskId!);
           
           if (cards.isNotEmpty || notes.isNotEmpty) {
             context.read<TimerCubit>().pause(manual: false);
             mascot.triggerPensando();

             showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FocusQuizDialog(flashcards: cards, notas: notes),
             ).then((_) {
                 mascot.resumeEstudio();
                 // only resume if it's currently paused
                 if (!context.mounted) return;
                 if (context.read<TimerCubit>().state.isPaused) {
                    context.read<TimerCubit>().resume();
                 }
             });
           } else {
             context.read<TimerCubit>().acknowledgeQuiz();
           }
        } else if (state.quizDue) {
           // Do not override mascot state if a quiz pause is active.
        } else if (state.isRunning && state.mode == TimerMode.pomodoro) {
          mascot.triggerEstudiando();
        } else if (state.isRunning &&
            (state.mode == TimerMode.shortBreak ||
                state.mode == TimerMode.longBreak)) {
          mascot.triggerHueva();
        } else if (state.isPaused) {
          if (state.isManualPause) {
            mascot.triggerHueva();
          } else {
            mascot.triggerVolver();
          }
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
                                    if (state.isRunning && state.activeTaskTitle != null) ...[
                                      _ActiveTaskBadge(
                                        taskId: state.activeTaskId ?? '',
                                        title: state.activeTaskTitle!,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    // The content (Timer, Controls, Scroller)
                                    if (state.isPaused && state.isManualPause)
                                      PauseClock(
                                        size: timerSize,
                                      )
                                    else
                                      CircularTimer(
                                        remainingSeconds: state.remainingSeconds,
                                        progress: state.progress,
                                        size: timerSize,
                                      ),
                                    const SizedBox(height: 16),
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
                                    if (!state.isRunning && !state.isPaused)
                                      ModeSelector(
                                        currentMode: state.mode,
                                        onStart: () => _handleStart(context, cubit),
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
                            const MiniTaskList(),
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
              if (state.activeTaskTitle != null) ...[
                _ActiveTaskBadge(
                  taskId: state.activeTaskId ?? '',
                  title: state.activeTaskTitle!,
                ),
                const SizedBox(height: 24),
              ],
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final size =
                        (availableWidth * 0.75).clamp(160.0, 260.0) *
                        settings.timerSizeMultiplier;
                    if (state.isPaused && state.isManualPause) {
                      return PauseClock(size: size);
                    }
                    return CircularTimer(
                      remainingSeconds: state.remainingSeconds,
                      progress: state.progress,
                      size: size,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
              if (!state.isRunning && !state.isPaused)
                ModeSelector(
                  currentMode: state.mode,
                  onStart: () => _handleStart(context, cubit),
                ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 72,
        bottom: 20,
        left: 20,
        right: 20,
      ),
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
                  if (state.isPaused && state.isManualPause) {
                    return PauseClock(size: size);
                  }
                  return CircularTimer(
                    remainingSeconds: state.remainingSeconds,
                    progress: state.progress,
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
            if (!state.isRunning && !state.isPaused)
              ModeSelector(
                currentMode: state.mode,
                onStart: () => _handleStart(context, cubit),
              ),
            if (!state.isRunning && !settings.hideFocusCards) ...[
              const SizedBox(height: 24),
              const MiniTaskList(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

void _handleStart(BuildContext context, TimerCubit cubit) {
  final settings = context.read<SettingsProvider>();
  final isStrictMode = Platform.isAndroid && settings.strictMode;

  showDialog<dynamic>(
    context: context,
    builder: (ctx) => const TaskSelectionDialog(),
  ).then((result) {
    if (result == 'NO_TASK') {
      cubit.start(isStrictMode: isStrictMode);
    } else if (result != null && result is Map) {
      final taskId = result['id'] as String;
      final taskTitle = result['title'] as String;
      cubit.start(taskId: taskId, taskTitle: taskTitle, isStrictMode: isStrictMode);
    }
  });
}

class _ActiveTaskBadge extends StatelessWidget {
  final String taskId;
  final String title;

  const _ActiveTaskBadge({required this.taskId, required this.title});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    try {
      final tasksProvider = context.watch<TaskProvider>();
      final task = tasksProvider.tasks.firstWhere((t) => t.id == taskId);
      color = Color(task.priorityColorValue);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
