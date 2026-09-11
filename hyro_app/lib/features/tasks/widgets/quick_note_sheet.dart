import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/subtask_model.dart';
import '../tasks_provider.dart';

class QuickNoteSheet extends StatefulWidget {
  const QuickNoteSheet({super.key});

  @override
  State<QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends State<QuickNoteSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime? _selectedDate;
  int _selectedColor = 0xFF0095FF; // Default blue

  // Simple list to hold subtask titles as they are being drafted
  final List<TextEditingController> _subtaskControllers = [];

  // Pre-defined colors for the quick color picker
  final List<int> _presetColors = [
    0xFF0095FF, // Blue
    0xFFEF4444, // Red
    0xFF22C55E, // Green
    0xFFF59E0B, // Orange
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    for (var c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final subtasks = _subtaskControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .map((text) => SubTaskModel(id: const Uuid().v4(), title: text))
        .toList();

    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      notes: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      dueDate: _selectedDate,
      priorityColorValue: _selectedColor,
      subtasks: subtasks.isNotEmpty ? subtasks : null,
      priority: 'MEDIUM',
    );

    context.read<TaskProvider>().addTask(task);
    Navigator.pop(context);
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null 
          ? TimeOfDay.fromDateTime(_selectedDate!) 
          : TimeOfDay.now(),
      );
      
      setState(() {
        if (time != null) {
          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        } else {
          _selectedDate = DateTime(date.year, date.month, date.day);
        }
      });
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Elegir un color', style: AppTypography.h3),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColor = color);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: _selectedColor == color
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final dayStr = days[date.weekday - 1];
    final monthStr = months[date.month - 1];
    
    // Check if time is exactly 00:00 (default no-time assumption)
    if (date.hour == 0 && date.minute == 0) {
      return '$dayStr., ${date.day} $monthStr';
    } else {
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final amPm = date.hour >= 12 ? 'p.m.' : 'a.m.';
      final minStr = date.minute.toString().padLeft(2, '0');
      return '$dayStr., ${date.day} $monthStr, $hour:$minStr $amPm';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset > 0 ? bottomInset : 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4D5F9), // Light blue pill
                      foregroundColor: const Color(0xFF0F172A), // Dark text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Input
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.textSecondary, width: 2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: AppTypography.h2.copyWith(fontWeight: FontWeight.normal),
                            decoration: InputDecoration(
                              hintText: 'Agregar título',
                              hintStyle: AppTypography.h2.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Options list
                    _buildOptionRow(
                      icon: Icons.calendar_today_outlined,
                      label: _selectedDate != null ? _formatDate(_selectedDate!) : 'Elegir fecha',
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildOptionRow(
                      icon: Icons.circle,
                      iconColor: Color(_selectedColor),
                      label: 'Elegir un color',
                      onTap: _pickColor,
                    ),
                    const SizedBox(height: 24),
                    
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 16),
                    
                    // Note input
                    TextField(
                      controller: _noteController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Agregar nota',
                        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Subtasks
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.playlist_add_check, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 16),
                        Text('Subtareas', style: AppTypography.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._subtaskControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 36),
                        child: Row(
                          children: [
                            const Icon(Icons.circle_outlined, size: 16, color: AppColors.textTertiary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: AppTypography.bodyMedium,
                                decoration: const InputDecoration(
                                  hintText: 'Subtarea',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                              onPressed: () {
                                setState(() {
                                  _subtaskControllers.removeAt(index);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 24),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _subtaskControllers.add(TextEditingController());
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Agregar subtarea',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
