import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';

/// Tasks screen — CRUD for study tasks.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<_DemoTask> _tasks = [
    _DemoTask('Design System Update', 'Foundations & Typography', false),
    _DemoTask('Flutter Architecture', 'State Management with Bloc', false),
    _DemoTask('Database Design', 'Supabase Tables & RLS', true),
    _DemoTask('UI Components', 'Buttons, Cards, Inputs', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks', style: AppTypography.h1),
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Task'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_tasks.where((t) => !t.completed).length} pending • ${_tasks.where((t) => t.completed).length} completed',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          // ── Task List ──
          Expanded(
            child: ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => task.completed = !task.completed);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.completed
                                ? AppColors.breakGreen.withAlpha(30)
                                : AppColors.surfaceLight,
                            border: Border.all(
                              color: task.completed
                                  ? AppColors.breakGreen
                                  : AppColors.cardBorder,
                              width: 2,
                            ),
                          ),
                          child: task.completed
                              ? const Icon(Icons.check, size: 16, color: AppColors.breakGreen)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: AppTypography.labelLarge.copyWith(
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.completed
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(task.subtitle, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: AppColors.textTertiary, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Task', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Task title'),
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'Description (optional)'),
              style: AppTypography.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DemoTask {
  final String title;
  final String subtitle;
  bool completed;
  _DemoTask(this.title, this.subtitle, this.completed);
}
