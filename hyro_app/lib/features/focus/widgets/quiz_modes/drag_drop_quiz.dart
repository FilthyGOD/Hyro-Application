import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/tarea_nota_model.dart';

class DragDropQuiz extends StatefulWidget {
  final List<TareaNotaModel> notas;
  final void Function(bool isCorrect, String question, String userAnswer, String correctAnswer) onAnswer;
  final Color subjectColor;

  const DragDropQuiz({super.key, required this.notas, required this.onAnswer, this.subjectColor = const Color(0xFF00F2FF)});

  @override
  State<DragDropQuiz> createState() => _DragDropQuizState();
}

class _DragDropQuizState extends State<DragDropQuiz> {
  String _originalText = '';
  List<String> _blanks = []; // palabras removidas
  List<String> _displayParts = []; // texto dividido con marcadores de posición
  List<String> _availableWords = [];
  final Map<int, String?> _placed = {}; // índice del espacio en blanco -> palabra colocada
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
    final nota = widget.notas[rng.nextInt(widget.notas.length)];
    _originalText = nota.contenido;
    final words = _originalText.split(RegExp(r'\s+'));
    final candidates = words.where((w) => w.length > 3 && w.contains(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]'))).toSet().toList();
    candidates.shuffle(rng);

    final count = min(3, candidates.length);
    _blanks = candidates.take(count).toList();

    // Construye las partes para mostrar
    String text = _originalText;
    for (var w in _blanks) {
      text = text.replaceFirst(w, '{{BLANK}}');
    }
    _displayParts = text.split('{{BLANK}}');

    // Mezcla las palabras disponibles con distractores
    _availableWords = List<String>.from(_blanks);
    // Añade 1-2 distractores de otras palabras
    final distractorPool = candidates.where((w) => !_blanks.contains(w)).toList();
    distractorPool.shuffle(rng);
    _availableWords.addAll(distractorPool.take(min(2, distractorPool.length)));
    _availableWords.shuffle(rng);

    for (int i = 0; i < _blanks.length; i++) {
      _placed[i] = null;
    }
  }

  void _checkAnswer() {
    if (_answered) return;
    bool correct = true;
    for (int i = 0; i < _blanks.length; i++) {
      if (_cleanWord(_placed[i]) != _cleanWord(_blanks[i])) {
        correct = false;
        break;
      }
    }
    _isCorrect = correct;
    setState(() => _answered = true);
    widget.onAnswer(
      _isCorrect,
      _originalText,
      _placed.values.map((w) => w ?? '___').join(', '),
      _blanks.join(', '),
    );
  }

  String? _cleanWord(String? w) => w?.replaceAll(RegExp(r'[.,;!?()"\[\]{}]'), '').toLowerCase();

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
        Text('Coloca las palabras en su lugar correcto:', style: AppTypography.labelSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        // Texto con objetivos para soltar
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
            children: _buildTextWithBlanks(),
          ),
        ),
        const SizedBox(height: 16),
        // Palabras arrastrables
        Text('Palabras disponibles:', style: AppTypography.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableWords.where((w) => !_placed.values.contains(w)).map((word) {
            return Draggable<String>(
              data: word,
              feedback: Material(
                color: Colors.transparent,
                child: _wordChip(word, isDragging: true),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: _wordChip(word)),
              child: _wordChip(word),
            );
          }).toList(),
        ),
        if (!_answered && _placed.values.every((v) => v != null)) ...[
          const SizedBox(height: 16),
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

  List<Widget> _buildTextWithBlanks() {
    final widgets = <Widget>[];
    for (int i = 0; i < _displayParts.length; i++) {
      if (_displayParts[i].isNotEmpty) {
        widgets.add(Text(_displayParts[i], style: AppTypography.bodyLarge));
      }
      if (i < _blanks.length) {
        final blankIndex = i;
        final placedWord = _placed[blankIndex];
        widgets.add(
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              if (_answered) return;
              setState(() {
                // Quítala de cualquier otro espacio en blanco
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
                final correct = _cleanWord(placedWord) == _cleanWord(_blanks[blankIndex]);
                bg = correct ? AppColors.breakGreen.withAlpha(40) : const Color(0xFFEF4444).withAlpha(40);
                border = correct ? AppColors.breakGreen : const Color(0xFFEF4444);
              } else if (isHovering) {
                border = AppColors.primary;
              }
              return GestureDetector(
                onTap: () {
                  if (_answered || placedWord == null) return;
                  setState(() => _placed[blankIndex] = null);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  constraints: const BoxConstraints(minWidth: 60),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border, width: isHovering ? 2 : 1),
                  ),
                  child: Text(
                    placedWord ?? '___',
                    style: AppTypography.bodyLarge.copyWith(
                      color: placedWord != null ? Colors.white : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return widgets;
  }

  Widget _wordChip(String word, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.primary.withAlpha(40) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDragging ? AppColors.primary : AppColors.cardBorder),
        boxShadow: isDragging ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 12)] : null,
      ),
      child: Text(word, style: AppTypography.labelLarge.copyWith(color: Colors.white)),
    );
  }
}
