import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';
import '../../../../data/models/tarea_nota_model.dart';

class FillInBlankQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final List<TareaNotaModel> notas;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;

  const FillInBlankQuiz({super.key, required this.flashcards, required this.notas, required this.onAnswer});

  @override
  State<FillInBlankQuiz> createState() => _FillInBlankQuizState();
}

class _FillInBlankQuizState extends State<FillInBlankQuiz> {
  String _displayText = '';
  String _label = '';
  String? _contextText;
  List<String> _hiddenWords = [];
  final TextEditingController _ctrl = TextEditingController();
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _generate() {
    final rng = Random();
    final hasCards = widget.flashcards.isNotEmpty;
    final hasNotes = widget.notas.isNotEmpty;
    final useCard = hasCards && (!hasNotes || rng.nextBool());

    if (useCard && hasCards) {
      final card = widget.flashcards[rng.nextInt(widget.flashcards.length)];
      _contextText = card.frente;
      _label = 'Completa el reverso:';
      _prepareText(card.reverso, rng);
    } else if (hasNotes) {
      final nota = widget.notas[rng.nextInt(widget.notas.length)];
      _label = 'Completa la nota:';
      _prepareText(nota.contenido, rng);
    }
  }

  void _prepareText(String text, Random rng) {
    final words = text.split(RegExp(r'\s+'));
    final candidates = words.where((w) => w.length > 3 && w.contains(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]'))).toSet().toList();
    candidates.shuffle(rng);
    _hiddenWords = candidates.take(min(rng.nextInt(3) + 1, candidates.length)).toList();
    if (_hiddenWords.isEmpty && words.isNotEmpty) _hiddenWords = [words.last];

    _displayText = text;
    for (var w in _hiddenWords) {
      _displayText = _displayText.replaceFirst(w, '___');
    }
    _hiddenWords = _hiddenWords.map((w) => w.replaceAll(RegExp(r'[.,;!?()"\[\]{}]'), '')).toList();
  }

  void _check() {
    if (_answered) return;
    final answer = _ctrl.text.trim().toLowerCase();
    bool correct = answer.isNotEmpty;
    for (var w in _hiddenWords) {
      if (w.isNotEmpty && !answer.contains(w.toLowerCase())) {
        correct = false;
        break;
      }
    }
    setState(() => _answered = true);
    widget.onAnswer(correct, _displayText, answer.isEmpty ? '(sin respuesta)' : answer, _hiddenWords.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF34D399), size: 16),
              const SizedBox(width: 6),
              Text('COMPLETAR', style: AppTypography.labelSmall.copyWith(color: const Color(0xFF34D399))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_contextText != null) ...[
          Text('Frente de la tarjeta:', style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(_contextText!, style: AppTypography.bodyLarge),
          ),
          const SizedBox(height: 12),
        ],
        Text(_label, style: AppTypography.labelSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(_displayText, style: AppTypography.bodyLarge),
        ),
        if (!_answered) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: _hiddenWords.length > 1 ? 'Escribe las ${_hiddenWords.length} palabras...' : 'Escribe tu respuesta...',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
            style: AppTypography.bodyLarge,
            autofocus: true,
            onSubmitted: (_) => _check(),
          ),
        ],
      ],
    );
  }
}
