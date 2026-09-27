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
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String _sortOption = 'Fecha';

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );
    final catColor = Color(category.colorValue);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final tasks = taskProvider.tasks
              .where(
                  (t) => t.category == category.name || t.categoryId == category.id)
              .toList();

          tasks.sort((a, b) {
            if (_sortOption == 'Alfabético') {
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            } else if (_sortOption == 'Prioridad') {
              int priorityVal(String p) {
                if (p == 'HIGH' || p == 'ALTA PRIORIDAD') return 1;
                if (p == 'MEDIUM' || p == 'MEDIA') return 2;
                if (p == 'LOW' || p == 'BAJA') return 3;
                return 4;
              }
              return priorityVal(a.priority).compareTo(priorityVal(b.priority));
            } else {
              return b.createdAt.compareTo(a.createdAt);
            }
          });

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
                              if (value == 'edit') {
                                _showEditCategoryDialog(context, category);
                              } else if (value == 'delete') {
                                _showDeleteCategoryDialog(context, category);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Editar categoría',
                                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
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
                                // Time studied
                                Text(
                                  tiempoStr,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
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
                                'Hechas',
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

              // ── Opciones de Ordenamiento ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ordenar por: ',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortOption,
                        dropdownColor: AppColors.surfaceLight,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                        underline: const SizedBox(),
                        items: ['Fecha', 'Prioridad', 'Alfabético'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortOption = newValue;
                            });
                          }
                        },
                      ),
                    ],
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
        onTap: () => _showAddTaskDialog(context, category),
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

  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
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

  void _showEditCategoryDialog(BuildContext context, CategoryModel currentCategory) {
    final titleController = TextEditingController(text: currentCategory.name);
    int selectedColor = currentCategory.colorValue;
    int? selectedIcon = currentCategory.iconCodePoint;
    bool showAllColors = false;
    bool showAllIcons = false;

    final colors = [
      0xFF22C55E, 0xFF3B82F6, 0xFFEF4444, 0xFFF59E0B, 0xFF8B5CF6, 0xFFEC4899, 0xFF06B6D4,
      0xFF14B8A6, 0xFF10B981, 0xFF84CC16, 0xFFEAB308, 0xFFF97316, 0xFF6366F1, 0xFFD946EF,
      0xFFF43F5E, 0xFF64748B, 0xFF78716C, 0xFFA855F7, 0xFF0EA5E9, 0xFF2DD4BF, 0xFFFBBF24,
      0xFFFB923C, 0xFF9333EA,
    ];

    final icons = [
      Icons.school.codePoint, Icons.person.codePoint, Icons.work.codePoint,
      Icons.menu_book.codePoint, Icons.computer.codePoint, Icons.sports_esports.codePoint,
      Icons.music_note.codePoint, Icons.fitness_center.codePoint, Icons.flight.codePoint,
      Icons.palette.codePoint, Icons.shopping_bag.codePoint, Icons.book.codePoint,
      Icons.language.codePoint, Icons.calculate.codePoint, Icons.science.codePoint,
      Icons.biotech.codePoint, Icons.build.codePoint, Icons.code.codePoint,
      Icons.terminal.codePoint, Icons.brush.codePoint, Icons.camera_alt.codePoint,
      Icons.movie.codePoint, Icons.sports_soccer.codePoint, Icons.directions_car.codePoint,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final displayColors = showAllColors ? colors : colors.take(7).toList();
            final displayIcons = showAllIcons ? icons : icons.take(11).toList();
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Editar Categoría', style: AppTypography.h3),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Text('Color', style: AppTypography.bodySmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: displayColors.map((colorValue) {
                          final isSelected = selectedColor == colorValue;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColor = colorValue),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(colorValue).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      if (colors.length > 7)
                        TextButton(
                          onPressed: () => setDialogState(() => showAllColors = !showAllColors),
                          child: Text(
                            showAllColors ? 'Mostrar menos' : 'Mostrar más',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text('Ícono (Opcional)', style: AppTypography.bodySmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: displayIcons.map((iconCode) {
                          final isSelected = selectedIcon == iconCode;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedIcon = isSelected ? null : iconCode;
                              });
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Icon(
                                IconData(iconCode, fontFamily: 'MaterialIcons'),
                                color: isSelected ? AppColors.primary : Colors.white70,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (icons.length > 11)
                        TextButton(
                          onPressed: () => setDialogState(() => showAllIcons = !showAllIcons),
                          child: Text(
                            showAllIcons ? 'Mostrar menos' : 'Mostrar más',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
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
                    
                    final updatedCategory = CategoryModel(
                      id: currentCategory.id,
                      name: title,
                      colorValue: selectedColor,
                      iconCodePoint: selectedIcon,
                    );
                    
                    final categoryProvider = context.read<CategoryProvider>();
                    categoryProvider.updateCategory(updatedCategory);
                    
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 0, 149, 255), Color.fromARGB(255, 32, 43, 200)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  void _showAddTaskDialog(BuildContext context, CategoryModel category) {
    final titleController = TextEditingController();
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
                      description: '',
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
                      _showLimitDialog(context, category);
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

  void _showLimitDialog(BuildContext context, CategoryModel category) {
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

  void _showEditTaskDialog(BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    
    String selectedPriority = task.priority;
    if (selectedPriority == 'HIGH') selectedPriority = 'ALTA PRIORIDAD';
    else if (selectedPriority == 'MEDIUM') selectedPriority = 'MEDIA';
    else if (selectedPriority == 'LOW') selectedPriority = 'BAJA';
    else if (!['ALTA PRIORIDAD', 'MEDIA', 'BAJA'].contains(selectedPriority)) {
      selectedPriority = 'MEDIA';
    }

    DateTime? selectedDueDate = task.dueDate;

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
              title: Text('Editar Tarea', style: AppTypography.h3),
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

                    final updatedTask = task.copyWith(
                      title: title,
                      priority: selectedPriority,
                      priorityColorValue: colorValue,
                      dueDate: finalDueDate,
                    );

                    context.read<TaskProvider>().updateTask(updatedTask);
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
                    ),
                    child: const Text(
                      'Guardar',
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
              if (value == 'edit') {
                _showEditTaskDialog(context);
              } else if (value == 'delete') {
                _showDeleteTaskDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Editar actividad',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
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
