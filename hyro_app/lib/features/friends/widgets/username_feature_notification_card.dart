import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/notification_prefs_service.dart';

/// Tarjeta de notificacion de novedad para la Pestana de Amigos.
/// Informa sobre la nueva funcionalidad de cambio de nombre de usuario.
/// Se descarta con SharedPreferences y no vuelve a aparecer.
class UsernameFeatureNotificationCard extends StatefulWidget {
  const UsernameFeatureNotificationCard({super.key});

  @override
  State<UsernameFeatureNotificationCard> createState() =>
      _UsernameFeatureNotificationCardState();
}

class _UsernameFeatureNotificationCardState
    extends State<UsernameFeatureNotificationCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _isDismissed = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _sizeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _sizeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _checkVisibility();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkVisibility() async {
    final dismissed = await NotificationPrefsService.isUsernameFeatureCardDismissed();
    if (!mounted) return;
    if (!dismissed) {
      setState(() => _isVisible = true);
      _animController.forward();
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (!mounted) return;
    await NotificationPrefsService.dismissUsernameFeatureCard();
    setState(() {
      _isDismissed = true;
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || !_isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SizeTransition(
        sizeFactor: _sizeAnim,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0095FF).withAlpha(25),
                const Color(0xFF6A25F4).withAlpha(20),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de novedad
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NOVEDAD',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ya puedes personalizar tu nombre de usuario.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ve a la pestana de tu Perfil para cambiarlo.',
                      style: AppTypography.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Boton cerrar
              GestureDetector(
                onTap: _dismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withAlpha(100),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
