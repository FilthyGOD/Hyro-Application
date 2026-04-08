import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A breathing animated background that displays blurred color blobs
/// using the Focus Aura Lucid palette.
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
    // A slow, calming breathing cycle (e.g., 6 seconds per breath cycle)
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
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Primary color (Electric Blue) blob
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 + (_controller.value * 0.2); // 1.0 to 1.2
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

          // Secondary color (Vibrant Violet) blob
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

          // Tertiary color (Soft Neon Purple) blob
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

          // Heavy glassmorphism blur applied over all blobs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
