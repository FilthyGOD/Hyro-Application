import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Tarjetas de contador de sesión (ej. "4/4") y Tiempo Total de Enfoque (ej. "2.5h").
class SessionInfoCard extends StatelessWidget {
  final int completedSessions;
  final int totalFocusMinutes;

  const SessionInfoCard({
    super.key,
    required this.completedSessions,
    required this.totalFocusMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Text('SESIÓN', style: AppTypography.statLabel),
                const SizedBox(height: 6),
                Text(
                  '$completedSessions/4',
                  style: AppTypography.statNumber,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Text('ENFOQUE TOTAL', style: AppTypography.statLabel),
                const SizedBox(height: 6),
                Text(
                  _formatHours(totalFocusMinutes),
                  style: AppTypography.statNumber,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes / 60;
    return '${h.toStringAsFixed(1)}h';
  }
}
