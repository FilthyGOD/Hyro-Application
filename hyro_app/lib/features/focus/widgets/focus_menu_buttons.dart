import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/screens/tasks_screen.dart';

/// Botones de navegación rápida para la pantalla de Enfoque / Menú principal:
/// Agenda, Amigos y Horario.
class FocusMenuButtons extends StatelessWidget {
  const FocusMenuButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _MenuActionButton(
                icon: Icons.calendar_month_rounded,
                label: 'Agenda',
                onTap: () {
                  TasksScreen.switchToAgenda();
                  final appShell = context.findAncestorStateOfType<AppShellState>() ??
                      appShellKey.currentState;
                  appShell?.navigateTo(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MenuActionButton(
                icon: Icons.people_alt_rounded,
                label: 'Amigos',
                onTap: () {
                  final appShell = context.findAncestorStateOfType<AppShellState>() ??
                      appShellKey.currentState;
                  appShell?.navigateTo(4);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MenuActionButton(
          icon: Icons.schedule_rounded,
          label: 'Horario',
          isFullWidth: true,
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Próximamente: Horario'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MenuActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _MenuActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withAlpha(40),
          highlightColor: AppColors.primary.withAlpha(20),
          hoverColor: AppColors.primary.withAlpha(15),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

