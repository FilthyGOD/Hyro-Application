import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../settings/settings_provider.dart';
import '../../categories/category_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/tarea_card_model.dart';

/// Configuración resultante de la sesión de enfoque.
class FocusSessionConfig {
  final int studyMinutes;
  final int breakMinutes;
  final int coinsReward;
  final String? taskId;
  final String? taskTitle;
  final String? categoryId;
  final String? categoryName;
  final bool quizEnabled;

  const FocusSessionConfig({
    required this.studyMinutes,
    required this.breakMinutes,
    required this.coinsReward,
    this.taskId,
    this.taskTitle,
    this.categoryId,
    this.categoryName,
    required this.quizEnabled,
  });
}

/// Modal principal para configurar e iniciar la sesión de estudio.
class ConfigureFocusSessionModal extends StatefulWidget {
  const ConfigureFocusSessionModal({super.key});

  @override
  State<ConfigureFocusSessionModal> createState() =>
      _ConfigureFocusSessionModalState();
}

class _ConfigureFocusSessionModalState extends State<ConfigureFocusSessionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int _studyMinutes = 25;
  int _breakMinutes = 5;
  int _coinsReward = 10;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedTaskId;
  String? _selectedTaskTitle;

  bool _quizEnabled = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    // Cargar defaults desde SettingsProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      setState(() {
        _quizEnabled = settings.focusQuizEnabled;
        final pomDuration = settings.pomodoroDuration.toInt();
        if (pomDuration == 45) {
          _studyMinutes = 45;
          _breakMinutes = 10;
          _coinsReward = 20;
        } else if (pomDuration == 60) {
          _studyMinutes = 60;
          _breakMinutes = 15;
          _coinsReward = 30;
        } else if (pomDuration == 90) {
          _studyMinutes = 90;
          _breakMinutes = 20;
          _coinsReward = 50;
        } else {
          _studyMinutes = 25;
          _breakMinutes = 5;
          _coinsReward = 10;
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showStudyDurationSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _StudyDurationSelectorDialog(
        currentMinutes: _studyMinutes,
        onDurationSelected: (preset) {
          setState(() {
            _studyMinutes = preset.studyMinutes;
            _breakMinutes = preset.breakMinutes;
            _coinsReward = preset.coinsReward;
          });
        },
      ),
    );
  }

  void _showMaterialSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _StudyMaterialSelectorDialog(
        currentCategoryId: _selectedCategoryId,
        currentTaskId: _selectedTaskId,
        onMaterialSelected: (catId, catName, taskId, taskTitle) {
          setState(() {
            _selectedCategoryId = catId;
            _selectedCategoryName = catName;
            _selectedTaskId = taskId;
            _selectedTaskTitle = taskTitle;
          });
        },
      ),
    );
  }

  void _showQuizTimeSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _QuizTimeSelectorDialog(
        currentEnabled: _quizEnabled,
        onSelected: (enabled) {
          setState(() {
            _quizEnabled = enabled;
          });
        },
      ),
    );
  }

  void _startSession() {
    Navigator.of(context).pop(
      FocusSessionConfig(
        studyMinutes: _studyMinutes,
        breakMinutes: _breakMinutes,
        coinsReward: _coinsReward,
        taskId: _selectedTaskId,
        taskTitle: _selectedTaskTitle ?? (_selectedCategoryId != null ? 'Toda la materia' : null),
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        quizEnabled: _quizEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Título ──
                  Text(
                    'Configurar Sesión',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── 1. Botón: Tiempo de estudio ──
                  _buildSelectorButton(
                    icon: Icons.timer_rounded,
                    title: 'Tiempo de estudio',
                    subtitle:
                        '$_studyMinutes min\nDescanso: $_breakMinutes min • +$_coinsReward monedas',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onTap: _showStudyDurationSelector,
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Fila: Material de estudio + Tiempo de preguntas ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Material de estudio
                        Expanded(
                          child: _buildSelectorButton(
                            icon: Icons.menu_book_rounded,
                            title: 'Material de estudio',
                            subtitle: _selectedCategoryName != null
                                ? '$_selectedCategoryName\n${_selectedTaskTitle ?? "Toda la materia"}'
                                : 'Sin materia\nSin tarea asignada',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            onTap: _showMaterialSelector,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tiempo de preguntas
                        Expanded(
                          child: _buildSelectorButton(
                            icon: Icons.help_outline_rounded,
                            title: 'Tiempo de preguntas',
                            subtitle: _quizEnabled
                                ? 'Sí\n(Activado)'
                                : 'No\n(Desactivado)',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            onTap: _showQuizTimeSelector,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Botones de acción ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Iniciar Sesión (borde verde)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _startSession,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 10, 193, 47),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Iniciar Sesión',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cancelar (borde rojo)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 200, 30, 30),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancelar',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorButton({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final iconBox = Container(
      width: compact ? 38 : 48,
      height: compact ? 38 : 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: compact ? 22 : 26),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
          ),
          child: compact
              // Layout compacto: icono arriba, textos abajo
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [iconBox, if (trailing != null) trailing],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              // Layout normal: fila horizontal
              : Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-DIÁLOGO 1: TIEMPO DE ESTUDIO (Estética Imagen 3 con degradado verde)
// ═════════════════════════════════════════════════════════════════════════════

class StudyDurationPreset {
  final int studyMinutes;
  final int breakMinutes;
  final int coinsReward;
  final String title;
  final String description;

  const StudyDurationPreset({
    required this.studyMinutes,
    required this.breakMinutes,
    required this.coinsReward,
    required this.title,
    required this.description,
  });
}

class _StudyDurationSelectorDialog extends StatefulWidget {
  final int currentMinutes;
  final Function(StudyDurationPreset) onDurationSelected;

  const _StudyDurationSelectorDialog({
    required this.currentMinutes,
    required this.onDurationSelected,
  });

  @override
  State<_StudyDurationSelectorDialog> createState() =>
      _StudyDurationSelectorDialogState();
}

class _StudyDurationSelectorDialogState
    extends State<_StudyDurationSelectorDialog> {
  static const List<StudyDurationPreset> _presets = [
    StudyDurationPreset(
      studyMinutes: 25,
      breakMinutes: 5,
      coinsReward: 10,
      title: '25 Minutos',
      description: '5 min de descanso • +10 monedas',
    ),
    StudyDurationPreset(
      studyMinutes: 45,
      breakMinutes: 10,
      coinsReward: 20,
      title: '45 Minutos',
      description: '10 min de descanso • +20 monedas',
    ),
    StudyDurationPreset(
      studyMinutes: 60,
      breakMinutes: 15,
      coinsReward: 30,
      title: '60 Minutos',
      description: '15 min de descanso • +30 monedas',
    ),
    StudyDurationPreset(
      studyMinutes: 90,
      breakMinutes: 20,
      coinsReward: 50,
      title: '90 Minutos',
      description: '20 min de descanso • +50 monedas',
    ),
  ];

  late StudyDurationPreset _selected;

  @override
  void initState() {
    super.initState();
    _selected = _presets.firstWhere(
      (p) => p.studyMinutes == widget.currentMinutes,
      orElse: () => _presets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    const greenPrimary = Color(0xFF10B981);
    const greenDark = Color(0xFF047857);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header con degradado verde ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [greenPrimary, greenDark],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Tiempo de Estudio',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ..._presets.map((preset) {
                    final isSelected = _selected.studyMinutes == preset.studyMinutes;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selected = preset);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? greenPrimary.withValues(alpha: 0.12)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? greenPrimary
                                    : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? greenPrimary
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.title,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: isSelected
                                              ? greenPrimary
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        preset.description,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFB800)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '+${preset.coinsReward} 🪙',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFFFFB800),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDurationSelected(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-DIÁLOGO 2: MATERIAL DE ESTUDIO (Estética Imagen 2 de amigos/versus)
// ═════════════════════════════════════════════════════════════════════════════

class _StudyMaterialSelectorDialog extends StatefulWidget {
  final String? currentCategoryId;
  final String? currentTaskId;
  final Function(
    String? categoryId,
    String? categoryName,
    String? taskId,
    String? taskTitle,
  ) onMaterialSelected;

  const _StudyMaterialSelectorDialog({
    this.currentCategoryId,
    this.currentTaskId,
    required this.onMaterialSelected,
  });

  @override
  State<_StudyMaterialSelectorDialog> createState() =>
      _StudyMaterialSelectorDialogState();
}

class _StudyMaterialSelectorDialogState
    extends State<_StudyMaterialSelectorDialog> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header naranja ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFF92400E)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Material de estudio',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // ── Body ──
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedCategory == null
                    ? _buildCategoryList()
                    : _buildTaskList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    List<CategoryModel> categories = [];
    try {
      categories = context.watch<CategoryProvider>().categories;
    } catch (_) {}
    if (categories.isEmpty && Hive.isBoxOpen('categoriesBox')) {
      final box = Hive.box<CategoryModel>('categoriesBox');
      categories = box.values.toList();
    }

    List<TaskModel> allTasks = [];
    try {
      allTasks = context.watch<TaskProvider>().tasks;
    } catch (_) {}
    if (allTasks.isEmpty && Hive.isBoxOpen('tasksBox')) {
      final box = Hive.box<TaskModel>('tasksBox');
      allTasks = box.values.toList();
    }

    return Padding(
      key: const ValueKey('study_mat_categories'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de materia
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF92400E).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Selecciona una materia',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Opción 1: Estudiar sin materia ni tarea
          ListTile(
            tileColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.15),
              radius: 20,
              child: const Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            title: Text(
              'Solo estudiar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Sin materia ni tarea asignada',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
            onTap: () {
              widget.onMaterialSelected(null, null, null, null);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),

          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No tienes materias creadas aún.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = Color(category.colorValue);
                  final taskCount =
                      allTasks.where((t) => t.categoryId == category.id).length;

                  return ListTile(
                    tileColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(
                        category.iconCodePoint != null
                            ? IconData(
                                category.iconCodePoint!,
                                fontFamily: 'MaterialIcons',
                              )
                            : Icons.folder,
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
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
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
      ),
    );
  }

  Widget _buildTaskList() {
    final category = _selectedCategory!;
    List<TaskModel> tasks = [];
    try {
      final all = context.watch<TaskProvider>().tasks;
      tasks = all.where((t) => t.categoryId == category.id).toList();
    } catch (_) {}
    if (tasks.isEmpty && Hive.isBoxOpen('tasksBox')) {
      final box = Hive.box<TaskModel>('tasksBox');
      tasks = box.values.where((t) => t.categoryId == category.id).toList();
    }

    Box<TareaCardModel>? cardsBox;
    if (Hive.isBoxOpen('cardsBox')) {
      cardsBox = Hive.box<TareaCardModel>('cardsBox');
    }

    return Padding(
      key: ValueKey('study_mat_tasks_${category.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono y título de la materia
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF92400E).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          // Botón Cambiar materia
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = null;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cambiar materia',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Opción: Toda la materia (sin tarea específica)
          () {
            final taskIds = tasks.map((t) => t.id).toSet();
            final totalCategoryCards = cardsBox != null
                ? cardsBox.values.where((c) => taskIds.contains(c.tareaId)).length
                : 0;
            final isAllSelected = widget.currentCategoryId == category.id &&
                (widget.currentTaskId == null || widget.currentTaskId!.isEmpty);
            final catColor = Color(category.colorValue);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onMaterialSelected(
                    category.id,
                    category.name,
                    null,
                    'Toda la materia',
                  );
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isAllSelected
                        ? catColor.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAllSelected
                          ? catColor
                          : AppColors.cardBorder,
                      width: isAllSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAllSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isAllSelected
                            ? catColor
                            : AppColors.textTertiary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.all_inclusive_rounded,
                        color: catColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toda la materia',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Estudiar sin tarea específica',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalCategoryCards > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '$totalCategoryCards cards',
                            style: AppTypography.bodySmall.copyWith(
                              color: catColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }(),
          const SizedBox(height: 8),

          Text(
            'Tareas',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No tienes tareas en esta materia.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final numCards = cardsBox != null
                      ? cardsBox.values
                          .where((c) => c.tareaId == task.id)
                          .length
                      : 0;
                  final color = Color(task.priorityColorValue);
                  final isSelected = widget.currentTaskId == task.id;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onMaterialSelected(
                          category.id,
                          category.name,
                          task.id,
                          task.title,
                        );
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD97706).withValues(alpha: 0.12)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD97706)
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (numCards > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '$numCards cards',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-DIÁLOGO 3: TIEMPO DE PREGUNTAS (Estética Imagen 3 con degradado naranja/rojo)
// ═════════════════════════════════════════════════════════════════════════════

class _QuizTimeSelectorDialog extends StatefulWidget {
  final bool currentEnabled;
  final Function(bool) onSelected;

  const _QuizTimeSelectorDialog({
    required this.currentEnabled,
    required this.onSelected,
  });

  @override
  State<_QuizTimeSelectorDialog> createState() =>
      _QuizTimeSelectorDialogState();
}

class _QuizTimeSelectorDialogState extends State<_QuizTimeSelectorDialog> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentEnabled;
  }

  @override
  Widget build(BuildContext context) {
    const orangePrimary = Color(0xFFEA580C);
    const redDark = Color(0xFFDC2626);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header rojo/naranja ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [orangePrimary, redDark],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                'Tiempo de Preguntas',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOption(
                    title: 'Sí (Activado)',
                    description:
                        'Al terminar el tiempo de estudio, se generarán preguntas de repaso para evaluar y reforzar lo aprendido.',
                    value: true,
                    accentColor: orangePrimary,
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    title: 'No (Desactivado)',
                    description:
                        'Sesión continua de estudio sin preguntas de evaluación al finalizar.',
                    value: false,
                    accentColor: orangePrimary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelected(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangePrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String description,
    required bool value,
    required Color accentColor,
  }) {
    final isSelected = _selected == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selected = value);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? accentColor : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? accentColor : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
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

