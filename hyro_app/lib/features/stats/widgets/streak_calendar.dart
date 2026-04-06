import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../data/models/daily_stats.dart';

class StreakCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final Map<String, DailyStats> monthStats;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const StreakCalendar({
    super.key,
    required this.displayMonth,
    required this.monthStats,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Basic calendar logic
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      displayMonth.year,
      displayMonth.month,
    );
    // 1 is Monday, 7 is Sunday
    int firstWeekday = firstDayOfMonth.weekday; // 1 to 7

    // UI needs Sunday first? The image shows D L M M J V S (Domingo, Lunes, etc.) - assume Monday first or Sunday first?
    // User requested "D L M M J V S", which is Sunday = D, Monday = L. Wait, Domingo, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado.
    // So Sunday is the first day of the week in the design.
    // If firstWeekday = 7 (Sunday), we want it in column 0.
    // So shift = firstWeekday % 7
    int startingEmptyDays = firstWeekday % 7;

    final monthName = _getMonthName(displayMonth.month);
    final year = displayMonth.year;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text('Calendario de Rachas', style: AppTypography.h3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        onPressed: onPreviousMonth,
                        splashRadius: 20,
                      ),
                      Text('$monthName $year', style: AppTypography.bodyMedium),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                        onPressed: onNextMonth,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildDaysOfWeek(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: startingEmptyDays + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startingEmptyDays) {
                return const SizedBox.shrink();
              }
              final dayIndex = index - startingEmptyDays + 1;
              final dateStr =
                  '${displayMonth.year}-${displayMonth.month.toString().padLeft(2, '0')}-${dayIndex.toString().padLeft(2, '0')}';
              final stats = monthStats[dateStr];
              final hasFocus = stats != null && stats.focusSessions > 0;
              final isToday = _isToday(
                displayMonth.year,
                displayMonth.month,
                dayIndex,
              );

              return _buildDayCell(dayIndex, hasFocus, isToday);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    const days = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          days.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDayCell(int day, bool hasFocus, bool isToday) {
    Color bgColor = AppColors.surfaceLight;
    Color textColor = Colors.white70;

    if (hasFocus) {
      bgColor = Colors.orange; // Streak color
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppColors.primary.withValues(alpha: 0.4);
      textColor = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border:
            isToday && !hasFocus ? Border.all(color: AppColors.primary) : null,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight:
                hasFocus || isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  bool _isToday(int year, int month, int day) {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}
