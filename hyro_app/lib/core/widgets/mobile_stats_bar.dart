import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/shop/screens/premium_shop_screen.dart';

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
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Protectores (Shield) ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon: const Text('🛡️', style: TextStyle(fontSize: 26)),
            value: '${profile.protectoresRachaActivos}',
          ),
          const SizedBox(width: 30),

          // ── Racha (Fire) ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon:
                profile.rachaActual > 0
                    ? const Text('🔥', style: TextStyle(fontSize: 26))
                    : Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
            value: '${profile.rachaActual}',
          ),
          const SizedBox(width: 30),

          // ── Monedas (Coin) ──
          _StatChip(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumShopScreen()),
              );
            },
            icon: SvgPicture.asset(
              'assets/images/HyroCoins.svg',
              width: 28,
              height: 28,
            ),
            value: _formatNumber(profile.monedas),
          ),
          const SizedBox(width: 30),

          // ── XP Doble (Potion) ──
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
                icon: const Text('🧪', style: TextStyle(fontSize: 26)),
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
                fontSize: 18,
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
