import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/glass_card.dart';
import '../mascot/mascot_controller.dart';

/// Shop screen — mascot preview with cosmetic categories.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedHat = -1; // -1 = nothing selected yet
  final Set<int> _ownedHats = {0}; // 0 (none) is always owned

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSelectHat(int hatId) {
    setState(() => _selectedHat = hatId);
  }

  void _onBuyHat(int hatId) {
    final mascot = context.read<MascotController>();
    mascot.triggerCompra(hatId);
    setState(() {
      _ownedHats.add(hatId);
    });
  }

  void _onEquipHat(int hatId) {
    final mascot = context.read<MascotController>();
    mascot.setSombrero(hatId);
    setState(() {
      _selectedHat = hatId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: isDesktop ? 32 : 64,
        left: isDesktop ? 72 : 20,
        right: isDesktop ? 32 : 20,
        bottom: 32,
      ),
      child: Column(
        children: [
          // Header
          Text('Tienda', style: AppTypography.h1),
          const SizedBox(height: 4),
          Text('Personaliza a tu mascota', style: AppTypography.bodyMedium),
          const SizedBox(height: 24),

          // ── Mascot Preview ──
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Consumer<MascotController>(
              builder: (context, mascot, _) {
                final previewSize = isDesktop ? 380.0 : 260.0;
                if (!mascot.isLoaded) {
                  return SizedBox(
                    width: previewSize,
                    height: previewSize,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  width: previewSize,
                  height: previewSize,
                  child: Rive(artboard: mascot.artboard!, fit: BoxFit.contain),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Tabs ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.labelLarge,
                  unselectedLabelStyle: AppTypography.bodyMedium,
                  dividerColor: AppColors.cardBorder,
                  tabs: const [
                    Tab(text: '🎩 Sombreros'),
                    Tab(text: '👓 Lentes'),
                    Tab(text: '👕 Vestuario'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHatsTab(),
                      _buildComingSoonTab(),
                      _buildComingSoonTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80), // bottom padding for nav
        ],
      ),
    );
  }

  // ── Hats Tab ──
  Widget _buildHatsTab() {
    final hatItems = [
      _HatItem(id: 0, name: 'Sin sombrero', icon: '❌'),
      _HatItem(id: 1, name: 'Gorra', icon: '🧢'),
      _HatItem(id: 2, name: 'Sombrero mago', icon: '🎩'),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children:
                  hatItems.map((hat) {
                    final isSelected = _selectedHat == hat.id;
                    final isOwned = _ownedHats.contains(hat.id);

                    return GestureDetector(
                      onTap: () => _onSelectHat(hat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withAlpha(30)
                                  : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hat.icon,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hat.name,
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isOwned && hat.id != 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Comprado',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.breakGreen,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Action button
        if (_selectedHat >= 0) _buildActionButton(),
      ],
    );
  }

  Widget _buildActionButton() {
    final isOwned = _ownedHats.contains(_selectedHat);

    if (_selectedHat == 0) {
      // "Sin sombrero" — just equip (remove hat)
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.primary,
        onTap: () => _onEquipHat(0),
      );
    }

    if (isOwned) {
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.primary,
        onTap: () => _onEquipHat(_selectedHat),
      );
    }

    return _ShopButton(
      label: 'Comprar',
      icon: Icons.shopping_cart,
      color: AppColors.breakGreen,
      onTap: () => _onBuyHat(_selectedHat),
    );
  }

  // ── Coming Soon Tab ──
  Widget _buildComingSoonTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text('Tienda', style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(
            '¡Próximamente!',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Desbloquea temas, mascotas y más.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: null,
            child: Text(
              'Notifícame',
              style: AppTypography.chip.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hat data model ──
class _HatItem {
  final int id;
  final String name;
  final String icon;
  const _HatItem({required this.id, required this.name, required this.icon});
}

// ── Shop Action Button ──
class _ShopButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShopButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.glowShadow(color, blur: 20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
