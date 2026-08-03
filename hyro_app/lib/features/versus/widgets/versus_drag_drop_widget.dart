import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VersusDragDropWidget extends StatefulWidget {
  final String textWithBlanks;
  final List<String> originalBlanks;
  final List<String> availableWords;
  final bool answered;
  final void Function(bool isCorrect, String answerText) onVerify;
  final Color subjectColor;

  const VersusDragDropWidget({
    super.key,
    required this.textWithBlanks,
    required this.originalBlanks,
    required this.availableWords,
    required this.answered,
    required this.onVerify,
    this.subjectColor = const Color(0xFF00F2FF),
  });

  @override
  State<VersusDragDropWidget> createState() => _VersusDragDropWidgetState();
}

class _VersusDragDropWidgetState extends State<VersusDragDropWidget> {
  List<String> _displayParts = [];
  final Map<int, String?> _placed = {};

  @override
  void initState() {
    super.initState();
    _initParts();
  }

  @override
  void didUpdateWidget(covariant VersusDragDropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textWithBlanks != widget.textWithBlanks) {
      _initParts();
    }
  }

  void _initParts() {
    _displayParts = widget.textWithBlanks.split('{{BLANK}}');
    _placed.clear();
    for (int i = 0; i < widget.originalBlanks.length; i++) {
      _placed[i] = null;
    }
  }

  void _checkAnswer() {
    if (widget.answered) return;
    bool correct = true;
    for (int i = 0; i < widget.originalBlanks.length; i++) {
      if (_cleanWord(_placed[i]) != _cleanWord(widget.originalBlanks[i])) {
        correct = false;
        break;
      }
    }
    
    final answerText = List.generate(widget.originalBlanks.length, (i) => _placed[i] ?? '_').join(', ');
    widget.onVerify(correct, answerText);
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
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
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
          children: widget.availableWords.where((w) => !_placed.values.contains(w)).map((word) {
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
        if (!widget.answered && _placed.values.every((v) => v != null)) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'VERIFICAR',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
      if (i < widget.originalBlanks.length) {
        final blankIndex = i;
        final placedWord = _placed[blankIndex];
        widgets.add(
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              if (widget.answered) return;
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
              if (widget.answered) {
                final correct = _cleanWord(placedWord) == _cleanWord(widget.originalBlanks[blankIndex]);
                bg = correct ? AppColors.breakGreen.withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15);
                border = correct ? AppColors.breakGreen : const Color(0xFFEF4444);
              } else if (isHovering) {
                border = AppColors.primary;
              }
              return GestureDetector(
                onTap: () {
                  if (widget.answered || placedWord == null) return;
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
                      color: placedWord != null ? AppColors.textPrimary : AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Text(
        word,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
