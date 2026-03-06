import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Session counter (e.g., "4/4") and Total Focus time (e.g., "2.5h") cards.
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
                Text('SESSION', style: AppTypography.statLabel),
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
                Text('TOTAL FOCUS', style: AppTypography.statLabel),
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
