import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Barra superior estilo AppBar para móvil que muestra la racha y monedas del usuario.
/// Se usa en las pantallas de Enfoque y Tareas.
class MobileStatsBar extends StatelessWidget {
  const MobileStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Racha ──
          _StatChip(
            icon: profile.rachaActual > 0
                ? const Text('🔥', style: TextStyle(fontSize: 18))
                : Icon(
                    Icons.local_fire_department_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
            value: '${profile.rachaActual}',
            label: 'racha',
          ),
          // ── Monedas ──
          _StatChip(
            icon: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 20,
            ),
            value: _formatNumber(profile.monedas),
            label: 'monedas',
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatChip extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
