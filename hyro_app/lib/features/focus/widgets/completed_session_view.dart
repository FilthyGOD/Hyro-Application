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
                  _buildHeader(context),
                  const SizedBox(height: 32),
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
                  const Text(
                    'Has completado tu sesión con éxito. ¡Sigue así!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                        label: 'Iniciar Descanso',
                        icon: Icons.coffee,
                        isPrimary: true,
                        onPressed: () {
                          final cubit = context.read<TimerCubit>();
                          cubit.setMode(TimerMode.shortBreak);
                          cubit.start();
                        },
                      ),
                      _buildActionButton(
                        label: 'Próxima Tarea',
                        icon: Icons.arrow_forward,
                        isPrimary: false,
                        onPressed: () {},
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

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Sesión Completada', style: AppTypography.h1, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]} • Racha de Focus: $streak días 🔥',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
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
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF191D28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
      ),
      child: Column(
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
}
