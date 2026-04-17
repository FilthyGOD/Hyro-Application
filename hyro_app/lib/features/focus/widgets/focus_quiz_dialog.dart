import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tarea_card_model.dart';
import '../../../data/models/tarea_nota_model.dart';
import '../bloc/timer_cubit.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../mascot/mascot_controller.dart';
import 'package:rive/rive.dart' hide Animation;

class FocusQuizDialog extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final List<TareaNotaModel> notas;

  const FocusQuizDialog({
    super.key,
    required this.flashcards,
    required this.notas,
  });

  @override
  State<FocusQuizDialog> createState() => _FocusQuizDialogState();
}

class _FocusQuizDialogState extends State<FocusQuizDialog> {
  late bool _isFlashcard;
  TareaCardModel? _selectedCard;
  TareaNotaModel? _selectedNote;
  List<String> _hiddenWords = [];
  String? _displayText;
  int _difficulty = 1;

  final TextEditingController _inputController = TextEditingController();
  bool _revealed = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _pickQuestion();
  }

  void _pickQuestion() {
    final random = Random();
    final hasCards = widget.flashcards.isNotEmpty;
    final hasNotes = widget.notas.isNotEmpty;

    _difficulty = random.nextInt(3) + 1;

    if (hasCards && hasNotes) {
      _isFlashcard = random.nextBool();
    } else {
      _isFlashcard = hasCards;
    }

    if (_isFlashcard && hasCards) {
      _selectedCard =
          widget.flashcards[random.nextInt(widget.flashcards.length)];
      _prepareFillInTheBlanks(_selectedCard!.reverso);
    } else if (hasNotes) {
      _selectedNote = widget.notas[random.nextInt(widget.notas.length)];
      _prepareFillInTheBlanks(_selectedNote!.contenido);
    }
  }

  void _prepareFillInTheBlanks(String text) {
    final words = text.split(RegExp(r'\s+'));
    final candidateWords = words
        .where((w) => w.length > 3 && w.contains(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]')))
        .toList();

    _hiddenWords.clear();

    if (candidateWords.isEmpty) {
      if (words.isNotEmpty) {
        _hiddenWords.add(words.last);
      } else {
        _hiddenWords.add('');
      }
    } else {
      final distinctCandidates = candidateWords.toSet().toList();
      distinctCandidates.shuffle();

      int wordsToHide = min(_difficulty, distinctCandidates.length);
      _hiddenWords = distinctCandidates.take(wordsToHide).toList();
    }

    _displayText = text;
    for (var word in _hiddenWords) {
      _displayText = _displayText!.replaceFirst(word, '___');
    }

    _hiddenWords = _hiddenWords
        .map((w) => w.replaceAll(RegExp(r'[.,;!?()"\[\]{}]'), ''))
        .toList();
  }

  void _checkAnswer() {
    if (_revealed) return;

    final answer = _inputController.text.trim().toLowerCase();
    
    bool allCorrect = true;
    for (var word in _hiddenWords) {
      if (word.isNotEmpty && !answer.contains(word.toLowerCase())) {
        allCorrect = false;
        break;
      }
    }
    _isCorrect = answer.isNotEmpty && allCorrect;

    setState(() {
      _revealed = true;
    });

    context.read<TimerCubit>().recordQuizResult(_isCorrect);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        context.read<TimerCubit>().acknowledgeQuiz();
      }
    });
  }

  void _skip() {
    context.read<TimerCubit>().acknowledgeQuiz();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCard == null && _selectedNote == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text('Verificación de Enfoque', style: AppTypography.h3),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<MascotController>(
              builder: (context, mascot, _) {
                if (!mascot.isLoaded) return const SizedBox();
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.5,
                      child: Transform.translate(
                         offset: const Offset(0, 10),
                         child: RiveWidget(
                           controller: mascot.controller!,
                           fit: Fit.contain,
                         ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            if (_isFlashcard) ...[
              Text('Frente de la tarjeta:', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  _selectedCard!.frente,
                  style: AppTypography.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
              Text('Completa el reverso:', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(_displayText ?? '', style: AppTypography.bodyLarge),
              ),
            ] else ...[
              Text('Completa la nota:', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(_displayText ?? '', style: AppTypography.bodyLarge),
              ),
            ],

            const SizedBox(height: 24),

            if (!_revealed) ...[
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: _hiddenWords.length > 1
                      ? 'Escribe las ${_hiddenWords.length} palabras...'
                      : 'Escribe tu respuesta...',
                  hintStyle: AppTypography.bodyMedium,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: AppTypography.bodyLarge,
                autofocus: true,
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text('Saltar', style: AppTypography.bodyMedium),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Responder',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _isCorrect
                          ? AppColors.breakGreen.withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _isCorrect
                            ? AppColors.breakGreen
                            : const Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color:
                          _isCorrect
                              ? AppColors.breakGreen
                              : const Color(0xFFEF4444),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isCorrect ? '¡Correcto!' : 'Incorrecto',
                      style: AppTypography.h3.copyWith(
                        color:
                            _isCorrect
                                ? AppColors.breakGreen
                                : const Color(0xFFEF4444),
                      ),
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Respuesta esperada:',
                        style: AppTypography.labelSmall,
                      ),
                      Text(
                        _hiddenWords.join(', '),
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
