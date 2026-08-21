import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../mascot/mascot_controller.dart';
import '../providers/shop_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../friends/services/friends_service.dart';
import '../models/shop_item.dart';
import '../../../core/widgets/animated_background.dart';

class PremiumShopScreen extends StatefulWidget {
  const PremiumShopScreen({super.key});

  @override
  State<PremiumShopScreen> createState() => _PremiumShopScreenState();
}

class _PremiumShopScreenState extends State<PremiumShopScreen> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101422), // Matching the dark theme
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSuperCard(),
              const SizedBox(height: 32),
              _buildSectionTitle('Ofertas especiales'),
              _buildStoreCard(
                child: Column(
                  children: [
                    _buildListItem(
                      iconColor: const Color(0xFFCC88FF),
                      icon: Icons.widgets_rounded,
                      title: 'Recompensa de widget',
                      subtitle:
                          'Agrega el widget de Hyro a tu pantalla de inicio y recibe un Multiplicador de EXP.',
                      actionText: 'AGRÉGALO AHORA',
                      onAction: () {},
                    ),
                    _buildDivider(),
                    _buildListItem(
                      iconColor: const Color(0xFFFFB020),
                      icon: Icons.ondemand_video_rounded,
                      title: 'Cofre gratis',
                      subtitle: 'Ve un anuncio y gana hasta 15 gemas',
                      actionText: '▶ OBTENER',
                      onAction: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Días de racha'),
              _buildStoreCard(
                child: Consumer<ShopProvider>(
                  builder: (context, shop, child) {
                    final quantity = shop.ownedQuantities[401] ?? 0;
                    // Try to get item from catalog for real price, fallback to 10
                    final item =
                        shop.catalog.where((i) => i.id == 401).firstOrNull;
                    final price = item?.precio ?? 10;

                    return _buildListItem(
                      iconColor: const Color(0xFF3CDCF8),
                      customIcon: const Text(
                        '🛡️',
                        style: TextStyle(fontSize: 32),
                      ),
                      title: item?.nombre ?? 'Protector de racha',
                      subtitle:
                          'Protege tu racha si no practicas por un día. Equipa hasta 2 a la vez.',
                      isEquipped: quantity > 0,
                      equippedText: '$quantity / 2 EQUIPADO',
                      price: price,
                      onAction: () => _showObjectActionSheet(401),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Monedas'),
              _buildGemsSection(),
              const SizedBox(height: 32),
              _buildConsumiblesSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Energía'),
              _buildStoreCard(
                child: Column(
                  children: [
                    _buildListItem(
                      iconColor: const Color(0xFF3CDCF8),
                      icon: Icons.all_inclusive_rounded,
                      title: 'Ilimitada',
                      subtitle: '¡Con Súper, ya no te quedarás sin energía!',
                      actionText: 'PRUÉBALO GRATIS',
                      actionColor: const Color(0xFFCC88FF),
                      onAction: () {},
                    ),
                    _buildDivider(),
                    _buildListItem(
                      iconColor: const Color(0xFFFF5280),
                      icon: Icons.flash_on_rounded,
                      title: 'Recarga',
                      subtitle:
                          'Recarga tu energía al máximo para superar más lecciones',
                      actionText: 'COMPLETAS',
                      actionColor: Colors.white38,
                      onAction: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Código promocional'),
              _buildStoreCard(
                child: _buildListItem(
                  iconColor: const Color(0xFFFF5280),
                  icon: Icons.local_activity_rounded,
                  title: 'Ingresa un código promocional',
                  subtitle: 'Ingresa un código y recibe recompensas',
                  actionText: 'CANJEAR',
                  onAction: () {},
                ),
              ),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white54, size: 28),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Tienda',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.monedas}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.white.withValues(alpha: 0.1),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSuperCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Gradient Heart with Infinity ──
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // White border
                      const Icon(
                        Icons.favorite_rounded,
                        size: 104,
                        color: Colors.white,
                      ),
                      // Gradient fill
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF88D3FF),
                                Color(0xFFFFB2E6),
                                Color(0xFFFFD18C),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 96,
                          color: Colors.white,
                        ),
                      ),
                      // Infinity icon
                      const Icon(
                        Icons.all_inclusive_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Gradient Title ──
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      children: [
                        const TextSpan(text: 'Pase '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: ShaderMask(
                            shaderCallback:
                                (bounds) => const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 255, 140, 222),
                                    Color.fromARGB(255, 22, 103, 135),
                                  ],
                                ).createShader(bounds),
                            child: const Text(
                              'Fundador',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: '\ncon Hyro'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Subtitle ──
                  const Text(
                    'Únete a los primeros en dominar su tiempo. Desbloquea recompensas exclusivas y congela este precio de por vida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Subscription Button with Gradient Border ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(3), // gradient border width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF88D3FF),
                          Color.fromARGB(255, 220, 178, 255),
                          Color.fromARGB(255, 255, 140, 222),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF101422,
                          ), // Inner background color
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mensual',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$49.00 / MES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStoreCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141A2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.1),
      height: 1,
      thickness: 1.5,
    );
  }

  Widget _buildListItem({
    required Color iconColor,
    IconData? icon,
    Widget? customIcon,
    required String title,
    required String subtitle,
    String? actionText,
    Color? actionColor,
    bool isEquipped = false,
    String? equippedText,
    int? price,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child:
                  customIcon ??
                  (icon != null
                      ? Icon(icon, color: iconColor, size: 36)
                      : const SizedBox()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (isEquipped) ...[
                  Text(
                    equippedText ?? '',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (price != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$price',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                if (actionText != null) ...[
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionText,
                      style: TextStyle(
                        color: actionColor ?? Colors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGemCard(1200, '\$119.00'),
        const SizedBox(width: 12),
        _buildGemCard(3000, '\$235.00'),
        const SizedBox(width: 12),
        _buildGemCard(6500, '\$469.00'),
      ],
    );
  }

  Widget _buildGemCard(int amount, String price) {
    return Expanded(
      child: _buildStoreCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const Icon(
                Icons.monetization_on, // Simulating a chest of gems
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$amount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsumiblesSection() {
    final shop = context.watch<ShopProvider>();
    // Exclude item 401 (Protector de racha) because it's now at the top
    final items =
        shop.itemsByCategory('Objeto').where((item) => item.id != 401).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink(); // No items found
    }

    return _buildStoreCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children:
                  items.map((item) {
                    final quantityOwned = shop.ownedQuantities[item.id] ?? 0;

                    // Determinamos el color/tamaño de la fuente dependiendo de si es emoji o texto especial
                    // (Para mantener el estilo de fuente grande de emojis que diseñamos antes)
                    Widget iconWidget;
                    if (item.icon.contains('?')) {
                      iconWidget = Text(
                        item.icon,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    } else {
                      iconWidget = Text(
                        item.icon,
                        style: const TextStyle(fontSize: 36),
                      );
                    }

                    return _buildConsumibleCard(
                      iconWidget: iconWidget,
                      title: item.nombre,
                      price: item.precio,
                      quantityOwned: quantityOwned,
                      onTap: () => _showObjectActionSheet(item.id),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumibleCard({
    required Widget iconWidget,
    required String title,
    required int price,
    int quantityOwned = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1B233D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 48, child: Center(child: iconWidget)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (quantityOwned > 0) ...[
              Text(
                'Posees: $quantityOwned',
                style: const TextStyle(
                  color: AppColors.timerColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
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
                Text(item.icon, style: const TextStyle(fontSize: 48)),
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
                    _onBuy(itemId);
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

            final friends =
                snapshot.data!
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
                    child: Text('Regalar a...', style: AppTypography.h3),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final friendId = friend['usuario_id'] as String;
                        final friendName =
                            friend['nombre_usuario'] as String? ?? 'Usuario';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            friendName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
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
                            child: const Text(
                              'Enviar',
                              style: TextStyle(color: Colors.white),
                            ),
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

  void _confirmAndSendGift(
    String friendId,
    String friendName,
    ShopItem item,
  ) async {
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
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
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

  Future<void> _onBuy(int itemId) async {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final profile = context.read<ProfileProvider>();
    final userId = auth.supabaseUserId;

    if (userId == null) return;

    setState(() => _isPurchasing = true);

    final success = await shop.purchaseItem(userId, itemId);

    if (success && mounted) {
      await profile.loadProfile(userId);
      if (!mounted) return;

      final mascot = context.read<MascotController>();
      mascot.triggerCompra(itemId);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shop.error ?? 'Error al comprar'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    if (mounted) setState(() => _isPurchasing = false);
  }
}
