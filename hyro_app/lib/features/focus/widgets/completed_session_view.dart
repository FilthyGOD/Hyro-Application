import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Animation;
import '../../../core/theme/app_typography.dart';
import '../bloc/timer_cubit.dart';
import '../bloc/timer_state.dart';
import '../../../providers/auth_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../providers/ui_provider.dart';
import '../../mascot/mascot_controller.dart';
import 'package:provider/provider.dart';
import '../models/quiz_result_item.dart';

class CompletedSessionView extends StatefulWidget {
  final int streak;
  const CompletedSessionView({super.key, required this.streak});

  @override
  State<CompletedSessionView> createState() => _CompletedSessionViewState();
}

class _CompletedSessionViewState extends State<CompletedSessionView> {
  @override
  void initState() {
    super.initState();
    // Trigger festejo animation when this view appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotController>().triggerFestejo();
    });
  }

  int get streak => widget.streak;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final auth = context.watch<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final userName = auth.currentUser?.name;
    final pomodoroMins = settings.pomodoroDuration.toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 24 : 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Center(
                    child: _buildFestejoAnimation(isMobile),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    userName != null && userName.trim().isNotEmpty
                        ? '¡Excelente trabajo, $userName!'
                        : '¡Excelente trabajo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Has completado tu sesión con éxito llevas una racha de $streak días. ¡Sigue así!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard('TIEMPO', '${pomodoroMins}m Enfoque', context),
                      _buildStatCard('PROGRESO', '+10 XP', context),
                      _buildStatCard('RACHA', '$streak Días de Racha', context),
                      if (context.read<TimerCubit>().state.quizTotalCount > 0)
                        _buildStatCard(
                           'QUIZ',
                           '${context.read<TimerCubit>().state.quizCorrectCount}/${context.read<TimerCubit>().state.quizTotalCount} ✅',
                           context,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActionButton(
                        label: 'Continuar Tarea',
                        icon: Icons.play_arrow,
                        isPrimary: true,
                        onPressed: () {
                          final cubit = context.read<TimerCubit>();
                          final state = cubit.state;
                          cubit.setMode(TimerMode.pomodoro);
                          cubit.start(taskId: state.activeTaskId, taskTitle: state.activeTaskTitle);
                        },
                      ),
                      _buildActionButton(
                        label: 'Iniciar Descanso',
                        icon: Icons.coffee,
                        isPrimary: false,
                        onPressed: () {
                          final cubit = context.read<TimerCubit>();
                          cubit.setMode(TimerMode.shortBreak);
                          cubit.start();
                        },
                      ),
                      _buildActionButton(
                        label: 'Cambiar Tarea',
                        icon: Icons.swap_horiz,
                        isPrimary: false,
                        onPressed: () {
                          context.read<TimerCubit>().reset();
                        },
                      ),
                      if (context.read<TimerCubit>().state.quizHistory.isNotEmpty)
                        _buildActionButton(
                          label: 'Resultados del Quiz',
                          icon: Icons.checklist_rtl_rounded,
                          isPrimary: false,
                          onPressed: () {
                            _showQuizHistory(context, context.read<TimerCubit>().state.quizHistory);
                          },
                        ),
                    ],
                  ),
                  Consumer<UiProvider>(
                    builder: (context, ui, _) {
                      return SizedBox(height: ui.isMusicBarVisible ? 100 : 20);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildFestejoAnimation(bool isMobile) {
    final size = isMobile ? 150.0 : 200.0;

    return Consumer<MascotController>(
      builder: (context, mascot, _) {
        if (!mascot.isLoaded) {
          // Fallback while Rive loads
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: Icon(Icons.star_rounded, size: 60, color: Color(0xFFF59E0B)),
            ),
          );
        }
        return SizedBox(
          width: size,
          height: size,
          child: RiveWidget(
            controller: mascot.controller!,
            fit: Fit.contain,
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: isMobile ? 150 : 200,
      height: isMobile ? 100 : 130,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF191D28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF3B82F6) : const Color(0xFF191D28),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: const Color(0xFF2D3748), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizHistory(BuildContext context, List<QuizResultItem> history) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF191D28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Resultados del Quiz', style: AppTypography.h3.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF2D3748), height: 32),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.isCorrect ? Icons.check_circle : Icons.cancel,
                                color: item.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Pregunta ${index + 1}',
                                      style: AppTypography.labelLarge.copyWith(color: Colors.white),
                                    ),
                                    if (item.quizType.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withAlpha(40),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.quizType,
                                          style: AppTypography.bodySmall.copyWith(color: const Color(0xFF60A5FA), fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Definición/Contexto:', style: AppTypography.labelSmall.copyWith(color: Colors.white54)),
                          Text(item.questionText, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('Tu respuesta:', style: AppTypography.labelSmall.copyWith(color: Colors.white54)),
                          Text(
                            item.userAnswer,
                            style: AppTypography.bodyLarge.copyWith(
                              color: item.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!item.isCorrect) ...[
                            const SizedBox(height: 4),
                            Text('Respuesta correcta:', style: AppTypography.labelSmall.copyWith(color: Colors.white54)),
                            Text(item.correctAnswer, style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF10B981))),
                          ]
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

