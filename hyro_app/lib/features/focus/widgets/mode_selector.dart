import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/timer_state.dart';

/// Chips to switch between Pomodoro, Short Break, Long Break.
class ModeSelector extends StatelessWidget {
  final TimerMode currentMode;
  final ValueChanged<TimerMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeChip(
          label: 'Pomodoro',
          isActive: currentMode == TimerMode.pomodoro,
          activeColor: AppColors.primary,
          onTap: () => onModeChanged(TimerMode.pomodoro),
        ),
        const SizedBox(width: 10),
        _ModeChip(
          label: 'Short Break',
          isActive: currentMode == TimerMode.shortBreak,
          activeColor: AppColors.primary,
          onTap: () => onModeChanged(TimerMode.shortBreak),
        ),
        const SizedBox(width: 10),
        _ModeChip(
          label: 'Long Break',
          isActive: currentMode == TimerMode.longBreak,
          activeColor: AppColors.primary,
          onTap: () => onModeChanged(TimerMode.longBreak),
        ),
      ],
    );
  }
}

class _ModeChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_ModeChip> createState() => _ModeChipState();
}

class _ModeChipState extends State<_ModeChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? widget.activeColor
                    : _hovering
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  widget.isActive ? widget.activeColor : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTypography.chip.copyWith(
              color: widget.isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
