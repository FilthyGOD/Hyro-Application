import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/tarea_nota_model.dart';
import '../../../data/models/tarea_card_model.dart';
import '../../../data/models/tarea_fuente_model.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/repositories/source_repository.dart';
import '../../../data/local/note_local_ds.dart';
import '../../../data/local/card_local_ds.dart';
import '../../../data/local/source_local_ds.dart';
import '../../../data/remote/note_remote_ds.dart';
import '../../../data/remote/card_remote_ds.dart';
import '../../../data/remote/source_remote_ds.dart';
import '../../../providers/auth_provider.dart';
import '../tasks_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class TaskDetailsDialog extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _notesController;
  late TextEditingController _newSubtaskController;
  late TextEditingController _chatInputController;

  late TaskModel _currentTask;
  bool _isUploadingDocument = false;
  int _selectedTab = 1; // Start on Chat tab

  // Flashcards state — backed by CardRepository
  final List<TareaCardModel> _flashcards = [];
  late TextEditingController _cardFrontController;
  late TextEditingController _cardBackController;

  // Notes — backed by NoteRepository
  final List<TareaNotaModel> _chatNotes = [];

  // Fuentes (documents) — backed by SourceRepository
  final List<TareaFuenteModel> _fuentes = [];

  late NoteRepository _noteRepo;
  late CardRepository _cardRepo;
  late SourceRepository _sourceRepo;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task.copyWith();
    _notesController = TextEditingController(text: _currentTask.notes ?? '');
    _newSubtaskController = TextEditingController();
    _chatInputController = TextEditingController();
    _cardFrontController = TextEditingController();
    _cardBackController = TextEditingController();

    // Build repositories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final supabaseClient = Supabase.instance.client;
      _noteRepo = NoteRepository(
        local: NoteLocalDataSource(),
        remote: NoteRemoteDataSource(supabaseClient),
        isAuthenticated: () => auth.isAuthenticated,
        getUserId: () => auth.supabaseUserId,
      );
      _cardRepo = CardRepository(
        local: CardLocalDataSource(),
        remote: CardRemoteDataSource(supabaseClient),
        isAuthenticated: () => auth.isAuthenticated,
      );
      _sourceRepo = SourceRepository(
        local: SourceLocalDataSource(),
        remote: SourceRemoteDataSource(supabaseClient),
        isAuthenticated: () => auth.isAuthenticated,
        getUserId: () => auth.supabaseUserId,
      );
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final notes = _noteRepo.getNotesForTask(_currentTask.id);
    final cards = _cardRepo.getCardsForTask(_currentTask.id);
    final sources = _sourceRepo.getSourcesForTask(_currentTask.id);
    if (mounted) {
      setState(() {
        _chatNotes
          ..clear()
          ..addAll(notes);
        _flashcards
          ..clear()
          ..addAll(cards);
        _fuentes
          ..clear()
          ..addAll(sources);
      });
    }

    // Migrate old attached document URLs to TareaFuenteModel
    if (_currentTask.attachedDocumentUrls != null &&
        _currentTask.attachedDocumentUrls!.isNotEmpty) {
      final oldUrls = List<String>.from(_currentTask.attachedDocumentUrls!);
      final auth = context.read<AuthProvider>();
      bool hasMigrated = false;

      for (final url in oldUrls) {
        // Prevent duplicate migration
        if (!_fuentes.any((f) => f.rutaArchivo == url)) {
          final uri = Uri.tryParse(url);
          final originalName = uri?.pathSegments.last.split('_').skip(1).join('_') ?? 'Documento';
          final ext = originalName.contains('.')
              ? originalName.split('.').last.toLowerCase()
              : null;

          final fuente = TareaFuenteModel(
            id: const Uuid().v4(),
            tareaId: _currentTask.id,
            usuarioId: auth.supabaseUserId ?? '',
            nombreArchivo: originalName,
            rutaArchivo: url,
            tipoArchivo: ext,
          );

          await _sourceRepo.addSource(fuente);
          hasMigrated = true;
          if (mounted) {
            setState(() {
              _fuentes.add(fuente);
            });
          }
        }
      }

      if (hasMigrated && mounted) {
        setState(() {
          _currentTask = _currentTask.copyWith(attachedDocumentUrls: []);
        });
        _saveTask();
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newSubtaskController.dispose();
    _chatInputController.dispose();
    _cardFrontController.dispose();
    _cardBackController.dispose();
    super.dispose();
  }

  void _saveTask() {
    // Rebuild notes from chat note models
    final allNotes = _chatNotes.map((n) => n.contenido).join('\n---\n');
    final updated = _currentTask.copyWith(notes: allNotes);
    context.read<TaskProvider>().updateTask(updated);
  }

  // ── Fuentes (Documents) ──────────────────────────────────────────────────

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingDocument = true);

        final file = File(result.files.single.path!);
        final originalName = result.files.single.name;
        final sanitizedName =
            originalName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
        final fuenteId = const Uuid().v4();
        final storageName = '${fuenteId}_$sanitizedName';

        // Determine file extension for tipo_archivo
        final ext = originalName.contains('.')
            ? originalName.split('.').last.toLowerCase()
            : null;

        // Check if user is authenticated — upload to bucket
        final auth = context.read<AuthProvider>();
        String rutaArchivo;

        if (auth.isAuthenticated) {
          // Upload to Supabase Storage bucket
          await Supabase.instance.client.storage
              .from('task_documents')
              .upload(storageName, file);

          rutaArchivo = Supabase.instance.client.storage
              .from('task_documents')
              .getPublicUrl(storageName);
        } else {
          // Guest mode — store local path; will be uploaded during sync
          rutaArchivo = file.path;
        }

        // Create the TareaFuenteModel and persist via repository
        final fuente = TareaFuenteModel(
          id: fuenteId,
          tareaId: _currentTask.id,
          usuarioId: auth.supabaseUserId ?? '',
          nombreArchivo: originalName,
          rutaArchivo: rutaArchivo,
          tipoArchivo: ext,
        );

        await _sourceRepo.addSource(fuente);

        setState(() {
          _fuentes.add(fuente);
        });
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error al subir documento: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  Future<void> _removeDocument(TareaFuenteModel fuente) async {
    try {
      await _sourceRepo.deleteSource(fuente.id);

      // Try to remove file from bucket if it's a remote URL
      if (!fuente.isLocal) {
        try {
          // Extract the storage path from the public URL
          final uri = Uri.tryParse(fuente.rutaArchivo);
          if (uri != null) {
            final segments = uri.pathSegments;
            // URL pattern: .../storage/v1/object/public/task_documents/{file}
            final bucketIdx = segments.indexOf('task_documents');
            if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
              final storagePath = segments.sublist(bucketIdx + 1).join('/');
              await Supabase.instance.client.storage
                  .from('task_documents')
                  .remove([storagePath]);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Could not remove file from bucket: $e');
        }
      }

      setState(() {
        _fuentes.removeWhere((f) => f.id == fuente.id);
      });
    } catch (e) {
      debugPrint('Error removing document: $e');
    }
  }

  // ── Chat (Notes) ────────────────────────────────────────────────────────

  void _sendChatMessage() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    final nota = TareaNotaModel(
      id: const Uuid().v4(),
      tareaId: _currentTask.id,
      usuarioId: '',
      contenido: text,
    );
    _noteRepo.addNote(nota);
    setState(() {
      _chatNotes.add(nota);
    });
    _chatInputController.clear();
    _saveTask();
  }

  void _showEditNoteDialog(int index) {
    final nota = _chatNotes[index];
    final controller = TextEditingController(text: nota.contenido);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Editar Nota', style: AppTypography.labelLarge),
          content: TextField(
            controller: controller,
            maxLines: null,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: () {
                final newText = controller.text.trim();
                if (newText.isNotEmpty && newText != nota.contenido) {
                  final updatedNota = nota.copyWith(contenido: newText);
                  _noteRepo.updateNote(updatedNota);
                  setState(() {
                    _chatNotes[index] = updatedNota;
                  });
                  _saveTask();
                }
                Navigator.pop(context);
              },
              child: Text('Guardar', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  // ── Cards (Flashcards) ──────────────────────────────────────────────────

  void _addFlashcard() {
    final front = _cardFrontController.text.trim();
    final back = _cardBackController.text.trim();
    if (front.isEmpty || back.isEmpty) return;

    final card = TareaCardModel(
      id: const Uuid().v4(),
      tareaId: _currentTask.id,
      frente: front,
      reverso: back,
    );
    _cardRepo.addCard(card);
    setState(() {
      _flashcards.add(card);
      _cardFrontController.clear();
      _cardBackController.clear();
    });
  }

  void _removeFlashcard(int index) {
    final card = _flashcards[index];
    _cardRepo.deleteCard(card.id);
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  IconData _iconForExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description;
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return Icons.slideshow;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Color _colorForExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return const Color(0xFFEF4444);
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return const Color(0xFF3B82F6);
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return const Color(0xFFF59E0B);
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return const Color(0xFF22C55E);
    return AppColors.textSecondary;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(),

              // ── Tab content ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildTabContent(),
                ),
              ),

              // ── Bottom Navigation ──
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Activity icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTask.title,
                  style: AppTypography.labelLarge.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentTask.category ?? 'Sin categoría',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () {
              _saveTask();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ── TAB CONTENT ─────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildFuentesTab();
      case 1:
        return _buildChatTab();
      case 2:
        return _buildCardsTab();
      default:
        return _buildChatTab();
    }
  }

  // ── FUENTES TAB ─────────────────────────────────────────────────────────

  Widget _buildFuentesTab() {
    return Padding(
      key: const ValueKey('fuentes'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload button
          _buildUploadArea(),
          const SizedBox(height: 16),

          // File count
          Row(
            children: [
              Icon(Icons.folder_open_rounded,
                  color: AppColors.textTertiary, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_fuentes.length} fuente${_fuentes.length != 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document list
          Expanded(
            child: _fuentes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.source_rounded,
                            color: AppColors.textTertiary.withAlpha(100),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Sube PDFs, Word u otros archivos\npara usar como fuentes de estudio.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _fuentes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildDocumentCard(_fuentes[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _isUploadingDocument ? null : _pickAndUploadDocument,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isUploadingDocument
                ? AppColors.primary.withAlpha(120)
                : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploadingDocument) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text('Subiendo...', style: AppTypography.bodyMedium),
            ] else ...[
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Agregar fuente',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(TareaFuenteModel fuente) {
    final fileName = fuente.nombreArchivo.isNotEmpty
        ? fuente.nombreArchivo
        : 'Documento';
    final icon = _iconForExtension(fileName);
    final color = _colorForExtension(fileName);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final url = fuente.rutaArchivo;
                if (fuente.isLocal) {
                  // Open local file
                  final localUri = Uri.file(url);
                  if (await canLaunchUrl(localUri)) {
                    await launchUrl(localUri);
                  }
                } else {
                  // Open remote URL
                  final remoteUri = Uri.parse(url);
                  if (await canLaunchUrl(remoteUri)) {
                    await launchUrl(remoteUri);
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fuente.isLocal ? 'Archivo local' : 'Toca para abrir',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.textTertiary,
            onPressed: () => _removeDocument(fuente),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── NOTAS TAB ───────────────────────────────────────────────────────────

  Widget _buildChatTab() {
    return Padding(
      key: const ValueKey('chat'),
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Messages area
          Expanded(
            child: _chatNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.textTertiary.withAlpha(100),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Escribe notas, apuntes o detalles\nsobre esta actividad.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _chatNotes.length,
                    itemBuilder: (context, index) =>
                        _buildChatBubble(_chatNotes[index].contenido, index),
                  ),
          ),

          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Las notas se guardan automáticamente.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ),

          // Input area
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy button
                  _chatActionIcon(Icons.copy_rounded, () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nota copiada'), duration: Duration(seconds: 2)),
                      );
                    }
                  }),
                  const SizedBox(width: 8),
                  // Edit button
                  _chatActionIcon(Icons.edit_rounded, () => _showEditNoteDialog(index)),
                  const SizedBox(width: 8),
                  // Delete button
                  _chatActionIcon(Icons.delete_outline_rounded, () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text('Eliminar nota', style: AppTypography.labelLarge),
                        content: Text('¿Estás seguro de que deseas eliminar esta nota?', style: AppTypography.bodyMedium),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              final nota = _chatNotes[index];
                              _noteRepo.deleteNote(nota.id);
                              setState(() {
                                _chatNotes.removeAt(index);
                              });
                              _saveTask();
                            },
                            child: Text('Eliminar', style: AppTypography.labelLarge.copyWith(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 16, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatInputController,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Escribe una nota...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendChatMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendChatMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── CARDS TAB ───────────────────────────────────────────────────────────

  Widget _buildCardsTab() {
    return Padding(
      key: const ValueKey('cards'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card creator
          _buildCardCreator(),
          const SizedBox(height: 16),

          // Card count
          Row(
            children: [
              Icon(Icons.style_rounded,
                  color: AppColors.textTertiary, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_flashcards.length} card${_flashcards.length != 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Flashcard list
          Expanded(
            child: _flashcards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style_outlined,
                            color:
                                AppColors.textTertiary.withAlpha(100),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Crea tarjetas de estudio para\nrepasar el contenido de esta actividad.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _flashcards.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildFlashcardTile(index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCreator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nueva Card',
            style: AppTypography.labelLarge.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardFrontController,
            style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary),
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'Frente — Pregunta o concepto',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cardBackController,
            style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary),
            maxLines: 2,
            maxLength: 150,
            decoration: InputDecoration(
              hintText: 'Reverso — Respuesta o definición',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _addFlashcard,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Crear',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardTile(int index) {
    final card = _flashcards[index];
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => FlashcardPreviewDialog(
            cards: _flashcards,
            initialIndex: index,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(40),
                    AppColors.primaryDark.withAlpha(40),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.style_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.frente,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.reverso,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textTertiary,
              onPressed: () => _removeFlashcard(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }



  // ── BOTTOM NAVIGATION BAR ──────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.source_rounded,
            label: 'Fuentes',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.chat_rounded,
            label: 'Notas',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.style_rounded,
            label: 'Cards',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardPreviewDialog extends StatefulWidget {
  final List<TareaCardModel> cards;
  final int initialIndex;

  const FlashcardPreviewDialog({
    super.key,
    required this.cards,
    required this.initialIndex,
  });

  @override
  State<FlashcardPreviewDialog> createState() => _FlashcardPreviewDialogState();
}

class _FlashcardPreviewDialogState extends State<FlashcardPreviewDialog> {
  late int _currentIndex;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final card = widget.cards[_currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showBack = !_showBack;
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey(_showBack),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _showBack
                            ? [
                                const Color(0xFF0F2744),
                                const Color(0xFF0A1A33),
                              ]
                            : [
                                const Color(0xFF182040),
                                const Color(0xFF131829),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showBack
                            ? AppColors.primary.withAlpha(80)
                            : AppColors.cardBorder,
                      ),
                      boxShadow: _showBack
                          ? AppColors.glowShadow(AppColors.primary, blur: 16)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showBack ? 'REVERSO' : 'FRENTE',
                          style: AppTypography.labelSmall.copyWith(
                            color: _showBack
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                _showBack ? card.reverso : card.frente,
                                textAlign: TextAlign.center,
                                style: AppTypography.h3.copyWith(
                                  fontSize: 18,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toca para voltear',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0
                            ? () => setState(() {
                                  _currentIndex--;
                                  _showBack = false;
                                })
                            : null,
                        icon: Icon(Icons.chevron_left_rounded,
                            color: _currentIndex > 0
                                ? AppColors.primary
                                : AppColors.textTertiary),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.cards.length}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentIndex < widget.cards.length - 1
                            ? () => setState(() {
                                  _currentIndex++;
                                  _showBack = false;
                                })
                            : null,
                        icon: Icon(Icons.chevron_right_rounded,
                            color: _currentIndex < widget.cards.length - 1
                                ? AppColors.primary
                                : AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
