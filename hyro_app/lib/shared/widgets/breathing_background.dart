import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A calming animated background with subtle breathing (pulsing) gradients.
class BreathingBackground extends StatefulWidget {
  const BreathingBackground({super.key});

  @override
  State<BreathingBackground> createState() => _BreathingBackgroundState();
}

class _BreathingBackgroundState extends State<BreathingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 6 seconds duration for a full inhale/exhale cycle creates a calming pace (4-10 breaths per min)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.1, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Repeat the animation back and forth forever
    _controller.repeat(reverse: true);
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Top-left soft glow
              Positioned(
                top: -150,
                left: -150,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: _buildGlowOrb(size: 400, color: AppColors.primary),
                  ),
                ),
              ),
              // Bottom-right soft glow (with slight phase inverse by using inverted values manually if we wanted, or just same pulse)
              Positioned(
                bottom: -200,
                right: -100,
                child: Transform.scale(
                  scale: 2.1 - _scaleAnimation.value, // opposite scale pulse
                  child: Opacity(
                    opacity:
                        0.35 -
                        _opacityAnimation.value, // opposite opacity pulse
                    child: _buildGlowOrb(
                      size: 500,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              // Center-bottom faint glow
              Positioned(
                bottom: 0,
                left: MediaQuery.of(context).size.width / 4,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value * 0.5,
                    child: _buildGlowOrb(
                      size: 600,
                      color: AppColors.primaryGlow,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlowOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
