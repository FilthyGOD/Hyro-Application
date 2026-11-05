import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_nota_model.dart';
import '../../utils/quiz_content_helper.dart';

abstract class _FlowToken {}

class _TextToken extends _FlowToken {
  final String text;
  _TextToken(this.text);
}

class _BlankToken extends _FlowToken {
  final int index;
  final String expectedWord;
  _BlankToken({required this.index, required this.expectedWord});
}

class _NewlineToken extends _FlowToken {}

class DragDropQuiz extends StatefulWidget {
  final List<TareaNotaModel> notas;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;
  final Color subjectColor;

  const DragDropQuiz({
    super.key,
    required this.notas,
    required this.onAnswer,
    this.subjectColor = const Color(0xFF00F2FF),
  });

  @override
  State<DragDropQuiz> createState() => _DragDropQuizState();
}

class _DragDropQuizState extends State<DragDropQuiz> {
  String? _noteTitle;
  String _originalCleanText = '';
  List<String> _blanksInOrder = []; // Palabras que deben ir en los huecos, en orden de texto
  List<_FlowToken> _tokens = [];
  List<String> _availableWords = [];
  final Map<int, String?> _placed = {}; // índice de hueco -> palabra colocada
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final rng = Random();
    if (widget.notas.isEmpty) return;

    // 1. Parsear notas limpias y filtrar por etiquetas preferidas
    final parsedNotes = widget.notas
        .map((n) => QuizContentHelper.parseNote(id: n.id, rawContent: n.contenido))
        .where((n) => n.body.trim().isNotEmpty)
        .toList();

    final preferredNotes = parsedNotes
        .where((n) => QuizContentHelper.isPreferredTag(n.tag))
        .toList();

    final eligibleNotes = preferredNotes.isNotEmpty ? preferredNotes : parsedNotes;
    if (eligibleNotes.isEmpty) return;

    final note = eligibleNotes[rng.nextInt(eligibleNotes.length)];
    _noteTitle = note.title;
    _originalCleanText = note.body;

    // 2. Extraer palabras candidatas válidas del texto limpio (limpiando signos)
    final words = _originalCleanText.split(RegExp(r'\s+'));
    final candidates = words
        .map(QuizContentHelper.cleanWord)
        .where((w) => QuizContentHelper.isEligibleWord(w))
        .toSet()
        .toList();
    candidates.shuffle(rng);

    final count = min(3, candidates.length);
    var selected = candidates.take(count).toList();
    if (selected.isEmpty && words.isNotEmpty) {
      final fallback = words
          .map(QuizContentHelper.cleanWord)
          .firstWhere((w) => w.isNotEmpty, orElse: () => 'palabra');
      selected = [fallback];
    }

    // Ordenar las palabras ocultas según el orden en que aparecen en el texto
    selected.sort((a, b) {
      final posA = _originalCleanText.toLowerCase().indexOf(a.toLowerCase());
      final posB = _originalCleanText.toLowerCase().indexOf(b.toLowerCase());
      return posA.compareTo(posB);
    });

    _blanksInOrder = selected;

    // 3. Tokenizar el texto línea por línea y palabra por palabra
    _tokens = [];
    final remainingBlanks = List<String>.from(_blanksInOrder);
    int blankCounter = 0;

    final lines = _originalCleanText.split('\n');
    for (int l = 0; l < lines.length; l++) {
      final line = lines[l].trim();
      if (l > 0) {
        _tokens.add(_NewlineToken());
      }
      if (line.isEmpty) continue;

      final lineWords = line.split(RegExp(r'\s+'));
      for (final rawWord in lineWords) {
        final clean = QuizContentHelper.cleanWord(rawWord);

        if (remainingBlanks.isNotEmpty &&
            clean.toLowerCase() == remainingBlanks.first.toLowerCase()) {
          remainingBlanks.removeAt(0);

          // Puntuación delantera (ej: '(', '¿')
          final prefixMatch = RegExp(r'^[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9]+').firstMatch(rawWord);
          final prefix = prefixMatch != null ? prefixMatch.group(0)! : '';

          // Puntuación trasera (ej: ')', ',', '.', ';')
          final suffixMatch = RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9]+$').firstMatch(rawWord);
          final suffix = suffixMatch != null ? suffixMatch.group(0)! : '';

          if (prefix.isNotEmpty) {
            _tokens.add(_TextToken(prefix));
          }

          _tokens.add(_BlankToken(index: blankCounter, expectedWord: clean));
          _placed[blankCounter] = null;
          blankCounter++;

          if (suffix.isNotEmpty) {
            _tokens.add(_TextToken(suffix));
          }
        } else {
          _tokens.add(_TextToken(rawWord));
        }
      }
    }

    // 4. Preparar banco de palabras disponibles con distractores limpios
    _availableWords = List<String>.from(_blanksInOrder);
    final distractorPool = candidates.where((w) => !_blanksInOrder.contains(w)).toList();
    distractorPool.shuffle(rng);
    _availableWords.addAll(distractorPool.take(min(2, distractorPool.length)));
    _availableWords.shuffle(rng);
  }

  void _onWordSelected(String word) {
    if (_answered) return;
    // Si ya está colocada, no duplicarla
    if (_placed.values.contains(word)) return;

    // Colocar en el primer hueco vacío
    for (int i = 0; i < _blanksInOrder.length; i++) {
      if (_placed[i] == null) {
        setState(() {
          _placed[i] = word;
        });
        break;
      }
    }
  }

  void _onSlotTapped(int blankIndex) {
    if (_answered) return;
    if (_placed[blankIndex] != null) {
      setState(() {
        _placed[blankIndex] = null;
      });
    }
  }

  void _checkAnswer() {
    if (_answered) return;
    bool correct = true;
    for (int i = 0; i < _blanksInOrder.length; i++) {
      final placedWord = _placed[i];
      final expectedWord = _blanksInOrder[i];
      if (placedWord == null ||
          QuizContentHelper.normalizeToken(placedWord) != QuizContentHelper.normalizeToken(expectedWord)) {
        correct = false;
        break;
      }
    }

    _isCorrect = correct;
    setState(() => _answered = true);

    final expectedAnswerInOrder = _blanksInOrder
        .map(QuizContentHelper.cleanWord)
        .join(', ');

    final userAnswersInOrder = List.generate(
      _blanksInOrder.length,
      (i) => _placed[i] != null ? QuizContentHelper.cleanWord(_placed[i]!) : '___',
    ).join(', ');

    widget.onAnswer(
      _isCorrect,
      _originalCleanText,
      userAnswersInOrder,
      expectedAnswerInOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge superior
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator_rounded, color: Color(0xFFFBBF24), size: 16),
                const SizedBox(width: 6),
                Text('ARRASTRA Y COLOCA', style: AppTypography.labelSmall.copyWith(color: const Color(0xFFFBBF24))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_noteTitle != null && _noteTitle!.isNotEmpty) ...[
          // Título de la nota en un contenedor limpio
          Text('Concepto / Tema:', style: AppTypography.labelSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              _noteTitle!,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],

        Text('Coloca las palabras en su lugar correcto:', style: AppTypography.labelSmall, textAlign: TextAlign.center),
        const SizedBox(height: 10),

        // Contenedor principal de texto con huecos que fluyen naturalmente
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: _buildFlowWidgets(),
          ),
        ),
        const SizedBox(height: 16),

        // Banco de palabras disponibles
        Text(
          'Palabras disponibles (arrastra o toca):',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableWords.map((word) {
            final isPlaced = _placed.values.contains(word);
            if (isPlaced) {
              return Opacity(
                opacity: 0.25,
                child: _wordChip(word),
              );
            }

            return Draggable<String>(
              data: word,
              feedback: Material(
                color: Colors.transparent,
                child: _wordChip(word, isDragging: true),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: _wordChip(word)),
              child: GestureDetector(
                onTap: () => _onWordSelected(word),
                child: _wordChip(word),
              ),
            );
          }).toList(),
        ),

        // Botón Verificar cuando todos los huecos estén llenos
        if (!_answered && _placed.values.every((v) => v != null)) ...[
          const SizedBox(height: 18),
          Builder(
            builder: (context) {
              final color = widget.subjectColor;
              final gradientLight = Color.lerp(color, Colors.white, 0.15)!;
              final gradientDark = Color.lerp(color, Colors.black, 0.15)!;
              return Center(
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
                      onTap: _checkAnswer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Text(
                          'Verificar',
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
              );
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFlowWidgets() {
    return _tokens.map<Widget>((token) {
      if (token is _NewlineToken) {
        return const SizedBox(width: double.infinity, height: 6);
      } else if (token is _TextToken) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
          child: Text(
            token.text,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        );
      } else if (token is _BlankToken) {
        final blankIndex = token.index;
        final placedWord = _placed[blankIndex];

        return DragTarget<String>(
          onAcceptWithDetails: (details) {
            if (_answered) return;
            setState(() {
              _placed.forEach((k, v) {
                if (v == details.data) _placed[k] = null;
              });
              _placed[blankIndex] = details.data;
            });
          },
          builder: (context, candidateData, _) {
            final isHovering = candidateData.isNotEmpty;
            Color bg = AppColors.surface;
            Color border = AppColors.cardBorder;

            if (_answered) {
              final correct = placedWord != null &&
                  QuizContentHelper.normalizeToken(placedWord) ==
                      QuizContentHelper.normalizeToken(_blanksInOrder[blankIndex]);
              bg = correct ? AppColors.breakGreen.withAlpha(50) : const Color(0xFFEF4444).withAlpha(50);
              border = correct ? AppColors.breakGreen : const Color(0xFFEF4444);
            } else if (placedWord != null) {
              bg = const Color(0xFF2563EB).withValues(alpha: 0.35);
              border = const Color(0xFF3B82F6);
            } else if (isHovering) {
              border = AppColors.primary;
            }

            final displayText = placedWord != null
                ? QuizContentHelper.cleanWord(placedWord)
                : '___';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: GestureDetector(
                onTap: () => _onSlotTapped(blankIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 32,
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: border,
                      width: isHovering || placedWord != null ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    widthFactor: 1.0,
                    child: Text(
                      displayText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: placedWord != null ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  Widget _wordChip(String word, {bool isDragging = false}) {
    final clean = QuizContentHelper.cleanWord(word);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.primary.withAlpha(40) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDragging ? AppColors.primary : AppColors.cardBorder),
        boxShadow: isDragging ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 10)] : null,
      ),
      child: Text(
        clean,
        style: AppTypography.labelLarge.copyWith(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
