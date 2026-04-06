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
import '../../../data/models/tarea_nota_model.dart';
import '../../../data/models/tarea_card_model.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/local/note_local_ds.dart';
import '../../../data/local/card_local_ds.dart';
import '../../../data/remote/note_remote_ds.dart';
import '../../../data/remote/card_remote_ds.dart';
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

  // Flashcard state — backed by CardRepository
  final List<TareaCardModel> _flashcards = [];
  late TextEditingController _cardFrontController;
  late TextEditingController _cardBackController;
  int? _previewIndex;
  bool _previewShowBack = false;

  // Notes — backed by NoteRepository
  final List<TareaNotaModel> _chatNotes = [];

  late NoteRepository _noteRepo;
  late CardRepository _cardRepo;

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
      _loadNotesAndCards();
    });
  }

  void _loadNotesAndCards() {
    final notes = _noteRepo.getNotesForTask(_currentTask.id);
    final cards = _cardRepo.getCardsForTask(_currentTask.id);
    if (mounted) {
      setState(() {
        _chatNotes
          ..clear()
          ..addAll(notes);
        _flashcards
          ..clear()
          ..addAll(cards);
      });
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
        final rawFileName =
            result.files.single.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
        final fileName = '${const Uuid().v4()}_$rawFileName';

        await Supabase.instance.client.storage
            .from('task_documents')
            .upload(fileName, file);

        final publicUrl = Supabase.instance.client.storage
            .from('task_documents')
            .getPublicUrl(fileName);

        final urls =
            List<String>.from(_currentTask.attachedDocumentUrls ?? []);
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
            content: Text(
                'Error al subir documento: Asegúrate de tener el bucket "task_documents" en Supabase. Detalles: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  void _removeDocument(String url) {
    final urls =
        List<String>.from(_currentTask.attachedDocumentUrls ?? []);
    urls.remove(url);
    setState(() {
      _currentTask = _currentTask.copyWith(attachedDocumentUrls: urls);
    });
    _saveTask();
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
      if (_previewIndex == index) {
        _previewIndex = null;
        _previewShowBack = false;
      }
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
    final docs = _currentTask.attachedDocumentUrls ?? [];

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
                '${docs.length} fuente${docs.length != 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document list
          Expanded(
            child: docs.isEmpty
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
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildDocumentCard(docs[index]),
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

  Widget _buildDocumentCard(String url) {
    final uri = Uri.tryParse(url);
    final fileName =
        uri?.pathSegments.last.split('_').skip(1).join('_') ?? 'Documento';
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
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
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
                    'Toca para abrir',
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
            onPressed: () => _removeDocument(url),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── CHAT TAB ────────────────────────────────────────────────────────────

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
                  _chatActionIcon(Icons.copy_rounded, () {
                    // Copy to clipboard
                  }),
                  const SizedBox(width: 8),
                  // Delete button
                  _chatActionIcon(Icons.delete_outline_rounded, () {
                    final nota = _chatNotes[index];
                    _noteRepo.deleteNote(nota.id);
                    setState(() {
                      _chatNotes.removeAt(index);
                    });
                    _saveTask();
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

          // Flashcard list / preview
          Expanded(
            child: _previewIndex != null
                ? _buildCardPreview()
                : _flashcards.isEmpty
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
        setState(() {
          _previewIndex = index;
          _previewShowBack = false;
        });
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

  Widget _buildCardPreview() {
    final card = _flashcards[_previewIndex!];
    return Column(
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() {
              _previewIndex = null;
              _previewShowBack = false;
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Volver a la lista',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _previewShowBack = !_previewShowBack;
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Container(
                key: ValueKey(_previewShowBack),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _previewShowBack
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
                    color: _previewShowBack
                        ? AppColors.primary.withAlpha(80)
                        : AppColors.cardBorder,
                  ),
                  boxShadow: _previewShowBack
                      ? AppColors.glowShadow(AppColors.primary, blur: 16)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _previewShowBack ? 'REVERSO' : 'FRENTE',
                      style: AppTypography.labelSmall.copyWith(
                        color: _previewShowBack
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _previewShowBack ? card.reverso : card.frente,
                      textAlign: TextAlign.center,
                      style: AppTypography.h3.copyWith(
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
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

        const SizedBox(height: 12),

        // Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _previewIndex! > 0
                  ? () => setState(() {
                        _previewIndex = _previewIndex! - 1;
                        _previewShowBack = false;
                      })
                  : null,
              icon: Icon(Icons.chevron_left_rounded,
                  color: _previewIndex! > 0
                      ? AppColors.primary
                      : AppColors.textTertiary),
            ),
            Text(
              '${_previewIndex! + 1} / ${_flashcards.length}',
              style: AppTypography.bodySmall,
            ),
            IconButton(
              onPressed: _previewIndex! < _flashcards.length - 1
                  ? () => setState(() {
                        _previewIndex = _previewIndex! + 1;
                        _previewShowBack = false;
                      })
                  : null,
              icon: Icon(Icons.chevron_right_rounded,
                  color: _previewIndex! < _flashcards.length - 1
                      ? AppColors.primary
                      : AppColors.textTertiary),
            ),
          ],
        ),
      ],
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
            label: 'Chat',
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
