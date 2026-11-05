import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/services/notifications_service.dart';
import '../../../features/categories/category_provider.dart';
import '../../../features/tasks/tasks_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/task_model.dart';
import '../../../features/tasks/screens/category_detail_screen.dart';
import '../../../features/tasks/widgets/task_details_sheet.dart';

/// Modal desplegable global tipo Bottom Sheet para crear Tareas, Categorías, Recordatorios y Horarios.
/// Sale desde abajo por encima de toda la interfaz (incluyendo la barra flotante),
/// con selector tipo píldora arriba y botón de acción ancho abajo (Estilo Imagen 2).
class GlobalCreateModal extends StatefulWidget {
  final int initialTab;

  const GlobalCreateModal({super.key, this.initialTab = 0});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Sube por encima de toda la app (barra inferior incluida)
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => GlobalCreateModal(initialTab: initialTab),
    );
  }

  @override
  State<GlobalCreateModal> createState() => _GlobalCreateModalState();
}

class _GlobalCreateModalState extends State<GlobalCreateModal> {
  late int _currentTab;

  // ── Formulario: Tarea ──
  final _taskTitleController = TextEditingController();
  final _taskNotesController = TextEditingController();
  String? _taskCategoryId;
  String _taskPriority = 'MEDIA';
  DateTime? _taskDueDate;
  TimeOfDay? _taskDueTime;

  // ── Formulario: Categoría ──
  final _catTitleController = TextEditingController();
  int _catSelectedColor = 0xFF22C55E;
  int? _catSelectedIcon = Icons.school.codePoint;
  bool _catShowAllColors = false;
  bool _catShowAllIcons = false;

  // ── Formulario: Recordatorio ──
  final _reminderTitleController = TextEditingController();
  int _reminderColor = 0xFF3B82F6;
  String _reminderPriority = 'MEDIA';
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;

  // ── Formulario: Horario ──
  String? _scheduleCategoryId;
  String _scheduleDay = 'Lunes';
  TimeOfDay _scheduleStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _scheduleEndTime = const TimeOfDay(hour: 10, minute: 0);
  final _scheduleRoomController = TextEditingController();

  static const List<int> _colors = [
    0xFF22C55E, // Green
    0xFF3B82F6, // Blue
    0xFFEF4444, // Red
    0xFFF59E0B, // Orange
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFF14B8A6, // Teal
    0xFF10B981, // Emerald
    0xFF84CC16, // Lime
    0xFFEAB308, // Yellow
    0xFFF97316, // Deep Orange
    0xFF6366F1, // Indigo
    0xFFD946EF, // Fuchsia
    0xFFF43F5E, // Rose
    0xFF64748B, // Slate
    0xFF78716C, // Stone
    0xFFA855F7, // Light Purple
    0xFF0EA5E9, // Sky Blue
    0xFF2DD4BF, // Light Teal
    0xFFFBBF24, // Amber
    0xFFFB923C, // Coral
    0xFF9333EA, // Deep Purple
  ];

  static final List<int> _icons = [
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
    Icons.book.codePoint,
    Icons.language.codePoint,
    Icons.calculate.codePoint,
    Icons.science.codePoint,
    Icons.biotech.codePoint,
    Icons.build.codePoint,
    Icons.code.codePoint,
    Icons.terminal.codePoint,
    Icons.brush.codePoint,
    Icons.camera_alt.codePoint,
    Icons.movie.codePoint,
    Icons.sports_soccer.codePoint,
    Icons.home.codePoint,
    Icons.star.codePoint,
    Icons.bolt.codePoint,
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _reminderDate = DateTime.now();
    _reminderTime = const TimeOfDay(hour: 12, minute: 0);
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskNotesController.dispose();
    _catTitleController.dispose();
    _reminderTitleController.dispose();
    _scheduleRoomController.dispose();
    super.dispose();
  }

  String get _currentTitle {
    switch (_currentTab) {
      case 0:
        return 'Nueva Tarea';
      case 1:
        return 'Nueva Categoría';
      case 2:
        return 'Nuevo Recordatorio';
      case 3:
        return 'Nuevo Horario';
      default:
        return 'Crear';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Ocupa el 92% de la altura de la pantalla (como en la Imagen 2)
    final sheetHeight = MediaQuery.of(context).size.height * 0.92;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: sheetHeight,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color(0xFF101422), // Fondo sólido que cubre completamente la barra inferior
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: Color(0xFF2A324B), width: 1.5),
            left: BorderSide(color: Color(0xFF2A324B), width: 1.0),
            right: BorderSide(color: Color(0xFF2A324B), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: bottomInset == 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                // ── Drag Handle Superior ──
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    margin: const EdgeInsets.only(top: 14, bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // ── Header con Título y Botón Cerrar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentTitle,
                        style: AppTypography.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // ── Barra de Selección tipo Píldora (Imagen 2 & 5) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTabItem(0, 'Tarea', Icons.check_circle_outline_rounded),
                            const SizedBox(width: 4),
                            _buildTabItem(1, 'Categoría', Icons.folder_outlined),
                            const SizedBox(width: 4),
                            _buildTabItem(2, 'Recordatorio', Icons.notifications_none_rounded),
                            const SizedBox(width: 4),
                            _buildTabItem(3, 'Horario', Icons.schedule_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Formulario Scrolleable con los campos ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentTabForm(),
                    ),
                  ),
                ),

                // ── Botón Inferior Ancho Fijo (Estilo Imagen 2) ──
                _buildBottomFixedAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabForm() {
    switch (_currentTab) {
      case 0:
        return _buildTaskForm();
      case 1:
        return _buildCategoryForm();
      case 2:
        return _buildReminderForm();
      case 3:
        return _buildScheduleForm();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PESTAÑA: TAREA (Imagen 2)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTaskForm() {
    final categories = context.watch<CategoryProvider>().categories;

    return Column(
      key: const ValueKey('form_task'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de actividad / Título
        _buildFieldLabel('TÍTULO DE LA TAREA'),
        const SizedBox(height: 6),
        TextField(
          controller: _taskTitleController,
          decoration: _inputDecoration(hint: 'Título de la tarea'),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Categoría / Materia
        _buildFieldLabel('MATERIA / CATEGORÍA'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _taskCategoryId,
          dropdownColor: AppColors.surfaceLight,
          decoration: _inputDecoration(hint: 'Selecciona una materia'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin Categoría', style: TextStyle(color: Colors.white70)),
            ),
            ...categories.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: Color(c.colorValue), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(c.name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) => setState(() => _taskCategoryId = val),
        ),
        const SizedBox(height: 16),

        // Prioridad
        _buildFieldLabel('PRIORIDAD'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _taskPriority,
          dropdownColor: AppColors.surfaceLight,
          decoration: _inputDecoration(),
          items: const [
            DropdownMenuItem(value: 'ALTA PRIORIDAD', child: Text('ALTA PRIORIDAD', style: TextStyle(color: Color(0xFFEF4444)))),
            DropdownMenuItem(value: 'MEDIA', child: Text('MEDIA', style: TextStyle(color: Color(0xFFF59E0B)))),
            DropdownMenuItem(value: 'BAJA', child: Text('BAJA', style: TextStyle(color: Color(0xFF22C55E)))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _taskPriority = val);
          },
        ),
        const SizedBox(height: 16),

        // Fecha de Vencimiento
        _buildFieldLabel('FECHA DE VENCIMIENTO (OPCIONAL)'),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: _taskDueDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: _taskDueTime ?? TimeOfDay.now(),
              );
              setState(() {
                _taskDueDate = date;
                _taskDueTime = time;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  _taskDueDate != null
                      ? '${_taskDueDate!.day}/${_taskDueDate!.month}/${_taskDueDate!.year}${_taskDueTime != null ? ' - ${_taskDueTime!.format(context)}' : ''}'
                      : 'Seleccionar Fecha',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _taskDueDate != null ? Colors.white : Colors.white54,
                  ),
                ),
                if (_taskDueDate != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _taskDueDate = null;
                      _taskDueTime = null;
                    }),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detalles / Notas (Como en Imagen 2: DETAILS)
        _buildFieldLabel('DETALLES / NOTAS (OPCIONAL)'),
        const SizedBox(height: 6),
        TextField(
          controller: _taskNotesController,
          maxLines: 3,
          decoration: _inputDecoration(hint: 'Agregar notas o instrucciones...'),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveTask() {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) {
      _showSnackbar('Por favor ingresa el título de la tarea');
      return;
    }

    final catProvider = context.read<CategoryProvider>();
    final taskProvider = context.read<TaskProvider>();

    CategoryModel? matchedCat;
    if (_taskCategoryId != null) {
      try {
        matchedCat = catProvider.categories.firstWhere((c) => c.id == _taskCategoryId);
      } catch (_) {}
    }

    // Validar límite de tareas por categoría
    if (_taskCategoryId != null) {
      final tasksInCat = taskProvider.tasks.where((t) => t.categoryId == _taskCategoryId).length;
      if (tasksInCat >= TaskProvider.maxTasksPerCategory) {
        _showSnackbar('Has alcanzado el máximo de tareas en esta categoría');
        return;
      }
    }

    int colorValue = 0xFFF59E0B;
    if (_taskPriority == 'ALTA PRIORIDAD') colorValue = 0xFFEF4444;
    if (_taskPriority == 'BAJA') colorValue = 0xFF22C55E;

    DateTime? finalDueDate;
    if (_taskDueDate != null) {
      final time = _taskDueTime ?? const TimeOfDay(hour: 0, minute: 0);
      finalDueDate = DateTime(
        _taskDueDate!.year,
        _taskDueDate!.month,
        _taskDueDate!.day,
        time.hour,
        time.minute,
      );
    }

    final taskId = generateId();
    final task = TaskModel(
      id: taskId,
      title: title,
      description: _taskNotesController.text.trim(),
      notes: _taskNotesController.text.trim(),
      category: matchedCat?.name,
      categoryId: matchedCat?.id,
      priority: _taskPriority,
      priorityColorValue: colorValue,
      pomodorosTarget: 1,
      dueDate: finalDueDate,
    );

    taskProvider.addTask(task);

    // Si tiene fecha, programar recordatorio
    if (finalDueDate != null) {
      NotificationsService.instance.scheduleTaskReminder(
        taskId,
        title,
        finalDueDate,
        false,
      );
    }

    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => TaskDetailsDialog(task: task),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PESTAÑA: CATEGORÍA (Imagen 2 & 3)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryForm() {
    return Column(
      key: const ValueKey('form_category'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de la categoría
        _buildFieldLabel('NOMBRE DE LA CATEGORÍA'),
        const SizedBox(height: 6),
        TextField(
          controller: _catTitleController,
          decoration: _inputDecoration(hint: 'Ej. Matemáticas, Programación'),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Selector de Color
        _buildFieldLabel('COLOR'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: (_catShowAllColors ? _colors : _colors.take(8)).map((c) {
            final isSelected = _catSelectedColor == c;
            return GestureDetector(
              onTap: () => setState(() => _catSelectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 10)]
                      : null,
                ),
                child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
        if (_colors.length > 8)
          TextButton(
            onPressed: () => setState(() => _catShowAllColors = !_catShowAllColors),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            child: Text(
              _catShowAllColors ? 'Mostrar menos' : 'Mostrar más',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        const SizedBox(height: 16),

        // Selector de Ícono
        _buildFieldLabel('ÍCONO (OPCIONAL)'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: (_catShowAllIcons ? _icons : _icons.take(8)).map((iconCode) {
            final isSelected = _catSelectedIcon == iconCode;
            return GestureDetector(
              onTap: () => setState(() => _catSelectedIcon = isSelected ? null : iconCode),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
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
        if (_icons.length > 8)
          TextButton(
            onPressed: () => setState(() => _catShowAllIcons = !_catShowAllIcons),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            child: Text(
              _catShowAllIcons ? 'Mostrar menos' : 'Mostrar más',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveCategory() {
    final title = _catTitleController.text.trim();
    if (title.isEmpty) {
      _showSnackbar('Por favor ingresa el nombre de la categoría');
      return;
    }

    final catProvider = context.read<CategoryProvider>();
    if (catProvider.categories.length >= CategoryProvider.maxCategories) {
      _showSnackbar('Has alcanzado el máximo de categorías permitidas');
      return;
    }

    final cat = CategoryModel(
      id: generateId(),
      name: title,
      colorValue: _catSelectedColor,
      iconCodePoint: _catSelectedIcon,
    );

    catProvider.addCategory(cat);
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(category: cat),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. PESTAÑA: RECORDATORIO (Imagen 2)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReminderForm() {
    final reminderColors = [
      0xFF3B82F6, // Azul
      0xFF10B981, // Esmeralda
      0xFFF59E0B, // Naranja
      0xFF8B5CF6, // Púrpura
      0xFFEF4444, // Rojo
      0xFFEC4899, // Rosa
    ];

    return Column(
      key: const ValueKey('form_reminder'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del recordatorio
        _buildFieldLabel('TÍTULO DEL RECORDATORIO'),
        const SizedBox(height: 6),
        TextField(
          controller: _reminderTitleController,
          decoration: _inputDecoration(hint: '¿Qué deseas recordar?'),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Color
        _buildFieldLabel('COLOR DE ALERTA'),
        const SizedBox(height: 8),
        Row(
          children: reminderColors.map((c) {
            final isSelected = _reminderColor == c;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _reminderColor = c),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Prioridad
        _buildFieldLabel('PRIORIDAD'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _reminderPriority,
          dropdownColor: AppColors.surfaceLight,
          decoration: _inputDecoration(),
          items: const [
            DropdownMenuItem(value: 'ALTA PRIORIDAD', child: Text('ALTA', style: TextStyle(color: Color(0xFFEF4444)))),
            DropdownMenuItem(value: 'MEDIA', child: Text('MEDIA', style: TextStyle(color: Color(0xFFF59E0B)))),
            DropdownMenuItem(value: 'BAJA', child: Text('BAJA', style: TextStyle(color: Color(0xFF22C55E)))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _reminderPriority = val);
          },
        ),
        const SizedBox(height: 16),

        // Fecha y Hora de la alerta
        _buildFieldLabel('FECHA Y HORA DE LA ALERTA'),
        const SizedBox(height: 6),
        Row(
          children: [
            // Fecha
            Expanded(
              child: InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _reminderDate ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _reminderDate = date);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        _reminderDate != null
                            ? '${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year}'
                            : 'Fecha',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Hora
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _reminderTime = time);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        _reminderTime != null ? _reminderTime!.format(context) : 'Hora',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveReminder() {
    final title = _reminderTitleController.text.trim();
    if (title.isEmpty) {
      _showSnackbar('Ingresa un título para el recordatorio');
      return;
    }

    DateTime targetDate = _reminderDate ?? DateTime.now();
    TimeOfDay targetTime = _reminderTime ?? const TimeOfDay(hour: 12, minute: 0);
    final reminderDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      targetTime.hour,
      targetTime.minute,
    );

    final taskId = generateId();
    final task = TaskModel(
      id: taskId,
      title: '🔔 $title',
      description: 'Recordatorio programado',
      priority: _reminderPriority,
      priorityColorValue: _reminderColor,
      dueDate: reminderDateTime,
      pomodorosTarget: 1,
    );

    context.read<TaskProvider>().addTask(task);

    // Programar notificación
    NotificationsService.instance.scheduleTaskReminder(
      taskId,
      title,
      reminderDateTime,
      false,
    );

    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => TaskDetailsDialog(task: task),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PESTAÑA: HORARIO (Imagen 2)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduleForm() {
    final categories = context.watch<CategoryProvider>().categories;
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    return Column(
      key: const ValueKey('form_schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Materia / Asignatura
        _buildFieldLabel('MATERIA / ASIGNATURA'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _scheduleCategoryId,
          dropdownColor: AppColors.surfaceLight,
          decoration: _inputDecoration(hint: 'Selecciona una materia'),
          items: categories.isEmpty
              ? [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin materias (crea una primero)', style: TextStyle(color: Colors.white54)),
                  ),
                ]
              : categories.map((c) {
                  return DropdownMenuItem<String?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: Color(c.colorValue), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
          onChanged: (val) => setState(() => _scheduleCategoryId = val),
        ),
        const SizedBox(height: 16),

        // Día de la semana
        _buildFieldLabel('DÍA DE LA SEMANA'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) {
              final isSelected = _scheduleDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : AppColors.cardBorder,
                    ),
                  ),
                  onSelected: (_) => setState(() => _scheduleDay = day),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Horario (Inicio y Fin)
        _buildFieldLabel('HORARIO DE CLASE'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _scheduleStartTime,
                  );
                  if (time != null) setState(() => _scheduleStartTime = time);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text('Inicio: ${_scheduleStartTime.format(context)}', style: AppTypography.bodySmall),
                    ],
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
                    initialTime: _scheduleEndTime,
                  );
                  if (time != null) setState(() => _scheduleEndTime = time);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text('Fin: ${_scheduleEndTime.format(context)}', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Salón / Aula
        _buildFieldLabel('AULA / SALÓN (OPCIONAL)'),
        const SizedBox(height: 6),
        TextField(
          controller: _scheduleRoomController,
          decoration: _inputDecoration(hint: 'Ej. Aula 204 o En línea'),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveSchedule() {
    final catProvider = context.read<CategoryProvider>();
    CategoryModel? matchedCat;
    if (_scheduleCategoryId != null) {
      try {
        matchedCat = catProvider.categories.firstWhere((c) => c.id == _scheduleCategoryId);
      } catch (_) {}
    }

    final catName = matchedCat?.name ?? 'Clase';
    final room = _scheduleRoomController.text.trim();

    // Calcular próxima fecha correspondiente a ese día de la semana
    final now = DateTime.now();
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final targetWeekday = dayNames.indexOf(_scheduleDay) + 1;
    int daysUntilTarget = targetWeekday - now.weekday;
    if (daysUntilTarget < 0) daysUntilTarget += 7;

    final targetDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      _scheduleStartTime.hour,
      _scheduleStartTime.minute,
    );

    final task = TaskModel(
      id: generateId(),
      title: '📚 Clase: $catName',
      description: 'Día: $_scheduleDay • Horario: ${_scheduleStartTime.format(context)} - ${_scheduleEndTime.format(context)}${room.isNotEmpty ? ' • $room' : ''}',
      category: matchedCat?.name,
      categoryId: matchedCat?.id,
      priority: 'MEDIA',
      priorityColorValue: matchedCat?.colorValue ?? 0xFF3B82F6,
      dueDate: targetDate,
      pomodorosTarget: 1,
    );

    context.read<TaskProvider>().addTask(task);

    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => TaskDetailsDialog(task: task),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  /// Botón inferior fijo a todo el ancho (Estilo Imagen 2)
  Widget _buildBottomFixedAction() {
    String label;
    VoidCallback onSubmit;
    switch (_currentTab) {
      case 0:
        label = 'Agregar Tarea';
        onSubmit = _saveTask;
        break;
      case 1:
        label = 'Crear Categoría';
        onSubmit = _saveCategory;
        break;
      case 2:
        label = 'Agregar Recordatorio';
        onSubmit = _saveReminder;
        break;
      case 3:
        label = 'Guardar Horario';
        onSubmit = _saveSchedule;
        break;
      default:
        label = 'Guardar';
        onSubmit = () {};
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101422),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.4)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Container(
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
                color: const Color(0xFF0052E0).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSubmit,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
