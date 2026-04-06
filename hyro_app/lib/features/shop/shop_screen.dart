import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/glass_card.dart';
import '../mascot/mascot_controller.dart';
import '../../providers/shop_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import 'models/shop_item.dart';

// ── Cosmetic category enum ──
enum _CosmeticCategory { sombrero, cara, cuerpo }

/// Shop screen — mascot preview with cosmetic categories backed by Supabase.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Per-category selection
  final Map<_CosmeticCategory, int> _selectedItem = {
    _CosmeticCategory.sombrero: -1,
    _CosmeticCategory.cara: -1,
    _CosmeticCategory.cuerpo: -1,
  };

  int _currentTabIndex = 0;
  bool _isPurchasing = false;

  // "Nada" items (always owned, id X00 per category)
  static const _nadaItems = {
    _CosmeticCategory.sombrero: ShopItem(
      id: 100,
      nombre: 'Nada',
      categoria: 'Sombrero',
      precio: 0,
    ),
    _CosmeticCategory.cara: ShopItem(
      id: 200,
      nombre: 'Nada',
      categoria: 'Cara',
      precio: 0,
    ),
    _CosmeticCategory.cuerpo: ShopItem(
      id: 300,
      nombre: 'Nada',
      categoria: 'Traje',
      precio: 0,
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initialize with actually equipped items
    final mascot = context.read<MascotController>();
    _selectedItem[_CosmeticCategory.sombrero] = mascot.equippedSombrero;
    _selectedItem[_CosmeticCategory.cara] = mascot.equippedCara;
    _selectedItem[_CosmeticCategory.cuerpo] = mascot.equippedCuerpo;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──
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

  String _categoryFilter(_CosmeticCategory cat) {
    switch (cat) {
      case _CosmeticCategory.sombrero:
        return 'sombr';
      case _CosmeticCategory.cara:
        return 'cara';
      case _CosmeticCategory.cuerpo:
        return 'traje';
    }
  }

  List<ShopItem> _itemsForCategory(ShopProvider shop, _CosmeticCategory cat) {
    final nada = _nadaItems[cat]!;
    final fromDb = shop.itemsByCategory(_categoryFilter(cat));
    return [nada, ...fromDb];
  }

  void _handleTabSelection() {
    if (_tabController.index != _currentTabIndex) {
      _currentTabIndex = _tabController.index;

      final mascot = context.read<MascotController>();
      mascot.restoreEquippedState();

      final currentCategory = _CosmeticCategory.values[_currentTabIndex];
      final selectedId = _selectedItem[currentCategory];

      if (selectedId != null && selectedId >= 0) {
        if (currentCategory == _CosmeticCategory.sombrero) {
          mascot.previewSombrero(selectedId);
        } else if (currentCategory == _CosmeticCategory.cara) {
          mascot.previewCara(selectedId);
        } else if (currentCategory == _CosmeticCategory.cuerpo) {
          mascot.previewCuerpo(selectedId);
        }
      }
    }
  }

  // ── Actions ──
  void _onSelect(_CosmeticCategory cat, int id) {
    setState(() => _selectedItem[cat] = id);

    final mascot = context.read<MascotController>();
    mascot.restoreEquippedState();

    if (cat == _CosmeticCategory.sombrero) {
      mascot.previewSombrero(id);
    } else if (cat == _CosmeticCategory.cara) {
      mascot.previewCara(id);
    } else if (cat == _CosmeticCategory.cuerpo) {
      mascot.previewCuerpo(id);
    }
  }

  Future<void> _onBuy(_CosmeticCategory cat, int itemId) async {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final profile = context.read<ProfileProvider>();
    final userId = auth.supabaseUserId;

    setState(() => _isPurchasing = true);

    final success = await shop.purchaseItem(userId, itemId);

    if (success && mounted) {
      // Refresh profile to get updated coin count
      await profile.loadProfile(userId);
      if (!mounted) return;

      final mascot = context.read<MascotController>();
      mascot.triggerCompra(itemId);
    } else if (!success && mounted) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shop.error ?? 'Error al comprar'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    if (mounted) setState(() => _isPurchasing = false);
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
    final profile = context.watch<ProfileProvider>();
    final shop = context.watch<ShopProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: isDesktop ? 32 : 64,
        left: isDesktop ? 72 : 20,
        right: isDesktop ? 32 : 20,
        bottom: 32,
      ),
      child: Column(
        children: [
          // Header with coin count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tienda', style: AppTypography.h1),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.monedas}',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

          // ── Loading / Content ──
          if (shop.isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
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
                        _buildCategoryTab(shop, _CosmeticCategory.sombrero),
                        _buildCategoryTab(shop, _CosmeticCategory.cara),
                        _buildCategoryTab(shop, _CosmeticCategory.cuerpo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Generic Category Tab ──
  Widget _buildCategoryTab(ShopProvider shop, _CosmeticCategory category) {
    final items = _itemsForCategory(shop, category);
    final selected = _selectedItem[category]!;
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
                    final isOwned = shop.ownsItem(item.id) || item.id == nadaId;

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
                              item.id == nadaId ? '❌' : item.icon,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.nombre,
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
                            if (!isOwned) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.precio}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
        if (selected >= 0) _buildActionButton(shop, category, selected, nadaId),
      ],
    );
  }

  Widget _buildActionButton(
    ShopProvider shop,
    _CosmeticCategory category,
    int selected,
    int nadaId,
  ) {
    final isOwned = shop.ownsItem(selected) || selected == nadaId;

    if (selected == nadaId) {
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.timerColor,
        onTap: () => _onEquip(category, nadaId),
      );
    }

    if (isOwned) {
      return _ShopButton(
        label: 'Equipar',
        icon: Icons.checkroom,
        color: AppColors.timerColor,
        onTap: () => _onEquip(category, selected),
      );
    }

    // Not owned — show price and buy button
    final items = _itemsForCategory(shop, category);
    final itemIdx = items.indexWhere((i) => i.id == selected);
    
    // If the selected/equipped item is not in the current catalog (e.g. from old prefs), hide button.
    if (itemIdx == -1) return const SizedBox.shrink();
    
    final item = items[itemIdx];
    return _ShopButton(
      label: _isPurchasing ? 'Comprando...' : 'Comprar · ${item.precio} 🪙',
      icon: Icons.shopping_cart,
      color: AppColors.timerColor,
      onTap: _isPurchasing ? () {} : () => _onBuy(category, selected),
    );
  }
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
