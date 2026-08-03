import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/tarea_card_model.dart';

/// BottomSheet para seleccionar la tarea en un duelo de tareas/materias cruzadas.
class TaskSelectorSheet extends StatelessWidget {
  final List<TaskModel> tasks;

  const TaskSelectorSheet({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final cardsBox = Hive.box<TareaCardModel>('cardsBox');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona tu Tarea',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Para este duelo cruzado, responderás preguntas basadas en la tarea que elijas.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'No tienes tareas disponibles.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final numCards = cardsBox.values.where((c) => c.tareaId == task.id).length;
                  final color = Color(task.priorityColorValue);

                  return ListTile(
                    tileColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(
                        Icons.assignment_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$numCards flashcards creadas',
                      style: AppTypography.bodySmall.copyWith(
                        color: numCards > 0 ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: numCards > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, task),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
