import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Animation;
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../../features/mascot/mascot_controller.dart';
import '../../features/settings/settings_provider.dart';

/// Burbuja de mascota flotante y arrastrable que sigue al usuario en todas las pantallas.
/// Se oculta cuando [visible] es falso (por ejemplo, en la pantalla de la Tienda).
class FloatingMascot extends StatefulWidget {
  final bool visible;

  const FloatingMascot({super.key, required this.visible});

  @override
  State<FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnimation;

  // Posición de arrastre — nulo hasta el primer diseño, luego se inicializa a la esquina predeterminada
  double? _posX;
  double? _posY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  double _getBubbleSize(bool isMobile) => isMobile ? 120.0 : 150.0;

  void _initPositionIfNeeded(Size screenSize, double bubbleSize) {
    if (_posX == null || _posY == null) {
      // Por defecto: esquina inferior derecha
      _posX = screenSize.width - bubbleSize - 24;
      _posY = screenSize.height - bubbleSize - 100;
    }
  }

  void _clampPosition(Size screenSize, double bubbleSize) {
    _posX = _posX!.clamp(0.0, screenSize.width - bubbleSize);
    _posY = _posY!.clamp(0.0, screenSize.height - bubbleSize);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final bubbleSize = _getBubbleSize(isMobile);
    final screenSize = MediaQuery.sizeOf(context);
    final settings = context.watch<SettingsProvider>();
    final bubbleMode = settings.mascotBubbleMode;

    // Volver a verificar la posición si el tamaño de la pantalla cambió
    if (_posX != null && _posY != null) {
      _clampPosition(screenSize, bubbleSize);
    } else {
      _initPositionIfNeeded(screenSize, bubbleSize);
    }

    // Cuando se oculta, desliza hacia el borde derecho
    final targetX = widget.visible ? _posX! : screenSize.width + 20;
    final targetY = _posY!;

    Widget buildMascotContent({
      double scale = 1.6,
      Offset offset = const Offset(0, -10),
    }) {
      return Consumer<MascotController>(
        builder: (context, mascot, _) {
          if (!widget.visible) {
            return const SizedBox();
          }
          if (!mascot.isLoaded) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: offset,
                child: RiveWidget(
                  controller: mascot.controller!,
                  fit: Fit.contain,
                ),
              ),
            ),
          );
        },
      );
    }

    Widget buildBubbleContainer() {
      switch (bubbleMode) {
        // ── 1. MODO NORMAL (CON BURBUJA AZUL MARINO) ──────────────────────────
        case MascotBubbleMode.normal:
          return Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF182040), Color(0xFF131829)],
              ),
              border: Border.all(
                color: AppColors.primary.withAlpha(_isDragging ? 140 : 80),
                width: _isDragging ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(_isDragging ? 70 : 40),
                  blurRadius: _isDragging ? 32 : 24,
                  spreadRadius: _isDragging ? 4 : 2,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                // ⚙️ PARÁMETROS MODO NORMAL:
                // scale: Zoom de la mascota (1.6)
                // offset: Alineación X, Y (0, -10)
                child: buildMascotContent(
                  scale: 1.6,
                  offset: const Offset(0, -10),
                ),
              ),
            ),
          );

        // ── 2. MODO GLASS (EFECTO CRISTAL TRASLÚCIDO) ─────────────────────────
        case MascotBubbleMode.glass:
          return Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 🔍 Opacidad del fondo cristalino (0.01 = 1% opacidad)
              color: Colors.white.withValues(alpha: _isDragging ? 0.05 : 0.01),
              border: Border.all(
                // 🔍 Opacidad del borde brillante (0.35 = 35% de brillo blanco)
                color: Colors.white.withValues(
                  alpha: _isDragging ? 0.60 : 0.35,
                ),
                width: _isDragging ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF3CDCF8,
                  ).withValues(alpha: _isDragging ? 0.25 : 0.12),
                  blurRadius: _isDragging ? 20 : 14,
                  spreadRadius: _isDragging ? 2 : 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                // 🔍 Desenfoque de cristal (sigmaX: 2, sigmaY: 2)
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                // ⚙️ PARÁMETROS MODO GLASS:
                // scale: Zoom de la mascota (1.6)
                // offset: Alineación X, Y (0, -10)
                child: buildMascotContent(
                  scale: 1.6,
                  offset: const Offset(0, -10),
                ),
              ),
            ),
          );

        // ── 3. MODO SIN BURBUJA (LA PURA MASCOTA MÁS GRANDE) ─────────────────
        case MascotBubbleMode.none:
          return Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow:
                  _isDragging
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFF3CDCF8,
                          ).withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
            // ⚙️ PARÁMETROS MODO SIN BURBUJA:
            // scale: Zoom ampliado a 2.2 para hacer a la mascota más grande
            // offset: Alineación X, Y (0, -6)
            child: buildMascotContent(scale: 2.2, offset: const Offset(0, -6)),
          );
      }
    }

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      left: targetX,
      top: targetY,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.visible ? 1.0 : 0.0,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) {
            setState(() {
              _posX = (_posX! + details.delta.dx).clamp(
                0.0,
                screenSize.width - bubbleSize,
              );
              _posY = (_posY! + details.delta.dy).clamp(
                0.0,
                screenSize.height - bubbleSize,
              );
            });
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          onTap: () {
            final mascot = context.read<MascotController>();
            mascot.triggerSaludo();
          },
          child: AnimatedBuilder(
            animation: _breatheAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset:
                    _isDragging
                        ? Offset.zero
                        : Offset(0, -_breatheAnimation.value),
                child: child,
              );
            },
            child: AnimatedScale(
              scale: _isDragging ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: buildBubbleContainer(),
            ),
          ),
        ),
      ),
    );
  }
}
