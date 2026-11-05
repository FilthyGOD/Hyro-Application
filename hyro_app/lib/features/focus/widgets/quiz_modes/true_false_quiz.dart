import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';
import '../../../../data/models/tarea_nota_model.dart';
import '../../utils/quiz_content_helper.dart';

class _StudyPair {
  final String title;
  final String content;

  const _StudyPair({required this.title, required this.content});
}

class TrueFalseQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final List<TareaNotaModel> notas;
  final void Function(
    bool isCorrect,
    String question,
    String userAnswer,
    String correctAnswer,
  )
  onAnswer;
  final Color subjectColor;

  const TrueFalseQuiz({
    super.key,
    required this.flashcards,
    required this.notas,
    required this.onAnswer,
    this.subjectColor = const Color(0xFF00F2FF),
  });

  @override
  State<TrueFalseQuiz> createState() => _TrueFalseQuizState();
}

class _TrueFalseQuizState extends State<TrueFalseQuiz> {
  String _displayedTitle = '';
  String _displayedContent = '';
  bool _isTrue = true;
  bool? _userAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final rng = Random();
    final pairs = <_StudyPair>[];

    // 1. Extraer pares de Tarjetas de estudio (Frente -> Reverso)
    for (final card in widget.flashcards) {
      if (card.frente.trim().isNotEmpty && card.reverso.trim().isNotEmpty) {
        pairs.add(
          _StudyPair(title: card.frente.trim(), content: card.reverso.trim()),
        );
      }
    }

    // 2. Extraer pares de Notas y apuntes (Título -> Texto/Información)
    final parsedNotes =
        widget.notas
            .map(
              (n) => QuizContentHelper.parseNote(
                id: n.id,
                rawContent: n.contenido,
              ),
            )
            .where((n) => n.body.trim().isNotEmpty)
            .toList();

    final preferredNotes =
        parsedNotes
            .where((n) => QuizContentHelper.isPreferredTag(n.tag))
            .toList();

    final eligibleNotes =
        preferredNotes.isNotEmpty ? preferredNotes : parsedNotes;

    for (final note in eligibleNotes) {
      final title =
          note.title ??
          (note.tag != null ? 'Concepto: ${note.tag}' : 'Nota de estudio');
      pairs.add(_StudyPair(title: title, content: note.body));
    }

    if (pairs.isEmpty) return;

    pairs.shuffle(rng);
    final target = pairs.first;

    _isTrue = rng.nextBool();
    if (_isTrue || pairs.length < 2) {
      _displayedTitle = target.title;
      _displayedContent = target.content;
      _isTrue = true;
    } else {
      // Elegir un contenido de otra tarjeta o nota como distractor
      final otherPairs =
          pairs.where((p) => p.content != target.content).toList();
      if (otherPairs.isEmpty) {
        _displayedTitle = target.title;
        _displayedContent = target.content;
        _isTrue = true;
      } else {
        final distractor = otherPairs[rng.nextInt(otherPairs.length)];
        _displayedTitle = target.title;
        _displayedContent = distractor.content;
        _isTrue = false;
      }
    }
  }

  void _answer(bool value) {
    if (_answered) return;
    setState(() {
      _userAnswer = value;
      _answered = true;
    });
    final correct = value == _isTrue;
    final statement = '$_displayedTitle ➔ $_displayedContent';
    widget.onAnswer(
      correct,
      statement,
      value ? 'Verdadero' : 'Falso',
      _isTrue ? 'Verdadero' : 'Falso',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF38BDF8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'VERDADERO O FALSO',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Esta relación es correcta?',
          style: AppTypography.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Tarjeta con primer texto (Título) y segundo texto (Abajo)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              // 1. Título (Frente de card o Título de la nota)
              Text(
                _displayedTitle,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),

              // Separador estilizado
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.cardBorder.withValues(alpha: 0.6),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: widget.subjectColor,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.cardBorder.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Texto de abajo (Reverso de card o Contenido de la nota)
              Text(
                _displayedContent,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Botones de respuesta
        Row(
          children: [
            Expanded(
              child: _buildBtn(true, '✓ Verdadero', AppColors.breakGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBtn(false, '✗ Falso', const Color(0xFFEF4444)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBtn(bool value, String label, Color color) {
    Color bg = AppColors.surface;
    Color border = AppColors.cardBorder;
    if (_answered && _userAnswer == value) {
      final correct = value == _isTrue;
      bg =
          correct
              ? AppColors.breakGreen.withAlpha(50)
              : const Color(0xFFEF4444).withAlpha(50);
      border = correct ? AppColors.breakGreen : const Color(0xFFEF4444);
    }
    if (_answered && value == _isTrue && _userAnswer != value) {
      border = AppColors.breakGreen;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _answer(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
