import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../stats/stats_provider.dart';

/// Activity chart card showing daily focus sessions as vertical bars.
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate labels for the last 7 days, ending today at index 6
    final List<String> labels = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final String weekdayStr = _getWeekdayLabel(
        now.subtract(Duration(days: i)).weekday,
      );
      labels.add(weekdayStr);
    }

    final data = context.watch<StatsProvider>().weeklyActivityData;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVIDAD', style: AppTypography.statLabel),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                return _ActivityBar(
                  value: data[i],
                  label: labels[i],
                  isToday:
                      i ==
                      6, // Index 6 is today because we generated 6 to 0 days ago
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'X';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'D';
      default:
        return '';
    }
  }
}

class _ActivityBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final String label;
  final bool isToday;

  const _ActivityBar({
    required this.value,
    required this.label,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow:
                      isToday
                          ? AppColors.glowShadow(AppColors.primary, blur: 8)
                          : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 9,
            color: isToday ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
