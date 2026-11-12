import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/interactive_tutorial_controller.dart';

/// Overlay que oscurece el fondo con un recorte transparente (spotlight)
/// sobre el widget objetivo y muestra un diálogo explicativo con Jairito.
class InteractiveTutorialOverlay extends StatefulWidget {
  final Widget child;

  const InteractiveTutorialOverlay({super.key, required this.child});

  @override
  State<InteractiveTutorialOverlay> createState() => _InteractiveTutorialOverlayState();
}

class _InteractiveTutorialOverlayState extends State<InteractiveTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    InteractiveTutorialController.instance.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    InteractiveTutorialController.instance.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Rect? _getTargetRect(GlobalKey? key) {
    if (key == null) return null;
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final size = renderObject.size;
      final position = renderObject.localToGlobal(Offset.zero);
      return position & size;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = InteractiveTutorialController.instance;

    return Stack(
      children: [
        widget.child,
        if (controller.isActive && controller.currentStep != null)
          _buildOverlay(context, controller, controller.currentStep!),
      ],
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    InteractiveTutorialController controller,
    InteractiveTutorialStep step,
  ) {
    final targetRect = _getTargetRect(step.targetKey);
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Capa oscura con recorte (Spotlight) ──
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Tocar fuera avanza al siguiente paso
                controller.nextStep();
              },
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  overlayColor: Colors.black.withValues(alpha: 0.82),
                  spotlightPadding: 12.0,
                ),
              ),
            ),
          ),

          // ── Anillo brillante / pulso alrededor del elemento resaltado ──
          if (targetRect != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final pad = 12.0 * _pulseAnimation.value;
                final ringRect = Rect.fromLTRB(
                  targetRect.left - pad,
                  targetRect.top - pad,
                  targetRect.right + pad,
                  targetRect.bottom + pad,
                );

                return Positioned(
                  left: ringRect.left,
                  top: ringRect.top,
                  width: ringRect.width,
                  height: ringRect.height,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: step.accentColor.withValues(alpha: 0.85),
                          width: 2.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: step.accentColor.withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Tarjeta explicativa flotante ──
          _buildTooltipCard(context, controller, step, targetRect, screenSize),
        ],
      ),
    );
  }

  Widget _buildTooltipCard(
    BuildContext context,
    InteractiveTutorialController controller,
    InteractiveTutorialStep step,
    Rect? targetRect,
    Size screenSize,
  ) {
    final isTopHalf = targetRect != null && targetRect.center.dy > (screenSize.height / 2);
    final isMobile = screenSize.width < 600;

    double? top;
    double? bottom;

    if (targetRect == null) {
      // Si no hay target específico (ej. bienvenida), centrar en pantalla
      top = (screenSize.height - 380) / 2;
    } else if (isTopHalf) {
      // El elemento está abajo, poner la tarjeta arriba
      bottom = screenSize.height - targetRect.top + 20;
      if (bottom < 80) bottom = 80;
    } else {
      // El elemento está arriba, poner la tarjeta abajo
      top = targetRect.bottom + 20;
      if (top > screenSize.height - 350) top = screenSize.height - 350;
    }

    return Positioned(
      left: isMobile ? 16 : (screenSize.width - 500) / 2,
      right: isMobile ? 16 : null,
      width: isMobile ? null : 500,
      top: top,
      bottom: bottom,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 14),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: step.accentColor.withValues(alpha: 0.5),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: step.accentColor.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior: Indicador de paso y botón omitir
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: step.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.icon, size: 14, color: step.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'Paso ${controller.currentStepIndex + 1} de ${controller.totalSteps}',
                          style: TextStyle(
                            color: step.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.finishTutorial,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Omitir',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Contenido con Jairito a la izquierda
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: step.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: step.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SvgPicture.asset(
                      step.mascotSvg,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: AppTypography.h3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.description,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Prompt de acción
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: step.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.actionPrompt,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botones de navegación
              Row(
                children: [
                  if (controller.currentStepIndex > 0)
                    OutlinedButton(
                      onPressed: controller.previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Anterior', style: TextStyle(fontSize: 12)),
                    )
                  else
                    const SizedBox(width: 60),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: controller.nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentStepIndex == controller.totalSteps - 1
                              ? '¡Entendido! 🚀'
                              : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter que recorta un rectángulo redondeado con spotlight
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;
  final double spotlightPadding;

  const _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
    this.spotlightPadding = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect == null) {
      canvas.drawPath(screenPath, Paint()..color = overlayColor);
      return;
    }

    final paddedRect = Rect.fromLTRB(
      (targetRect!.left - spotlightPadding).clamp(0, size.width),
      (targetRect!.top - spotlightPadding).clamp(0, size.height),
      (targetRect!.right + spotlightPadding).clamp(0, size.width),
      (targetRect!.bottom + spotlightPadding).clamp(0, size.height),
    );

    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(paddedRect, const Radius.circular(18)));

    final combinedPath = Path.combine(PathOperation.difference, screenPath, spotlightPath);

    canvas.drawPath(combinedPath, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.spotlightPadding != spotlightPadding;
  }
}

