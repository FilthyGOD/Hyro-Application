import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import 'bloc/timer_cubit.dart';
import 'bloc/timer_state.dart';
import 'widgets/circular_timer.dart';
import 'widgets/timer_controls.dart';
import 'widgets/mode_selector.dart';
import 'widgets/session_info_card.dart';
import 'widgets/mascot_card.dart';
import 'widgets/mini_task_list.dart';
import 'widgets/activity_chart.dart';
import '../stats/stats_provider.dart';
import '../mascot/mascot_controller.dart';

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
          _buildHeader(context, streak),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left column: timer (SCROLLABLE IF NEEDED) ──
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
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
                            final timerSize = desiredTimerSize.clamp(
                              160.0,
                              460.0,
                            );

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
                                const SizedBox(height: 32),
                                TimerControls(
                                  isRunning: state.isRunning,
                                  isPaused: state.isPaused,
                                  onStart: cubit.start,
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
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // ── Right column: info cards (SCROLLABLE) ──
                SizedBox(
                  width: 320, // Fixed width so data cards aren't stretched
                  child: ListView(
                    // ListView instead of SingleChildScrollView+Column for better scroll behavior
                    children: [
                      SessionInfoCard(
                        completedSessions: sessionsToday,
                        totalFocusMinutes: minutesToday,
                      ),
                      const SizedBox(height: 16),
                      const MascotCard(),
                      const SizedBox(height: 16),
                      const MiniTaskList(),
                      const SizedBox(height: 16),
                      const ActivityChart(),
                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
                ),
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
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.dark_mode, color: AppColors.textSecondary),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
              ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 64, left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          // Header
          Text('Sesión de Trabajo Profundo', style: AppTypography.h2),
          const SizedBox(height: 4),
          Text(
            'Racha de Enfoque: $streak días 🔥',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
          // Session info
          SessionInfoCard(
            completedSessions: sessionsToday,
            totalFocusMinutes: minutesToday,
          ),
          const SizedBox(height: 24),
          // Timer
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // Make timer responsive: max 260, but scales down if screen is narrow
              final size = (availableWidth * 0.75).clamp(160.0, 260.0);
              return CircularTimer(
                remainingSeconds: state.remainingSeconds,
                progress: state.progress,
                label: _getTimerLabel(state.mode),
                size: size,
              );
            },
          ),
          const SizedBox(height: 24),
          // Controls
          TimerControls(
            isRunning: state.isRunning,
            isPaused: state.isPaused,
            onStart: cubit.start,
            onPause: cubit.pause,
            onResume: cubit.resume,
            onReset: cubit.reset,
            onStop: cubit.stop,
          ),
          const SizedBox(height: 20),
          // Mode selector
          ModeSelector(currentMode: state.mode, onModeChanged: cubit.setMode),
          const SizedBox(height: 24),
          const MascotCard(),
          const SizedBox(height: 16),
          const MiniTaskList(),
          const SizedBox(height: 16),
          const ActivityChart(),
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
