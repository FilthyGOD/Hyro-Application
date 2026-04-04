import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/subtask_model.dart';
import '../tasks_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class TaskDetailsDialog extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  late TextEditingController _notesController;
  late TextEditingController _newSubtaskController;

  late TaskModel _currentTask;
  bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task.copyWith();
    _notesController = TextEditingController(text: _currentTask.notes ?? '');
    _newSubtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final updated = _currentTask.copyWith(notes: _notesController.text.trim());
    context.read<TaskProvider>().updateTask(updated);
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingDocument = true);

        final file = File(result.files.single.path!);
        final rawFileName = result.files.single.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
        final fileName = '${const Uuid().v4()}_$rawFileName';

        // Usa un bucket 'task_documents'. Debe estar creado en Supabase y ser público.
        await Supabase.instance.client.storage
            .from('task_documents')
            .upload(fileName, file);

        final publicUrl = Supabase.instance.client.storage
            .from('task_documents')
            .getPublicUrl(fileName);

        final urls = List<String>.from(_currentTask.attachedDocumentUrls ?? []);
        urls.add(publicUrl);

        setState(() {
          _currentTask = _currentTask.copyWith(attachedDocumentUrls: urls);
        });
        _saveTask();
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: Asegúrate de tener el bucket "task_documents" en Supabase. Detalles: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  void _addSubtask() {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;

    final st = SubTaskModel(
      id: const Uuid().v4(),
      title: title,
    );

    final subtasks = List<SubTaskModel>.from(_currentTask.subtasks ?? []);
    subtasks.add(st);

    setState(() {
      _currentTask = _currentTask.copyWith(subtasks: subtasks);
    });
    _saveTask();
    _newSubtaskController.clear();
  }

  void _toggleSubtask(int index) {
    final subtasks = List<SubTaskModel>.from(_currentTask.subtasks ?? []);
    final st = subtasks[index];
    subtasks[index] = st.copyWith(isCompleted: !st.isCompleted);

    setState(() {
      _currentTask = _currentTask.copyWith(subtasks: subtasks);
    });
    _saveTask();
  }

  void _removeDocument(String url) {
    final urls = List<String>.from(_currentTask.attachedDocumentUrls ?? []);
    urls.remove(url);
    setState(() {
      _currentTask = _currentTask.copyWith(attachedDocumentUrls: urls);
    });
    _saveTask();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentTask.title,
                      style: AppTypography.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _saveTask();
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              const Divider(color: AppColors.cardBorder, height: 32),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notes Section
                      Text('Notas y Detalles', style: AppTypography.h3.copyWith(fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Agrega información sobre esta tarea...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: AppTypography.bodyMedium,
                        onChanged: (_) => _saveTask(),
                      ),
                      const SizedBox(height: 24),

                      // Subtasks Section
                      Text('Sub-tareas', style: AppTypography.h3.copyWith(fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_currentTask.subtasks != null && _currentTask.subtasks!.isNotEmpty)
                        ..._currentTask.subtasks!.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final st = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleSubtask(idx),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: st.isCompleted ? AppColors.primary : Colors.transparent,
                                      border: Border.all(
                                        color: st.isCompleted ? AppColors.primary : AppColors.textSecondary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: st.isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    st.title,
                                    style: AppTypography.bodyMedium.copyWith(
                                      decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                                      color: st.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newSubtaskController,
                              decoration: InputDecoration(
                                hintText: 'Nueva sub-tarea...',
                                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              style: AppTypography.bodyMedium,
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            onPressed: _addSubtask,
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Documents Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Documentos Adjuntos', style: AppTypography.h3.copyWith(fontSize: 16)),
                          if (_isUploadingDocument)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            TextButton.icon(
                              onPressed: _pickAndUploadDocument,
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('Subir'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_currentTask.attachedDocumentUrls == null || _currentTask.attachedDocumentUrls!.isEmpty)
                        Text(
                          'No hay documentos adjuntos.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        )
                      else
                        ..._currentTask.attachedDocumentUrls!.map((url) {
                          // Extract file name from url roughly
                          final uri = Uri.tryParse(url);
                          final fileName = uri?.pathSegments.last.split('_').skip(1).join('_') ?? 'Documento';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    child: Text(
                                      fileName,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryLight,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                                  onPressed: () => _removeDocument(url),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
