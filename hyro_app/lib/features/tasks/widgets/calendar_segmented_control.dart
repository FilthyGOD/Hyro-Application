import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum CalendarViewMode {
  day,
  week,
  month,
}

/// Selector de 3 botones (Día, Semana, Mes) con estilo glassmorphism.
class CalendarSegmentedControl extends StatelessWidget {
  final CalendarViewMode currentMode;
  final ValueChanged<CalendarViewMode> onModeChanged;

  const CalendarSegmentedControl({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF13182C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _buildSegment('Día', CalendarViewMode.day),
          _buildSegment('Semana', CalendarViewMode.week),
          _buildSegment('Mes', CalendarViewMode.month),
        ],
      ),
    );
  }

  Widget _buildSegment(String title, CalendarViewMode mode) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF246CF9),
                      Color(0xFF064BE2),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0052E0).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

