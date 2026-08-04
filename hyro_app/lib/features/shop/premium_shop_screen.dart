import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile/providers/profile_provider.dart';

class PremiumShopScreen extends StatelessWidget {
  const PremiumShopScreen({super.key});

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
                      subtitle: 'Agrega el widget de Hyro a tu pantalla de inicio y recibe un Multiplicador de EXP.',
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
                child: _buildListItem(
                  iconColor: const Color(0xFF3CDCF8),
                  icon: Icons.ac_unit_rounded, // Snowflake for freeze
                  title: 'Protector de racha',
                  subtitle: 'Protege tu racha si no practicas por un día. Equipa hasta 2 a la vez.',
                  isEquipped: true,
                  equippedText: '1 / 2 EQUIPADO',
                  price: 200,
                  onAction: () {},
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Gemas'),
              _buildGemsSection(),
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
                      subtitle: 'Recarga tu energía al máximo para superar más lecciones',
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
                  const Icon(Icons.monetization_on, color: Colors.cyan, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '${profile.monedas}',
                    style: const TextStyle(
                      color: Colors.cyan,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF281461), Color(0xFF5A2EBA), Color(0xFF1E5CCB)],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'SUPER',
              style: TextStyle(
                color: Color(0xFF5A2EBA),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Funcionalida-\ndes para\nacelerar tu\naprendizaje',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Obtén energía ilimitada y dile\nadiós a los anuncios',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'PRUEBA 1 SEMANA GRATIS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
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
    required IconData icon,
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
            child: Icon(icon, color: iconColor, size: 36),
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
                      const Icon(Icons.monetization_on, color: Colors.cyan, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$price',
                        style: const TextStyle(
                          color: Colors.cyan,
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
                Icons.diamond_rounded, // Simulating a chest of gems
                color: Colors.cyan,
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
                  color: Colors.cyan,
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
}
