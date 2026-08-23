import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';

/// Un fondo animado que respira y muestra burbujas de color difuminadas
/// utilizando la paleta de colores de Focus Aura Lucid.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Un ciclo de respiración lento y calmante (por ejemplo, 6 segundos por ciclo de respiración)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF101422), // AppColors.background
              Color(0xFF121F35), // Subtle blue-cyan glow (blend of background and primaryGlow)
              Color(0xFF18132A), // Subtle violet/purple glow (blend of background and pomodoroRed)
              Color(0xFF101422), // AppColors.background
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Burbuja de color primario (Azul Eléctrico)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (_controller.value * 0.2); // de 1.0 a 1.2
                final dx = math.sin(_controller.value * math.pi) * 30;
                final dy = math.cos(_controller.value * math.pi) * 20;

                return Positioned(
                  top: -50 + dy,
                  left: -50 + dx,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGlow,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Burbuja de color secundario (Violeta Vibrante)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + ((1 - _controller.value) * 0.15);
                final dx = math.cos(_controller.value * math.pi) * -40;
                final dy = math.sin(_controller.value * math.pi) * 20;

                return Positioned(
                  bottom: -100 + dy,
                  right: -50 + dx,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pomodoroRed.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Burbuja de color terciario (Púrpura Neón Suave)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.9 + (_controller.value * 0.3);
                final dx = math.sin(_controller.value * math.pi * 2) * 50;

                return Positioned(
                  top: 200,
                  right: 50 + dx,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pomodoroRedLight.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
