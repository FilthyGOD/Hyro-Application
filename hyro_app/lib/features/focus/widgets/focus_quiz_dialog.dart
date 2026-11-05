import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../data/models/tarea_card_model.dart';
import '../../../data/models/tarea_nota_model.dart';
import '../providers/focus_provider.dart';
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
  final Color subjectColor;

  const FocusQuizDialog({
    super.key,
    required this.flashcards,
    required this.notas,
    this.subjectColor = const Color(0xFF00F2FF),
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

    // Verdadero/Falso (Tarjetas de estudio y Notas)
    if (hasCards || hasNotes) {
      available.add(QuizMode.trueFalse);
    }

    if (hasCards) {
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

    context.read<FocusProvider>().recordQuizResult(isCorrect, item);

    final mascot = context.read<MascotController>();
    if (isCorrect) {
      mascot.triggerFestejo();
    } else {
      mascot.triggerPensando();
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pop(context);
        context.read<FocusProvider>().acknowledgeQuiz();
      }
    });
  }

  void _skip() {
    context.read<FocusProvider>().acknowledgeQuiz();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.subjectColor;
    final gradientLight = Color.lerp(color, Colors.white, 0.15)!;
    final gradientDark = Color.lerp(color, Colors.black, 0.25)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo ambiental animado
          const Positioned.fill(child: AnimatedBackground()),

          Column(
            children: [
              // ── Barra Superior con degradado del color de la materia (diseño original) ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientDark, color, gradientLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_alt_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Verificación de Enfoque',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Contenido Principal Scrollable y Centrado ──
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mascota Hero
                            Consumer<MascotController>(
                              builder: (context, mascot, _) {
                                if (!mascot.isLoaded) return const SizedBox(height: 110);
                                return SizedBox(
                                  height: 130,
                                  child: Center(
                                    child: Transform.scale(
                                      scale: 1.45,
                                      child: Transform.translate(
                                        offset: const Offset(0, 8),
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
                            const SizedBox(height: 20),

                            // Contenido del cuestionario
                            _buildQuizContent(),
                            const SizedBox(height: 24),

                            // Botones de resultado o acción
                            if (_revealed)
                              _buildResult()
                            else
                              _buildActions(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          notas: widget.notas,
          onAnswer: _onAnswer,
          subjectColor: widget.subjectColor,
        );
      case QuizMode.flashcardReveal:
        return FlashcardRevealQuiz(
          flashcards: widget.flashcards,
          onAnswer: _onAnswer,
          subjectColor: widget.subjectColor,
        );
      case QuizMode.dragDrop:
        return DragDropQuiz(
          notas: widget.notas,
          onAnswer: _onAnswer,
          subjectColor: widget.subjectColor,
        );
      default:
        return FillInBlankQuiz(
          flashcards: widget.flashcards,
          notas: widget.notas,
          onAnswer: _onAnswer,
          subjectColor: widget.subjectColor,
        );
    }
  }

  Widget _buildActions() {
    final color = widget.subjectColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Saltar
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _skip,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Text(
                  'Saltar',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
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
