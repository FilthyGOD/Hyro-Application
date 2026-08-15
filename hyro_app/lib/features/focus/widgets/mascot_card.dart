import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../mascot/mascot_controller.dart';

/// La tarjeta de motivación de la mascota — personaje Hyro animado en Rive.
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
          // Animación de la mascota en Rive
          Consumer<MascotController>(
            builder: (context, mascot, _) {
              if (!mascot.isLoaded) {
                return const SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return SizedBox(
                width: 180,
                height: 180,
                child: RiveWidget(
                  controller: mascot.controller!,
                  fit: Fit.contain,
                ),
              );
            },
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
