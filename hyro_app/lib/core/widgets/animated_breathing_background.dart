import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedBreathingBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBreathingBackground({super.key, required this.child});

  @override
  State<AnimatedBreathingBackground> createState() =>
      _AnimatedBreathingBackgroundState();
}

class _AnimatedBreathingBackgroundState
    extends State<AnimatedBreathingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 4 seconds to inhale, 4 seconds to exhale = 8s cycle, typical for calm breathing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background
        Container(color: AppColors.background),
        // Breathing Glow
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Calculate an opacity that breathes between 0.05 and 0.15 for subtlety
              final glowOpacity = 0.05 + (_animation.value * 0.1);
              final scale =
                  1.0 + (_animation.value * 0.15); // gentle scale pulse

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.3),
                      radius: 1.2,
                      colors: [
                        const Color(0xFFffb6b0).withOpacity(glowOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Foreground Content
        widget.child,
      ],
    );
  }
}
