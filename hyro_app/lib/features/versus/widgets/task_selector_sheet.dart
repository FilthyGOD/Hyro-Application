import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/tarea_card_model.dart';

import '../../../../data/models/category_model.dart';

/// BottomSheet para seleccionar la tarea en un duelo de tareas/materias cruzadas.
class TaskSelectorSheet extends StatefulWidget {
  final List<TaskModel> tasks;

  const TaskSelectorSheet({
    super.key,
    required this.tasks,
  });

  @override
  State<TaskSelectorSheet> createState() => _TaskSelectorSheetState();
}

class _TaskSelectorSheetState extends State<TaskSelectorSheet> {
  CategoryModel? _selectedCategory;
  late final Box<CategoryModel> _categoriesBox;
  late final Box<TareaCardModel> _cardsBox;

  @override
  void initState() {
    super.initState();
    _categoriesBox = Hive.box<CategoryModel>('categoriesBox');
    _cardsBox = Hive.box<TareaCardModel>('cardsBox');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedCategory == null
            ? _buildCategoryList()
            : _buildTaskList(_selectedCategory!),
      ),
    );
  }

  Widget _buildCategoryList() {
    // Extraer categorías únicas de las tareas
    final catIds = widget.tasks.map((t) => t.categoryId).where((id) => id != null).toSet();
    final categories = _categoriesBox.values.where((c) => catIds.contains(c.id)).toList();

    return Column(
      key: const ValueKey('categories'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          'Selecciona la Materia',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Primero, elige la materia de la cual quieres usar tus apuntes.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text(
                'No tienes materias disponibles.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = Color(category.colorValue);
                final taskCount = widget.tasks.where((t) => t.categoryId == category.id).length;

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
                      category.iconCodePoint != null ? IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.folder,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$taskCount tareas',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTaskList(CategoryModel category) {
    final tasks = widget.tasks.where((t) => t.categoryId == category.id).toList();

    return Column(
      key: ValueKey('tasks_${category.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ahora selecciona la tarea específica.',
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
                'No tienes tareas en esta materia.',
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
                final numCards = _cardsBox.values.where((c) => c.tareaId == task.id).length;
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
    );
  }
}
