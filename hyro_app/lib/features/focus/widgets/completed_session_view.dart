import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/timer_cubit.dart';
import '../bloc/timer_state.dart';

class CompletedSessionView extends StatelessWidget {
  final int streak;
  const CompletedSessionView({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                  const SizedBox(height: 48),
                  Center(
                    child: _buildGlowingStar(),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    '¡Excelente trabajo, John!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Has completado tu sesión con éxito. ¡Sigue así!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard('TIEMPO', '25m Focused', context),
                      _buildStatCard('PROGRESO', '+50 XP', context),
                      _buildStatCard('RACHA', '$streak Day Streak', context),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
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
                        label: 'Ver Logros',
                        icon: Icons.emoji_events,
                        isPrimary: false,
                        onPressed: () {},
                      ),
                      _buildActionButton(
                        label: 'Próxima Tarea',
                        icon: Icons.arrow_forward,
                        isPrimary: false,
                        onPressed: () {},
                      ),
                    ],
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

  Widget _buildGlowingStar() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFACC15).withOpacity(0.2),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF59E0B),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFF59E0B),
                blurRadius: 40,
              ),
            ],
          ),
          child: const Icon(
            Icons.star_rounded,
            size: 60,
            color: Color(0xFF2B1F05), // Dark interior like the image
          ),
        ),
      ),
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
