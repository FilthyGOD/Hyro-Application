import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Shop screen — placeholder for future implementation.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text('Tienda', style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(
            '¡Próximamente!',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Desbloquea temas, mascotas y más.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: null,
            child: Text('Notifícame', style: AppTypography.chip.copyWith(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}
