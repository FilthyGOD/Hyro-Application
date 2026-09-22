import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/category_model.dart';
import '../tasks_provider.dart';
import '../../categories/category_provider.dart';
import '../../missions/missions_provider.dart';
import '../widgets/task_details_sheet.dart';

/// Pantalla de detalle de una categoría — muestra header con color,
/// promedio de progreso, y lista de tareas.
class CategoryDetailScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final catColor = Color(category.colorValue);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final tasks = taskProvider.tasks
              .where(
                  (t) => t.category == category.name || t.categoryId == category.id)
              .toList();

          final total = tasks.length;
          final completed = tasks.where((t) => t.isCompleted).length;
          final percentage = total == 0 ? 0.0 : (completed / total) * 100;

          // Tiempo estudiado basado en pomodoros (25 min c/u)
          final totalPomodoros =
              tasks.fold<int>(0, (sum, t) => sum + t.pomodorosCompleted);
          final totalMinutes = totalPomodoros * 25;
          final hours = totalMinutes ~/ 60;
          final mins = totalMinutes % 60;
          final tiempoStr = hours > 0
              ? '${hours}h ${mins}min estudiado'
              : '${mins}min estudiado';

          // Prioridad predominante
          final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
          String dominantPriority = 'MEDIA';
          if (pendingTasks.isNotEmpty) {
            final highCount = pendingTasks
                .where((t) =>
                    t.priority == 'HIGH' || t.priority == 'ALTA PRIORIDAD')
                .length;
            final lowCount =
                pendingTasks.where((t) => t.priority == 'LOW' || t.priority == 'BAJA').length;
            if (highCount >= lowCount && highCount > 0) {
              dominantPriority = 'ALTA';
            } else if (lowCount > highCount) {
              dominantPriority = 'BAJA';
            }
          }

          Color priorityColor;
          switch (dominantPriority) {
            case 'ALTA':
              priorityColor = const Color(0xFFEF4444);
              break;
            case 'BAJA':
              priorityColor = const Color(0xFF22C55E);
              break;
            default:
              priorityColor = const Color(0xFFF59E0B);
          }

          return CustomScrollView(
            slivers: [
              // ── Header con color de categoría ──
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                            ),
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.cardBorder),
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteCategoryDialog(context);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Eliminar categoría',
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: const Color(0xFFEF4444)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Icon + Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Category icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: category.iconCodePoint != null
                                  ? Icon(
                                      IconData(
                                        category.iconCodePoint!,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      size: 28,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      category.name.isNotEmpty
                                          ? category.name[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: AppTypography.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Priority badge + time
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dominantPriority,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: priorityColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      tiempoStr,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Promedio / Progress Circle ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _ProgressCirclePainter(
                          percentage: percentage / 100,
                          color: catColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                percentage.toStringAsFixed(1),
                                style: AppTypography.h2.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                              Text(
                                'Promedio',
                                style: AppTypography.bodySmall.copyWith(
                                  color: catColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Lista de tareas ──
              if (tasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Center(
                      child: Text(
                        'Aún no hay tareas en esta categoría',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DetailTaskTile(task: task, catColor: catColor),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  ),
                ),

              // Bottom spacer for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showAddTaskDialog(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 149, 255),
                Color.fromARGB(255, 32, 43, 200),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Eliminar Categoría', style: AppTypography.h3),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${category.name}"?\n\nLas tareas asociadas también serán eliminadas.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () {
                ctx.read<TaskProvider>().deleteTasksByCategory(
                  category.id,
                  category.name,
                );
                ctx.read<CategoryProvider>().deleteCategory(category.id);
                Navigator.pop(ctx);  // Close dialog
                Navigator.of(context).pop();  // Close detail screen
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'MEDIA';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Nueva Tarea', style: AppTypography.h3),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Título de la tarea',
                        ),
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Descripción (opcional)',
                        ),
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Text('Prioridad', style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        dropdownColor: AppColors.surfaceLight,
                        items: ['ALTA PRIORIDAD', 'MEDIA', 'BAJA'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPriority = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Fecha de Vencimiento (Opcional)',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDueDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            selectedDueDate != null
                                ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                                : 'Seleccionar Fecha',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                GestureDetector(
                  onTap: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    int colorValue = 0xFFF59E0B;
                    if (selectedPriority == 'ALTA PRIORIDAD') {
                      colorValue = 0xFFEF4444;
                    }
                    if (selectedPriority == 'BAJA') {
                      colorValue = 0xFF22C55E;
                    }

                    DateTime? finalDueDate;
                    if (selectedDueDate != null) {
                      finalDueDate = DateTime(
                        selectedDueDate!.year,
                        selectedDueDate!.month,
                        selectedDueDate!.day,
                      );
                    }

                    final task = TaskModel(
                      id: const Uuid().v4(),
                      title: title,
                      description: descriptionController.text.trim(),
                      category: category.name,
                      categoryId: category.id,
                      priority: selectedPriority,
                      priorityColorValue: colorValue,
                      pomodorosTarget: 1,
                      dueDate: finalDueDate,
                    );

                    final taskProvider = context.read<TaskProvider>();
                    final tasksInCategory = taskProvider.tasks
                        .where((t) =>
                            t.categoryId == category.id ||
                            t.category == category.name)
                        .length;
                    if (tasksInCategory >= TaskProvider.maxTasksPerCategory) {
                      Navigator.pop(ctx);
                      _showLimitDialog(context);
                      return;
                    }
                    taskProvider.addTask(task);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 149, 255),
                          Color.fromARGB(255, 32, 43, 200),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Agregar Tarea',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Límite de Tareas',
                  style: AppTypography.h3.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            'Has alcanzado el máximo de ${TaskProvider.maxTasksPerCategory} tareas en esta categoría. Elimina alguna antes de crear otra.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}

// ── Task Tile for detail screen ──
class _DetailTaskTile extends StatelessWidget {
  final TaskModel task;
  final Color catColor;

  const _DetailTaskTile({required this.task, required this.catColor});

  void _showDeleteTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Eliminar Actividad', style: AppTypography.h3),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${task.title}"?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () {
                context.read<TaskProvider>().deleteTask(task.id);
                Navigator.pop(ctx);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = Color(task.priorityColorValue);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: catColor.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox circle
          GestureDetector(
            onTap: () {
              final taskProvider = context.read<TaskProvider>();
              final wasCompleted = task.isCompleted;
              taskProvider.toggleTaskCompletion(task.id);

              final missionsProvider = context.read<MissionsProvider>();
              if (!wasCompleted) {
                missionsProvider.updateProgress('task_completed', 1);
              } else {
                missionsProvider.updateProgress('task_completed', -1);
              }
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? catColor : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? catColor
                      : AppColors.textTertiary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => TaskDetailsDialog(task: task),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Text(
                task.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? AppColors.textTertiary : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Priority badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: priorityColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              task.priority,
              style: AppTypography.labelSmall.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pomodoro count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 16,
                color: Color(0xFFFFA600),
              ),
              const SizedBox(width: 3),
              Text(
                '${task.pomodorosCompleted}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Three dots menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
            color: AppColors.surface,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteTaskDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Eliminar actividad',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress Circle Painter ──
class _ProgressCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _ProgressCirclePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          color,
          color.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
