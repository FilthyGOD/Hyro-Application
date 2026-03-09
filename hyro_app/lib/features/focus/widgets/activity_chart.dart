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
    // Fixed labels for current week (Monday to Sunday)
    final List<String> labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    final data = context.watch<StatsProvider>().weeklyActivityData;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVITY', style: AppTypography.statLabel),
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
                  isToday: i == todayIndex,
                );
              }),
            ),
          ),
        ],
      ),
    );
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
