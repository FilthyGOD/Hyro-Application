import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';

class FlashcardRevealQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;
  final Color subjectColor;

  const FlashcardRevealQuiz({
    super.key,
    required this.flashcards,
    required this.onAnswer,
    this.subjectColor = const Color(0xFF00F2FF),
  });

  @override
  State<FlashcardRevealQuiz> createState() => _FlashcardRevealQuizState();
}

class _FlashcardRevealQuizState extends State<FlashcardRevealQuiz> with SingleTickerProviderStateMixin {
  late TareaCardModel _card;
  late bool _showFront; // true = muestra anverso, pregunta reverso
  final TextEditingController _ctrl = TextEditingController();
  bool _revealed = false;
  bool _isCorrect = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _card = widget.flashcards[rng.nextInt(widget.flashcards.length)];
    _showFront = rng.nextBool();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _check() {
    if (_revealed) return;
    final answer = _ctrl.text.trim().toLowerCase();
    final expected = (_showFront ? _card.reverso : _card.frente).toLowerCase();
    // Comprueba si la respuesta contiene palabras clave (3+ letras)
    final keyWords = expected.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    bool correct;
    if (keyWords.isEmpty) {
      correct = answer == expected;
    } else {
      int matches = keyWords.where((w) => answer.contains(w.replaceAll(RegExp(r'[.,;!?]'), ''))).length;
      correct = matches >= (keyWords.length * 0.5).ceil();
    }
    _isCorrect = correct && answer.isNotEmpty;
    setState(() => _revealed = true);
    _flipController.forward();
    widget.onAnswer(
      _isCorrect,
      _showFront ? _card.frente : _card.reverso,
      answer.isEmpty ? '(sin respuesta)' : answer,
      _showFront ? _card.reverso : _card.frente,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownSide = _showFront ? _card.frente : _card.reverso;
    final hiddenSide = _showFront ? _card.reverso : _card.frente;
    final color = widget.subjectColor;
    final gradientLight = Color.lerp(color, Colors.white, 0.15)!;
    final gradientDark = Color.lerp(color, Colors.black, 0.15)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge centrado
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flip_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text('FLASHCARD', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Texto centrado
        Text(
          _showFront ? '¿Qué hay en el reverso?' : '¿Qué hay en el frente?',
          style: AppTypography.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Visual de la tarjeta
        AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final show = _flipAnimation.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * 3.14159),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF182040), Color(0xFF131829)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 20)],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(show ? 0 : 3.14159),
                  child: Column(
                    children: [
                      Text(
                        show ? (_showFront ? 'FRENTE' : 'REVERSO') : (_showFront ? 'REVERSO' : 'FRENTE'),
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        show ? shownSide : hiddenSide,
                        style: AppTypography.bodyLarge.copyWith(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (!_revealed) ...[
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta...',
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
          const SizedBox(height: 16),
          // Botón Responder con degradado, centrado
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientDark, color, gradientLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _check,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(
                      'Responder',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
