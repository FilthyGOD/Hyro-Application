import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import '../tasks_provider.dart';
import '../screens/category_exam_screen.dart';

class CategoryExamConfigDialog extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryExamConfigDialog({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryExamConfigDialog> createState() => _CategoryExamConfigDialogState();
}

class _CategoryExamConfigDialogState extends State<CategoryExamConfigDialog> {
  bool _useAllTasks = true;
  List<String> _selectedTaskIds = [];

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks.where((t) => t.categoryId == widget.categoryId).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Examen: ${widget.categoryName}',
                    style: AppTypography.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona las tareas a incluir en tu examen',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _SelectionModeButton(
                      title: 'Todas',
                      isSelected: _useAllTasks,
                      onTap: () {
                        setState(() {
                          _useAllTasks = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectionModeButton(
                      title: 'Específicas',
                      isSelected: !_useAllTasks,
                      onTap: () {
                        setState(() {
                          _useAllTasks = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (!_useAllTasks) ...[
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isSelected = _selectedTaskIds.contains(task.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(task.title, style: AppTypography.bodyMedium),
                      activeColor: const Color(0xFF10B981),
                      checkColor: Colors.white,
                      side: const BorderSide(color: AppColors.textSecondary),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTaskIds.add(task.id);
                          } else {
                            _selectedTaskIds.remove(task.id);
                          }
                        });
                      },
                    );
                  },
                ),
              )
            ] else ...[
              const SizedBox(height: 16),
            ],

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  final finalTaskIds = _useAllTasks ? tasks.map((t) => t.id).toList() : _selectedTaskIds;
                  
                  if (finalTaskIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona al menos una tarea')),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryExamScreen(
                        taskIds: finalTaskIds,
                        categoryName: widget.categoryName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Comenzar Examen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionModeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionModeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? const Color(0xFF10B981) : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
