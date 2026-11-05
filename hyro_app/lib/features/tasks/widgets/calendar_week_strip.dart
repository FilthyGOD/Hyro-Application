import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Barra horizontal de 7 días (Lunes a Domingo) para las vistas de Día y Semana.
class CalendarWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, List<Color>>? dotsByDate;

  const CalendarWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dotsByDate,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos el lunes de la semana que contiene `selectedDate`
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    const dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekDays[index];
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, DateTime.now());

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF246CF9),
                            Color(0xFF0448DB),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isToday
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0052E0).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLetters[index],
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? const Color(0xFF00E5FF)
                                : Colors.white60),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: AppTypography.labelLarge.copyWith(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

