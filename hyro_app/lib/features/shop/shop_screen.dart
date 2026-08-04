import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/glass_card.dart';
import '../mascot/mascot_controller.dart';
import 'providers/shop_provider.dart';
import '../profile/providers/profile_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../friends/services/friends_service.dart';
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
        top: isDesktop ? 32 : (MediaQuery.of(context).padding.top + 72),
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
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.timerColor,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTypography.labelLarge,
                    unselectedLabelStyle: AppTypography.bodyMedium,
                    dividerColor: AppColors.cardBorder,
                    tabs: const [
                      Tab(text: 'Sombreros'),
                      Tab(text: 'Cara'),
                      Tab(text: 'Cuerpo'),
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
          const SizedBox(height: 24),
          if (!shop.isLoading)
            _buildConsumiblesSection(shop),
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
                        height: 135, // Forzar misma altura siempre
                        padding: const EdgeInsets.symmetric(
                          vertical: 12, // Reduce un poco el padding vertical para acomodar la altura fija
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.timerColor.withAlpha(30)
                                  : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.timerColor
                                    : AppColors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            item.imageAsset != null
                                ? Image.asset(
                                    item.imageAsset!,
                                    height: 48,
                                    fit: BoxFit.contain,
                                  )
                                : Text(
                                    item.id == nadaId ? '❌' : item.icon,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                item.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color:
                                      isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (isOwned && item.id != nadaId) ...[
                              Text(
                                'Comprado',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.breakGreen,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            if (!isOwned) ...[
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

  Widget _buildActionSheetButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showObjectActionSheet(int itemId) {
    final shop = context.read<ShopProvider>();
    final item = shop.catalog.firstWhere((i) => i.id == itemId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1528),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  item.nombre,
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Precio: ${item.precio} 🪙',
                  style: AppTypography.labelLarge.copyWith(color: Colors.amber),
                ),
                const SizedBox(height: 24),
                _buildActionSheetButton(
                  label: 'Comprar para mí',
                  icon: Icons.shopping_bag_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _onBuy(_CosmeticCategory.sombrero, itemId);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionSheetButton(
                  label: 'Regalar a un amigo',
                  icon: Icons.card_giftcard_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showFriendsGiftSelectionList(item);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFriendsGiftSelectionList(ShopItem item) {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.supabaseUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para enviar regalos.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1528),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: FriendsService().getFriendsRanking(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'Error cargando amigos',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              );
            }

            final friends = snapshot.data!
                .where((f) => f['usuario_id'] != currentUserId)
                .toList();

            if (friends.isEmpty) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No tienes amigos agregados aún para enviar regalos.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Text(
                      'Regalar a...',
                      style: AppTypography.h3,
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final friendId = friend['usuario_id'] as String;
                        final friendName = friend['nombre_usuario'] as String? ?? 'Usuario';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          title: Text(
                            friendName,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _confirmAndSendGift(friendId, friendName, item);
                            },
                            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAndSendGift(String friendId, String friendName, ShopItem item) async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final currentUserId = auth.supabaseUserId;
    if (currentUserId == null) return;

    if (profile.monedas < item.precio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No tienes suficientes monedas'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      await FriendsService().sendGift(
        senderId: currentUserId,
        recipientId: friendId,
        itemId: item.id,
        price: item.precio,
      );

      if (mounted) Navigator.of(context).pop();

      await profile.loadProfile(currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Regalo enviado con éxito a $friendName!'),
            backgroundColor: AppColors.breakGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar regalo: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget _buildConsumiblesSection(ShopProvider shop) {
    final items = shop.itemsByCategory('Objeto');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consumibles',
            style: AppTypography.h2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: items.map((item) {
              final quantityOwned = shop.ownedQuantities[item.id] ?? 0;

              return GestureDetector(
                onTap: () => _showObjectActionSheet(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 105,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.cardBorder.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.nombre,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Mostrar cantidad de cada cosa que ya se posee
                      if (quantityOwned > 0) ...[
                        Text(
                          'Posees: $quantityOwned',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.timerColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                      ],

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
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 149, 255),
                Color.fromARGB(255, 32, 43, 200),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
