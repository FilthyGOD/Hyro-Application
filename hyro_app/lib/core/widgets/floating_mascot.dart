import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Animation;
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../../features/mascot/mascot_controller.dart';

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

    // Volver a verificar la posición si el tamaño de la pantalla cambió
    if (_posX != null && _posY != null) {
       _clampPosition(screenSize, bubbleSize);
    } else {
       _initPositionIfNeeded(screenSize, bubbleSize);
    }

    // Cuando se oculta, desliza hacia el borde derecho
    final targetX = widget.visible ? _posX! : screenSize.width + 20;
    final targetY = _posY!;

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
              child: Container(
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
                    child: Consumer<MascotController>(
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
                          // 1. Usa Transform.scale para hacer un "zoom" manual y eliminar bordes
                          child: Transform.scale(
                            scale:
                                1.6, // Súbelo a 1.8 o 2.0 si sigue sobrando espacio
                            // 2. Usa Transform.translate para centrarlo (si quedó muy arriba o abajo)
                            child: Transform.translate(
                              offset: const Offset(
                                0,
                                -10,
                              ), // Ajusta los píxeles en X y Y a tu gusto
                              child: RiveWidget(
                                controller: mascot.controller!,
                                // Cambia a Fit.cover si quieres que llene todo el espacio ignorando la relación de aspecto
                                fit: Fit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
