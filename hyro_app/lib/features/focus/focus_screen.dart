import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// unused import removed
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
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
import '../stats/stats_provider.dart';
import '../tasks/tasks_provider.dart';
import '../mascot/mascot_controller.dart';
import '../settings/settings_provider.dart';

/// The main Focus screen with the Pomodoro timer and sidebar widgets.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return BlocListener<TimerCubit, TimerState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        final mascot = context.read<MascotController>();
        if (state.isRunning && state.mode == TimerMode.pomodoro) {
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

          if (isDesktop) {
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

    return Padding(
      padding: const EdgeInsets.only(left: 72, top: 32, right: 32, bottom: 32),
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
                      Spacer(flex: state.isRunning ? 1 : 3),
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
                            final settings = context.watch<SettingsProvider>();
                            final timerSize = desiredTimerSize.clamp(
                              160.0,
                              460.0,
                            ) * settings.timerSizeMultiplier;

                            return Column(
                              children: [
                                // Top spacer to push content down
                                const Spacer(flex: 1),

                                // The content (Timer, Controls, Scroller)
                                CircularTimer(
                                  remainingSeconds: state.remainingSeconds,
                                  progress: state.progress,
                                  label: _getTimerLabel(state.mode),
                                  size: timerSize,
                                ),
                                const SizedBox(height: 16),
                                if (state.isRunning && state.activeTaskTitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'Enfocando en: ${state.activeTaskTitle}',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 16),
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

                                // Bottom spacer (flex: 2) to push content higher up
                                // compensating for the space the music player takes later.
                                const Spacer(flex: 3),
                              ],
                            );
                          },
                        ),
                      ),
                      Spacer(flex: state.isRunning ? 1 : 2),
                    ],
                  ),
                ),
                // ── Right column: info cards (SCROLLABLE) ──
                if (!state.isRunning) ...[
                  const SizedBox(width: 48),
                  SizedBox(
                    width: 320, // Fixed width so data cards aren't stretched
                    child: Builder(
                      builder: (context) {
                        final settings = context.watch<SettingsProvider>();
                        if (settings.hideFocusCards) return const SizedBox.shrink();
                        
                        return ListView(
                          // ListView instead of SingleChildScrollView+Column for better scroll behavior
                          children: [
                            SessionInfoCard(
                              completedSessions: sessionsToday,
                              totalFocusMinutes: minutesToday,
                            ),
                            const SizedBox(height: 16),
                            const MiniTaskList(),
                            const SizedBox(height: 16),
                            const ActivityChart(),
                            const SizedBox(height: 32), // Bottom padding
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 64, left: 20, right: 20, bottom: 20),
      child: Column(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final settings = context.watch<SettingsProvider>();
              // Make timer responsive: max 260, but scales down if screen is narrow
              final size = (availableWidth * 0.75).clamp(160.0, 260.0) * settings.timerSizeMultiplier;
              return CircularTimer(
                remainingSeconds: state.remainingSeconds,
                progress: state.progress,
                label: _getTimerLabel(state.mode),
                size: size,
              );
            },
          ),
          const SizedBox(height: 16),
          if (state.isRunning && state.activeTaskTitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Enfocando en: ${state.activeTaskTitle}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
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
          const SizedBox(height: 80), // space for radio bar
        ],
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
  final taskProvider = context.read<TaskProvider>();
  final pendingTasks = taskProvider.tasks.where((t) => !t.isCompleted).toList();

  if (pendingTasks.isEmpty) {
    cubit.start();
    return;
  }

  showDialog<String?>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selecciona una tarea para enfocarte', style: AppTypography.h3, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: pendingTasks.length,
                itemBuilder: (context, index) {
                  final task = pendingTasks[index];
                  return ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Color(task.priorityColorValue)),
                    title: Text(task.title, style: AppTypography.bodyMedium),
                    subtitle: Text('${task.pomodorosCompleted} / ${task.pomodorosTarget} Pomodoros', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => Navigator.pop(ctx, task.id),
                  );
                },
              ),
            ),
            const Divider(color: AppColors.cardBorder),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.white54),
              title: const Text('Empezar sin tarea', style: TextStyle(color: Colors.white54)),
              onTap: () => Navigator.pop(ctx, 'NO_TASK'),
            ),
            ],
          ),
        ),
      );
    },
  ).then((taskId) {
    if (taskId == 'NO_TASK') {
      cubit.start();
    } else if (taskId != null) {
      final task = pendingTasks.firstWhere((t) => t.id == taskId);
      cubit.start(taskId: task.id, taskTitle: task.title);
    }
  });
}
