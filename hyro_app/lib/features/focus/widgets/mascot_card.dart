import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// The mascot motivation card — Hyro character with a quote.
class MascotCard extends StatelessWidget {
  const MascotCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'JAIRO EL ASISTENTE',
            style: AppTypography.statLabel.copyWith(
              color: AppColors.pomodoroRed,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Mascot face
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 2),
            ),
            child: const Center(
              child: Text('🦊', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"¡Mantén el enfoque! Lo estás haciendo genial.\n¡Sigue así!"',
            style: AppTypography.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
