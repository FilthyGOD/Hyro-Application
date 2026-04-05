import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/task_model.dart';
import 'tasks_provider.dart';
import '../stats/stats_provider.dart';
import '../../providers/ui_provider.dart';
import '../categories/category_provider.dart';
import 'widgets/task_details_sheet.dart';
import '../../data/models/category_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // ── Demo data ──
  // ── Categories will be dynamic ──
  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Consumer<UiProvider>(
        builder: (context, ui, _) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: ui.isMusicBarVisible ? 80 : 0,
            ),
            child: FloatingActionButton(
              onPressed: _showAddCategoryDialog,
              backgroundColor: AppColors.timerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          return SingleChildScrollView(
            child: Padding(
              padding: isLargeScreen
                  ? const EdgeInsets.only(
                      left: 72,
                      top: 32,
                      right: 32,
                      bottom: 32,
                    )
                  : const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile: !isLargeScreen),
                  const SizedBox(height: 32),
                  _buildTopCards(isLargeScreen: isLargeScreen),
                  const SizedBox(height: 32),
                  _buildCategoryCards(),
                  const SizedBox(height: 32),
                  _buildCategoriesHeader(),
                  const SizedBox(height: 16),
                  _buildCategoryList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCards({required bool isLargeScreen}) {
    if (isLargeScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildAnalyticsCard()),
          const SizedBox(width: 24),
          Expanded(child: _buildUpcomingCard()),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnalyticsCard(),
          const SizedBox(height: 16),
          _buildUpcomingCard(),
        ],
      );
    }
  }

  Widget _buildHeader({required bool isMobile}) {
    return Consumer<StatsProvider>(
      builder: (context, statsProvider, _) {
        final streak = statsProvider.currentStreak;
        final formattedDate = _getFormattedDate();

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Pendientes',
                style: isMobile ? AppTypography.h2 : AppTypography.h1,
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: isMobile ? Alignment.center : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$formattedDate • Racha de Enfoque: $streak días ',
                      style: AppTypography.bodySmall,
                    ),
                    if (streak > 0)
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    // weekday is 1-7 (Mon-Sun), days[0] is Sunday
    return '${days[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }

  Widget _buildCategoryCards() {
    return Consumer2<CategoryProvider, TaskProvider>(
      builder: (context, categoryProvider, taskProvider, child) {
        final categories = categoryProvider.categories;
        if (categories.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final tasks = taskProvider.tasks.where((t) => t.category == cat.name);
              final pending = tasks.where((t) => !t.isCompleted).length;
              final total = tasks.length;
              
              final isSelected = _selectedCategoryName == cat.name || 
                                 (_selectedCategoryName == null && cat == categories.first);
              
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryName = cat.name;
                    });
                  },
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.5,
                    child: SizedBox(
                      width: 160,
                      child: _CategoryCard(
                        category: cat,
                        pending: pending,
                        total: total,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tus Categorías", style: AppTypography.h3),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return Consumer2<CategoryProvider, TaskProvider>(
      builder: (context, categoryProvider, taskProvider, child) {
        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Aún no hay categorías. ¡Crea una!',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final selectedCatName = _selectedCategoryName ?? categories.first.name;
        final selectedCat = categories.cast<CategoryModel?>().firstWhere(
          (c) => c!.name == selectedCatName, 
          orElse: () => categories.first
        );

        if (selectedCat == null) return const SizedBox.shrink();

        final catTasks = taskProvider.tasks.where((t) => t.category == selectedCat.name).toList();
        return _CategoryListTile(
          key: ValueKey(selectedCat.id),
          category: selectedCat,
          tasks: catTasks,
          onAddTask: () => _showAddTaskDialog(initialCategory: selectedCat.name),
        );
      },
    );
  }



  Widget _buildAnalyticsCard() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final tasks = provider.tasks;
        final total = tasks.length;
        final completed = tasks.where((t) => t.isCompleted).length;
        final pending = total - completed;
        final percentage = total == 0 ? 0.0 : (completed / total);
        final percentageStr = (percentage * 100).toInt().toString() + '%';

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Análisis de Tareas', style: AppTypography.h3),
              const SizedBox(height: 20),
              // Circular chart
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _DonutChartPainter(percentage: percentage),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            percentageStr,
                            style: AppTypography.h2.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Hechas',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Stats
              _buildStatRow(
                color: AppColors.primary,
                label: 'Completadas',
                value: completed.toString(),
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                color: const Color(0xFFEC4899),
                label: 'Pendientes',
                value: pending.toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.labelLarge.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildUpcomingCard() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final upcomingTasks =
            provider.tasks
                .where(
                  (t) =>
                      !t.isCompleted &&
                      t.dueDate != null &&
                      t.dueDate!.isAfter(now),
                )
                .toList()
              ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        final topTasks = upcomingTasks.take(3).toList();

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRÓXIMAMENTE',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              if (topTasks.isEmpty)
                Text(
                  'No hay tareas próximas',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...topTasks.map((t) {
                  final month = _getMonthAbbrev(t.dueDate!.month);
                  final day = t.dueDate!.day.toString();
                  final timeStr = TimeOfDay.fromDateTime(
                    t.dueDate!,
                  ).format(context);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpcomingEvent(
                      month: month,
                      day: day,
                      title: t.title,
                      time: timeStr,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _getMonthAbbrev(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  // ── Dialogs ──
  void _showAddCategoryDialog() {
    final titleController = TextEditingController();
    int selectedColor = 0xFF22C55E; // Default Green
    int? selectedIcon; // Default nil

    final colors = [
      0xFF22C55E, // Green
      0xFF3B82F6, // Blue
      0xFFEF4444, // Red
      0xFFF59E0B, // Orange
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF06B6D4, // Cyan
    ];

    final icons = [
      Icons.school.codePoint,
      Icons.person.codePoint,
      Icons.work.codePoint,
      Icons.menu_book.codePoint,
      Icons.computer.codePoint,
      Icons.sports_esports.codePoint,
      Icons.music_note.codePoint,
      Icons.fitness_center.codePoint,
      Icons.flight.codePoint,
      Icons.palette.codePoint,
      Icons.shopping_bag.codePoint,
    ];

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
              title: Text('Nueva Categoría', style: AppTypography.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Nombre de la categoría',
                      ),
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Text('Color', style: AppTypography.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 18, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Ícono (Opcional)', style: AppTypography.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: icons.map((iconCode) {
                        final isSelected = selectedIcon == iconCode;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = (isSelected ? null : iconCode)),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: AppColors.primary, width: 2)
                                  : Border.all(color: Colors.transparent, width: 2),
                            ),
                            child: Icon(
                              IconData(iconCode, fontFamily: 'MaterialIcons'),
                              size: 20,
                              color: isSelected ? AppColors.primary : Colors.white70,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final cat = CategoryModel(
                      id: const Uuid().v4(),
                      name: title,
                      colorValue: selectedColor,
                      iconCodePoint: selectedIcon,
                    );

                    context.read<CategoryProvider>().addCategory(cat);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Crear Categoría'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog({required String initialCategory}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'MEDIA';
    int pomodorosTarget = 1;
    DateTime? selectedDueDate;
    TimeOfDay? selectedDueTime;

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
                      value: selectedPriority,
                      dropdownColor: AppColors.surfaceLight,
                      items:
                          ['ALTA PRIORIDAD', 'MEDIA', 'BAJA'].map((p) {
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
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setDialogState(() => selectedDueDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedDueTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setDialogState(() => selectedDueTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                selectedDueTime != null
                                    ? selectedDueTime!.format(context)
                                    : 'Seleccionar Hora',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pomodoros requeridos:',
                          style: AppTypography.bodySmall,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (pomodorosTarget > 1) {
                                  setDialogState(() => pomodorosTarget--);
                                }
                              },
                            ),
                            Text(
                              '$pomodorosTarget',
                              style: AppTypography.bodyLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setDialogState(() => pomodorosTarget++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    int colorValue = 0xFFF59E0B; // orange
                    if (selectedPriority == 'ALTA PRIORIDAD') {
                      colorValue = 0xFFEF4444; // red
                    }
                    if (selectedPriority == 'BAJA') {
                      colorValue = 0xFF22C55E; // green
                    }

                    DateTime? finalDueDate;
                    if (selectedDueDate != null) {
                      final time =
                          selectedDueTime ??
                          const TimeOfDay(hour: 0, minute: 0);
                      finalDueDate = DateTime(
                        selectedDueDate!.year,
                        selectedDueDate!.month,
                        selectedDueDate!.day,
                        time.hour,
                        time.minute,
                      );
                    }

                    final task = TaskModel(
                      id: const Uuid().v4(),
                      title: title,
                      description: descriptionController.text.trim(),
                      category: initialCategory,
                      priority: selectedPriority,
                      priorityColorValue: colorValue,
                      pomodorosTarget: pomodorosTarget,
                      dueDate: finalDueDate,
                    );

                    context.read<TaskProvider>().addTask(task);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Agregar Tarea'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════

// ── Category List Tile ──
class _CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  final List<TaskModel> tasks;
  final VoidCallback onAddTask;

  const _CategoryListTile({
    super.key,
    required this.category,
    required this.tasks,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = tasks.where((t) => !t.isCompleted).length;
    final color = Color(category.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            collapsedIconColor: AppColors.textSecondary,
            iconColor: color,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: category.iconCodePoint != null
                        ? Icon(
                            IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons'),
                            size: 16,
                            color: color,
                          )
                        : Text(
                            category.name.isNotEmpty ? category.name[0].toUpperCase() : 'C',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTypography.labelLarge.copyWith(fontSize: 16),
                  ),
                ),
                Text(
                  '$pendingCount PENDIENTES',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Aún no hay tareas', style: AppTypography.bodySmall),
                      )
                    else
                      ...tasks.map((t) => _TaskTile(task: t)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar Tarea'),
                        style: TextButton.styleFrom(
                          foregroundColor: color,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onAddTask,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Card ──
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int pending;
  final int total;

  const _CategoryCard({
    required this.category,
    required this.pending,
    required this.total,
  });

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
            '¿Estás seguro de que deseas eliminar "${category.name}"?\n\nLas tareas asociadas no serán eliminadas.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                context.read<CategoryProvider>().deleteCategory(category.id);
                Navigator.pop(ctx);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: category.iconCodePoint != null
                      ? Icon(
                          IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons'),
                          size: 20,
                          color: color,
                        )
                      : Text(
                          category.name.isNotEmpty ? category.name[0].toUpperCase() : 'C',
                          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textTertiary, size: 20),
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
                        const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Eliminar categoría',
                          style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            category.name,
            style: AppTypography.labelLarge.copyWith(fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$pending TAREAS PENDIENTES',
            style: AppTypography.labelSmall.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.0 : ((total - pending) / total),
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Tile ──
class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

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
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox circle
            GestureDetector(
              onTap: () {
                context.read<TaskProvider>().toggleTaskCompletion(task.id);
              },
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      task.isCompleted ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color:
                        task.isCompleted
                            ? AppColors.primary
                            : AppColors.textTertiary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child:
                    task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            // Content Column
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => TaskDetailsDialog(task: task),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    task.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color:
                          task.isCompleted
                              ? AppColors.textTertiary
                              : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (task.description != null && task.description!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.description!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  // Priority and Pomodoros Row
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            task.priorityColorValue,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(
                              task.priorityColorValue,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          task.priority,
                          style: AppTypography.labelSmall.copyWith(
                            color: Color(task.priorityColorValue),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Pomodoro count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${task.pomodorosTarget} Pomodoros',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Delete button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary, size: 18),
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
                    const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Eliminar actividad',
                      style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming Event ──
class _UpcomingEvent extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String time;

  const _UpcomingEvent({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Date badge
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              Text(day, style: AppTypography.h3.copyWith(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.labelLarge.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(time, style: AppTypography.bodySmall),
          ],
        ),
      ],
    );
  }
}

// ── Donut Chart Painter ──
class _DonutChartPainter extends CustomPainter {
  final double percentage;
  _DonutChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background arc
    final bgPaint =
        Paint()
          ..color = AppColors.surfaceLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc — gradient-like sweep
    final progressPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: const [
              Color(0xFF3B82F6),
              Color(0xFF06B6D4),
              Color(0xFF22C55E),
            ],
            stops: const [0.0, 0.5, 1.0],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


