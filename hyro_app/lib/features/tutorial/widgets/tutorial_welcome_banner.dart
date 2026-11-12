import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/tutorial_service.dart';

/// Banner visual para invitar a los nuevos usuarios a ver el tutorial guiado de Hyro.
class TutorialWelcomeBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const TutorialWelcomeBanner({super.key, this.onDismiss});

  @override
  State<TutorialWelcomeBanner> createState() => _TutorialWelcomeBannerState();
}

class _TutorialWelcomeBannerState extends State<TutorialWelcomeBanner> {
  bool _isVisible = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final seen = await TutorialService.instance.hasSeenTutorial();
    if (!seen && mounted) {
      setState(() => _isVisible = true);
    }
  }

  Future<void> _handleDismiss() async {
    await TutorialService.instance.markTutorialSeen();
    if (mounted) {
      setState(() => _dismissed = true);
    }
    widget.onDismiss?.call();
  }

  Future<void> _handleOpenTutorial() async {
    await TutorialService.instance.showTutorial(context);
    if (mounted) {
      setState(() => _dismissed = true);
    }
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.pomodoroRed.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascota saludando en SVG
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/JairitoHD_Saludo.svg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // Textos explicativos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '👋 ¿Nuevo en Hyro?',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '2 MIN',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Aprende a configurar tu pomodoro, crear materias y ganar duelos.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _handleOpenTutorial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ver Tutorial',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _handleDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text(
                        'Luego',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón cerrar
          GestureDetector(
            onTap: _handleDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close_rounded, size: 18, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
