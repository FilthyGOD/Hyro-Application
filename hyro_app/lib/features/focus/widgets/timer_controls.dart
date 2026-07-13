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
          icon: Icons.stop_rounded,
          label: 'Detener',
          onTap: () {
             _confirmAction(context, 'Detener', '¿Deseas detener y salir de la sesión actual?', onStop);
          },
          isSecondary: true,
        ),
        SizedBox(width: 16 * buttonSizeMultiplier),
        // Pausar / Reanudar
        if (isRunning)
          _ControlButton(
            icon: Icons.pause_rounded,
            label: 'Pausar',
            onTap: onPause,
            isSecondary: false,
          )
        else if (isPaused)
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: 'Reanudar',
            onTap: onResume,
            isSecondary: false,
          ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
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
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSecondary 
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF2A2E3D),
                        Color(0xFF1E212D),
                      ],
                    )
                  : const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 0, 149, 255),
                        Color.fromARGB(255, 32, 43, 200),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: widget.isSecondary ? Border.all(color: AppColors.cardBorder) : null,
              boxShadow: widget.isSecondary 
                  ? null 
                  : [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSecondary ? AppColors.textSecondary : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSecondary ? AppColors.textSecondary : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
