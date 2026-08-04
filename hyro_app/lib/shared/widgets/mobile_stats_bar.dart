import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/shop/premium_shop_screen.dart';

/// Barra superior estilo AppBar para móvil que muestra la racha y monedas del usuario.
/// Se usa en las pantallas de Enfoque, Tareas y Perfil.
class MobileStatsBar extends StatelessWidget {
  /// Widget opcional que se muestra al final de la barra (ej: botón de ajustes).
  final Widget? trailing;

  const MobileStatsBar({super.key, this.trailing});

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
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Racha ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon:
                profile.rachaActual > 0
                    ? const Text('🔥', style: TextStyle(fontSize: 18))
                    : Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
            value: '${profile.rachaActual}',
          ),
          const SizedBox(width: 12),
          // ── Monedas ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 20,
            ),
            value: _formatNumber(profile.monedas),
          ),
          const SizedBox(width: 12),
          // ── Protectores ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon: const Text('🛡️', style: TextStyle(fontSize: 18)),
            value: '${profile.protectoresRachaActivos}',
          ),
          const SizedBox(width: 12),
          // ── XP Doble ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatChip(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PremiumShopScreen(),
                    ),
                  );
                },
                icon: const Text('🧪', style: TextStyle(fontSize: 18)),
                value: '${profile.sesionesXPDobleRestantes}',
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
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
  final VoidCallback? onTap;

  const _StatChip({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
      ),
    );
  }
}
