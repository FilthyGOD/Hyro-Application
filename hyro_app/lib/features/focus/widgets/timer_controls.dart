import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Controles de Iniciar / Pausar / Reiniciar / Detener para el temporizador.
class TimerControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onStop;
  final double buttonSizeMultiplier;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onStop,
    this.buttonSizeMultiplier = 1.0,
  });

  void _confirmAction(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.timerColor),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isRunning && !isPaused) {
       return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Detener
        _ControlButton(
          icon: Icons.stop,
          size: 60 * buttonSizeMultiplier,
          onTap: () {
             _confirmAction(context, 'Detener', '¿Deseas detener y salir de la sesión actual?', onStop);
          },
          backgroundColor: AppColors.surfaceLight,
        ),
        SizedBox(width: 32 * buttonSizeMultiplier),
        // Pausar / Reanudar
        if (isRunning)
          _ControlButton(
            icon: Icons.pause,
            size: 60 * buttonSizeMultiplier,
            onTap: onPause,
            backgroundColor: AppColors.timerColor,
            iconColor: Colors.white,
            elevation: true,
          )
        else if (isPaused)
          _ControlButton(
            icon: Icons.play_arrow,
            size: 60 * buttonSizeMultiplier,
            onTap: onResume,
            backgroundColor: AppColors.timerColor,
            iconColor: Colors.white,
            elevation: true,
          ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color? iconColor;
  final bool elevation;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.backgroundColor,
    this.iconColor,
    this.elevation = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
            boxShadow:
                widget.elevation
                    ? AppColors.glowShadow(AppColors.timerColor, blur: 24)
                    : null,
            border: Border.all(
              color: AppColors.cardBorder,
              width: widget.elevation ? 0 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? AppColors.textSecondary,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );
  }
}
