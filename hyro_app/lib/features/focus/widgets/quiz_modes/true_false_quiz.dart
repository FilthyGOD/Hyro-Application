import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';

class TrueFalseQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;

  const TrueFalseQuiz({super.key, required this.flashcards, required this.onAnswer});

  @override
  State<TrueFalseQuiz> createState() => _TrueFalseQuizState();
}

class _TrueFalseQuizState extends State<TrueFalseQuiz> {
  String _statement = '';
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
    if (widget.flashcards.isEmpty) return;
    final cards = List<TareaCardModel>.from(widget.flashcards)..shuffle(rng);
    final target = cards.first;

    _isTrue = rng.nextBool();
    if (_isTrue || cards.length < 2) {
      _statement = '"${target.frente}" → ${target.reverso}';
      _isTrue = true;
    } else {
      // Elige un reverso incorrecto de otra tarjeta
      final wrong = cards.firstWhere((c) => c.id != target.id, orElse: () => target);
      if (wrong.id == target.id) {
        _statement = '"${target.frente}" → ${target.reverso}';
        _isTrue = true;
      } else {
        _statement = '"${target.frente}" → ${wrong.reverso}';
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
    widget.onAnswer(correct, _statement, value ? 'Verdadero' : 'Falso', _isTrue ? 'Verdadero' : 'Falso');
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
            color: const Color(0xFF0EA5E9).withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF38BDF8), size: 16),
              const SizedBox(width: 6),
              Text('VERDADERO O FALSO', style: AppTypography.labelSmall.copyWith(color: const Color(0xFF38BDF8))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('¿Esta relación es correcta?', style: AppTypography.labelSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(_statement, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildBtn(true, '✓ Verdadero', AppColors.breakGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildBtn(false, '✗ Falso', const Color(0xFFEF4444))),
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
      bg = correct ? AppColors.breakGreen.withAlpha(50) : const Color(0xFFEF4444).withAlpha(50);
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
          child: Text(label, style: AppTypography.labelLarge.copyWith(color: color), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
