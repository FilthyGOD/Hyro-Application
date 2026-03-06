import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Activity chart card showing daily focus sessions as vertical bars.
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key});

  // Sample data — would come from session repository in production
  static const _data = [0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.8];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
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
              children: List.generate(_data.length, (i) {
                return _ActivityBar(
                  value: _data[i],
                  label: _labels[i],
                  isToday: i == 4, // Friday
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
                  color: isToday ? AppColors.primary : AppColors.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isToday
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
