import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_card_model.dart';
import '../../../../data/models/tarea_nota_model.dart';
import '../../utils/quiz_content_helper.dart';

class FillInBlankQuiz extends StatefulWidget {
  final List<TareaCardModel> flashcards;
  final List<TareaNotaModel> notas;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;
  final Color subjectColor;

  const FillInBlankQuiz({
    super.key,
    required this.flashcards,
    required this.notas,
    required this.onAnswer,
    this.subjectColor = const Color(0xFF00F2FF),
  });

  @override
  State<FillInBlankQuiz> createState() => _FillInBlankQuizState();
}

class _FillInBlankQuizState extends State<FillInBlankQuiz> {
  String _displayText = '';
  String _label = '';
  String? _contextText;
  List<String> _hiddenWordsInOrder = [];
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

    // Parsear notas limpias y filtrar por etiquetas preferidas (Concepto, Examen, Pregunta)
    final parsedNotes = widget.notas
        .map((n) => QuizContentHelper.parseNote(id: n.id, rawContent: n.contenido))
        .where((n) => n.body.isNotEmpty)
        .toList();

    final preferredNotes = parsedNotes
        .where((n) => QuizContentHelper.isPreferredTag(n.tag))
        .toList();

    final eligibleNotes = preferredNotes.isNotEmpty ? preferredNotes : parsedNotes;
    final hasNotes = eligibleNotes.isNotEmpty;

    // Decidir fuente: Tarjetas o Notas
    final useCard = hasCards && (!hasNotes || rng.nextBool());

    if (useCard && hasCards) {
      final card = widget.flashcards[rng.nextInt(widget.flashcards.length)];
      _contextText = card.frente;
      _label = 'Completa el reverso:';
      _prepareText(card.reverso, rng);
    } else if (hasNotes) {
      final note = eligibleNotes[rng.nextInt(eligibleNotes.length)];
      _contextText = note.title;
      _label = 'Completa la nota:';
      _prepareText(note.body, rng);
    }
  }

  void _prepareText(String text, Random rng) {
    final words = text.split(RegExp(r'\s+'));
    final candidates = words.where((w) => QuizContentHelper.isEligibleWord(w)).toSet().toList();
    candidates.shuffle(rng);

    final pickCount = min(rng.nextInt(3) + 1, candidates.length);
    var selected = candidates.take(pickCount).toList();
    if (selected.isEmpty && words.isNotEmpty) {
      final fallback = words.lastWhere(
        (w) => QuizContentHelper.cleanWord(w).isNotEmpty,
        orElse: () => words.last,
      );
      selected = [fallback];
    }

    // Ordenar las palabras ocultas en el orden EXACTO en que aparecen en el texto
    selected.sort((a, b) {
      final posA = text.indexOf(a);
      final posB = text.indexOf(b);
      return posA.compareTo(posB);
    });

    _hiddenWordsInOrder = selected;

    // Reemplazar las palabras ocultas con ___
    _displayText = text;
    for (var w in _hiddenWordsInOrder) {
      _displayText = _displayText.replaceFirst(w, '___');
    }
  }

  void _check() {
    if (_answered) return;
    final rawInput = _ctrl.text.trim();

    // Separar palabras ingresadas por el usuario por comas, guiones o espacios
    final userTokens = rawInput
        .split(RegExp(r'[,;\-\s]+'))
        .map(QuizContentHelper.cleanWord)
        .where((w) => w.isNotEmpty)
        .toList();

    final availableTokens = List<String>.from(userTokens);
    bool correct = userTokens.isNotEmpty && _hiddenWordsInOrder.isNotEmpty;

    // Verificar que todas las palabras esperadas estén presentes sin importar el orden
    for (final expectedWord in _hiddenWordsInOrder) {
      final targetNormalized = QuizContentHelper.normalizeToken(expectedWord);
      final matchIndex = availableTokens.indexWhere((token) {
        return QuizContentHelper.normalizeToken(token) == targetNormalized;
      });

      if (matchIndex != -1) {
        availableTokens.removeAt(matchIndex); // Consumir token
      } else {
        correct = false;
        break;
      }
    }

    // Respuesta esperada limpia y en orden de aparición en el texto
    final expectedAnswerInOrder = _hiddenWordsInOrder
        .map(QuizContentHelper.cleanWord)
        .join(', ');

    setState(() => _answered = true);
    widget.onAnswer(
      correct,
      _displayText,
      rawInput.isEmpty ? '(sin respuesta)' : rawInput,
      expectedAnswerInOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        ),
        const SizedBox(height: 16),
        if (_contextText != null && _contextText!.isNotEmpty) ...[
          // Título / Pregunta arriba
          Text('Título / Concepto:', style: AppTypography.labelSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              _contextText!,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Label centrado
        Text(_label, style: AppTypography.labelSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(_displayText, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
        ),
        if (!_answered) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: _hiddenWordsInOrder.length > 1
                  ? 'Escribe las ${_hiddenWordsInOrder.length} palabras (separadas por comas o espacios)...'
                  : 'Escribe tu respuesta...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.white38),
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
