import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../tasks/tasks_provider.dart';

/// Mini task list shown on the Focus screen.
class MiniTaskList extends StatelessWidget {
  const MiniTaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final uncompleted = tasks.where((t) => !t.isCompleted).toList();

    // Sort descending by priority weight
    uncompleted.sort((a, b) {
      int weightA = _getPriorityWeight(a.priority);
      int weightB = _getPriorityWeight(b.priority);
      return weightB.compareTo(weightA);
    });

    final topTasks = uncompleted.take(2).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks', style: AppTypography.h3),
              GestureDetector(
                onTap: () {
                  // Navigate to tasks tab (handled by parent usually, or index change)
                },
                child: Text(
                  'View All',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No pending tasks. Great job!',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ...topTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _TaskItem(
                  title: task.title,
                  subtitle: task.category ?? 'No Category',
                  color: Color(task.priorityColorValue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getPriorityWeight(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      case 'LOW':
        return 1;
      default:
        return 0;
    }
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _TaskItem({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
