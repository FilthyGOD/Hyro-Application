import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';
import '../../../../data/models/tarea_nota_model.dart';

class MultipleChoiceQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final List<TareaNotaModel> notas;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;

  const MultipleChoiceQuiz({super.key, required this.flashcards, required this.notas, required this.onAnswer});

  @override
  State<MultipleChoiceQuiz> createState() => _MultipleChoiceQuizState();
}

class _MultipleChoiceQuizState extends State<MultipleChoiceQuiz> {
  String _question = '';
  String _correctAnswer = '';
  List<String> _options = [];
  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final rng = Random();
    if (widget.flashcards.length >= 2) {
      final cards = List<TareaCardModel>.from(widget.flashcards)..shuffle(rng);
      final target = cards.first;
      final askFront = rng.nextBool();
      _question = askFront ? target.frente : target.reverso;
      _correctAnswer = askFront ? target.reverso : target.frente;

      final distractors = <String>[];
      for (final c in cards.skip(1)) {
        final d = askFront ? c.reverso : c.frente;
        if (d != _correctAnswer && !distractors.contains(d)) distractors.add(d);
        if (distractors.length >= 3) break;
      }
      while (distractors.length < 3) {
        distractors.add('—');
      }
      _options = [_correctAnswer, ...distractors]..shuffle(rng);
    } else if (widget.flashcards.isNotEmpty) {
      final card = widget.flashcards.first;
      _question = card.frente;
      _correctAnswer = card.reverso;
      _options = [_correctAnswer, '—', '—', '—']..shuffle(rng);
    }
  }

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _selectedIndex = i;
      _answered = true;
    });
    final correct = _options[i] == _correctAnswer;
    widget.onAnswer(correct, _question, _options[i], _correctAnswer);
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
            color: const Color(0xFF6A25F4).withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_rounded, color: Color(0xFFA855F7), size: 16),
              const SizedBox(width: 6),
              Text('OPCIÓN MÚLTIPLE', style: AppTypography.labelSmall.copyWith(color: const Color(0xFFA855F7))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('¿Cuál es la respuesta correcta?', style: AppTypography.labelSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(_question, style: AppTypography.bodyLarge),
        ),
        const SizedBox(height: 16),
        ...List.generate(_options.length, (i) {
          Color bg = AppColors.surface;
          Color border = AppColors.cardBorder;
          Color textColor = Colors.white;
          if (_answered && i == _selectedIndex) {
            final correct = _options[i] == _correctAnswer;
            bg = correct ? AppColors.breakGreen.withAlpha(50) : const Color(0xFFEF4444).withAlpha(50);
            border = correct ? AppColors.breakGreen : const Color(0xFFEF4444);
          }
          if (_answered && _options[i] == _correctAnswer && i != _selectedIndex) {
            border = AppColors.breakGreen;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _select(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceLight,
                          border: Border.all(color: border),
                        ),
                        child: Center(child: Text(String.fromCharCode(65 + i), style: AppTypography.labelLarge.copyWith(color: textColor, fontSize: 13))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_options[i], style: AppTypography.bodyMedium.copyWith(color: textColor))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
