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
import '../models/quiz_result_item.dart';
import 'package:rive/rive.dart' hide Animation;
import 'quiz_modes/multiple_choice_quiz.dart';
import 'quiz_modes/true_false_quiz.dart';
import 'quiz_modes/flashcard_reveal_quiz.dart';
import 'quiz_modes/drag_drop_quiz.dart';
import 'quiz_modes/fill_in_blank_quiz.dart';

enum QuizMode { fillInNote, fillInCard, writeCardBack, writeCardFront, multipleChoice, trueFalse, flashcardReveal, dragDrop }

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
  late QuizMode _mode;
  bool _revealed = false;
  bool _isCorrect = false;
  String _resultCorrectAnswer = '';

  @override
  void initState() {
    super.initState();
    _pickMode();
  }

  void _pickMode() {
    final rng = Random();
    final hasCards = widget.flashcards.isNotEmpty;
    final hasNotes = widget.notas.isNotEmpty;
    final has2Cards = widget.flashcards.length >= 2;

    // Construir lista de modos disponibles
    final available = <QuizMode>[];

    // Siempre disponible si tenemos tarjetas o notas
    if (hasCards || hasNotes) {
      available.add(QuizMode.fillInCard);
    }

    // Opción múltiple necesita al menos 2 tarjetas para tener distractores significativos
    if (has2Cards) {
      available.add(QuizMode.multipleChoice);
    }

    // Verdadero/Falso necesita tarjetas
    if (hasCards) {
      available.add(QuizMode.trueFalse);
      available.add(QuizMode.flashcardReveal);
    }

    // Arrastrar y soltar necesita notas
    if (hasNotes) {
      available.add(QuizMode.dragDrop);
    }

    if (available.isEmpty) {
      _mode = QuizMode.fillInCard;
    } else {
      _mode = available[rng.nextInt(available.length)];
    }
  }

  void _onAnswer(bool isCorrect, String question, String userAnswer, String correctAnswer) {
    if (_revealed) return;
    _isCorrect = isCorrect;
    _resultCorrectAnswer = correctAnswer;

    setState(() => _revealed = true);

    String typeLabel;
    switch (_mode) {
      case QuizMode.multipleChoice:
        typeLabel = 'Opción Múltiple';
        break;
      case QuizMode.trueFalse:
        typeLabel = 'Verdadero/Falso';
        break;
      case QuizMode.flashcardReveal:
        typeLabel = 'Flashcard';
        break;
      case QuizMode.dragDrop:
        typeLabel = 'Arrastrar';
        break;
      default:
        typeLabel = 'Completar';
    }

    final item = QuizResultItem(
      id: DateTime.now().millisecondsSinceEpoch,
      questionText: question,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      isCorrect: isCorrect,
      quizType: typeLabel,
    );

    context.read<TimerCubit>().recordQuizResult(isCorrect, item);

    Future.delayed(const Duration(seconds: 4), () {
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                children: [
                  const Icon(Icons.psychology_alt_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Verificación de Enfoque', style: AppTypography.h3)),
                ],
              ),
              const SizedBox(height: 12),
              // Mascota
              Consumer<MascotController>(
                builder: (context, mascot, _) {
                  if (!mascot.isLoaded) return const SizedBox();
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Transform.scale(
                        scale: 1.4,
                        child: Transform.translate(
                          offset: const Offset(0, 8),
                          child: RiveWidget(controller: mascot.controller!, fit: Fit.contain),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Contenido del cuestionario
              _buildQuizContent(),
              const SizedBox(height: 20),
              // Botones de resultado o acción
              if (_revealed)
                _buildResult()
              else
                _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    switch (_mode) {
      case QuizMode.multipleChoice:
        return MultipleChoiceQuiz(
          flashcards: widget.flashcards,
          notas: widget.notas,
          onAnswer: _onAnswer,
        );
      case QuizMode.trueFalse:
        return TrueFalseQuiz(
          flashcards: widget.flashcards,
          onAnswer: _onAnswer,
        );
      case QuizMode.flashcardReveal:
        return FlashcardRevealQuiz(
          flashcards: widget.flashcards,
          onAnswer: _onAnswer,
        );
      case QuizMode.dragDrop:
        return DragDropQuiz(
          notas: widget.notas,
          onAnswer: _onAnswer,
        );
      default:
        return FillInBlankQuiz(
          flashcards: widget.flashcards,
          notas: widget.notas,
          onAnswer: _onAnswer,
        );
    }
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _skip,
          child: Text('Saltar', style: AppTypography.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect ? AppColors.breakGreen.withAlpha(76) : const Color(0xFFEF4444).withAlpha(76),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? AppColors.breakGreen : const Color(0xFFEF4444),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect ? AppColors.breakGreen : const Color(0xFFEF4444),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _isCorrect ? '¡Correcto!' : 'Incorrecto',
            style: AppTypography.h3.copyWith(
              color: _isCorrect ? AppColors.breakGreen : const Color(0xFFEF4444),
            ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 8),
            Text('Respuesta esperada:', style: AppTypography.labelSmall),
            Text(
              _resultCorrectAnswer,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
