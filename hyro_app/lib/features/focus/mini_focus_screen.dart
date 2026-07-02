import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/ui_provider.dart';
import 'bloc/timer_cubit.dart';
import 'bloc/timer_state.dart';
import 'widgets/circular_timer.dart';
import 'widgets/timer_controls.dart';

class MiniFocusScreen extends StatelessWidget {
  const MiniFocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimerCubit>();
    final state = context.watch<TimerCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Área de arrastre para la ventana
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                // Si usas window_manager, arrastrar puede implementarse usando windowManager.startDragging()
              },
              child: Container(),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20), // Espacio superior
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: IconButton(
                        tooltip: 'Return to full app',
                        icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70),
                        onPressed: () {
                          context.read<UiProvider>().setMiniMode(false);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (state.activeTaskTitle != null && state.isRunning) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Enfocando en:\n${state.activeTaskTitle}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  CircularTimer(
                    remainingSeconds: state.remainingSeconds,
                    progress: state.progress,
                    label: _getTimerLabel(state.mode),
                    size: 160,
                  ),
                  const SizedBox(height: 24),
                  TimerControls(
                    isRunning: state.isRunning,
                    isPaused: state.isPaused,
                    buttonSizeMultiplier: 0.8,
                    onStart: cubit.start,
                    onPause: cubit.pause,
                    onResume: cubit.resume,
                    onReset: cubit.reset,
                    onStop: () {
                      cubit.stop();
                      context.read<UiProvider>().setMiniMode(false);
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
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
