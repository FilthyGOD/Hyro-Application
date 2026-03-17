import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/glass_card.dart';
import '../mascot/mascot_controller.dart';

// ── Cosmetic category enum ──
enum _CosmeticCategory { sombrero, cara, cuerpo }

/// Shop screen — mascot preview with cosmetic categories.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Per-category selection (-1 = nothing selected yet)
  final Map<_CosmeticCategory, int> _selectedItem = {
    _CosmeticCategory.sombrero: -1,
    _CosmeticCategory.cara: -1,
    _CosmeticCategory.cuerpo: -1,
  };

  // Per-category owned items ("nada" IDs always owned)
  final Map<_CosmeticCategory, Set<int>> _ownedItems = {
    _CosmeticCategory.sombrero: {100},
    _CosmeticCategory.cara: {200},
    _CosmeticCategory.cuerpo: {300},
  };

  // ── Item catalogs ──
  static const _sombreroItems = [
    _ShopItem(id: 100, name: 'Nada', icon: '❌'),
    _ShopItem(id: 101, name: 'Elegante', icon: '🎩'),
    _ShopItem(id: 102, name: 'Mexicano', icon: '🤠'),
    _ShopItem(id: 103, name: 'Payaso', icon: '🤡'),
  ];

  static const _caraItems = [
    _ShopItem(id: 200, name: 'Nada', icon: '❌'),
    _ShopItem(id: 201, name: 'Monóculo', icon: '🧐'),
    _ShopItem(id: 202, name: 'Bigote', icon: '🥸'),
    _ShopItem(id: 203, name: 'Nariz de payaso', icon: '🔴'),
  ];

  static const _cuerpoItems = [
    _ShopItem(id: 300, name: 'Nada', icon: '❌'),
    _ShopItem(id: 301, name: 'Traje elegante', icon: '🤵'),
    _ShopItem(id: 302, name: 'Zarape', icon: '🇲🇽'),
    _ShopItem(id: 303, name: 'Traje de payaso', icon: '🎪'),
  ];

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

  // ── Helpers to map category → "nada" ID ──
  int _nadaId(_CosmeticCategory cat) {
    switch (cat) {
      case _CosmeticCategory.sombrero:
        return 100;
      case _CosmeticCategory.cara:
        return 200;
      case _CosmeticCategory.cuerpo:
        return 300;
    }
  }

  // ── Actions ──
  void _onSelect(_CosmeticCategory cat, int id) {
    setState(() => _selectedItem[cat] = id);
  }

  void _onBuy(_CosmeticCategory cat, int itemId) {
    final mascot = context.read<MascotController>();
    mascot.triggerCompra(itemId);
    setState(() {
      _ownedItems[cat]!.add(itemId);
    });
  }

  void _onEquip(_CosmeticCategory cat, int itemId) {
    final mascot = context.read<MascotController>();
    switch (cat) {
      case _CosmeticCategory.sombrero:
        mascot.setSombrero(itemId);
        break;
      case _CosmeticCategory.cara:
        mascot.setCara(itemId);
        break;
      case _CosmeticCategory.cuerpo:
        mascot.setCuerpo(itemId);
        break;
    }
    setState(() {
      _selectedItem[cat] = itemId;
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
                  child: RiveWidget(
                    controller: mascot.controller!,
                    fit: Fit.contain,
                  ),
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
                    Tab(text: '😎 Cara'),
                    Tab(text: '👕 Cuerpo'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTab(
                        _CosmeticCategory.sombrero,
                        _sombreroItems,
                      ),
                      _buildCategoryTab(_CosmeticCategory.cara, _caraItems),
                      _buildCategoryTab(_CosmeticCategory.cuerpo, _cuerpoItems),
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

  // ── Generic Category Tab ──
  Widget _buildCategoryTab(_CosmeticCategory category, List<_ShopItem> items) {
    final selected = _selectedItem[category]!;
    final owned = _ownedItems[category]!;
    final nadaId = _nadaId(category);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children:
                  items.map((item) {
                    final isSelected = selected == item.id;
                    final isOwned = owned.contains(item.id);

                    return GestureDetector(
                      onTap: () => _onSelect(category, item.id),
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
                              item.icon,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isOwned && item.id != nadaId) ...[
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
        if (selected >= 0)
          _buildActionButton(category, selected, owned, nadaId),
      ],
    );
  }

  Widget _buildActionButton(
    _CosmeticCategory category,
    int selected,
    Set<int> owned,
    int nadaId,
  ) {
    final isOwned = owned.contains(selected);

    if (selected == nadaId) {
      // "Nada" — just equip (remove cosmetic)
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.primary,
        onTap: () => _onEquip(category, nadaId),
      );
    }

    if (isOwned) {
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.primary,
        onTap: () => _onEquip(category, selected),
      );
    }

    return _ShopButton(
      label: 'Comprar',
      icon: Icons.shopping_cart,
      color: AppColors.breakGreen,
      onTap: () => _onBuy(category, selected),
    );
  }
}

// ── Generic shop item model ──
class _ShopItem {
  final int id;
  final String name;
  final String icon;
  const _ShopItem({required this.id, required this.name, required this.icon});
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
