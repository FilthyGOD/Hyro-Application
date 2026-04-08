import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../categories/category_provider.dart';
import '../../../app.dart';
import '../../../data/models/task_model.dart';

/// Mini task list shown on the Focus screen.
class MiniTaskList extends StatelessWidget {
  const MiniTaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isAuth = taskProvider.isAuthenticated();
    final userId = taskProvider.getUserId();

    if (isAuth && userId != null) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('tareas')
            .stream(primaryKey: ['id']).eq('usuario_id', userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const GlassCard(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final maps = snapshot.data ?? [];
          final tasks = maps.map((m) => TaskModel.fromSupabaseJson(m)).toList();
          
          final topTasks = _getTopTasks(tasks);
          return _buildGlassCard(context, topTasks);
        },
      );
    } else {
      // Local behavior
      final tasks = taskProvider.tasks;
      final topTasks = _getTopTasks(tasks);
      return _buildGlassCard(context, topTasks);
    }
  }

  List<TaskModel> _getTopTasks(List<TaskModel> tasks) {
    final uncompleted = tasks.where((t) => !t.isCompleted).toList();
    
    // Sort ascending by due date (closest first). Nulls go to the bottom.
    uncompleted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return uncompleted.take(2).toList();
  }

  Widget _buildGlassCard(BuildContext context, List<TaskModel> topTasks) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tareas', style: AppTypography.h3),
              GestureDetector(
                onTap: () {
                  context.findAncestorStateOfType<AppShellState>()?.navigateTo(1);
                },
                child: Text(
                  'Ver Todas',
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
                'No hay tareas pendientes. ¡Buen trabajo!',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ...topTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildTaskItem(context, task),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    final categories = context.read<CategoryProvider>().categories;
    String categoryName = 'Sin Categoría';
    
    if (task.category != null && task.category!.isNotEmpty) {
      categoryName = task.category!;
    } else if (task.categoryId != null) {
      try {
        final cat = categories.firstWhere((c) => c.id == task.categoryId);
        categoryName = cat.name;
      } catch (_) {}
    }

    return _TaskItem(
      title: task.title,
      subtitle: categoryName,
      color: Color(task.priorityColorValue),
    );
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
