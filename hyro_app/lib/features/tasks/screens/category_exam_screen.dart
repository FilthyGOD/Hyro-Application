import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tarea_card_model.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/local/card_local_ds.dart';
import '../../../data/remote/card_remote_ds.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../versus/models/versus_models.dart';

class CategoryExamScreen extends StatefulWidget {
  final List<String> taskIds;
  final String categoryName;

  const CategoryExamScreen({
    super.key,
    required this.taskIds,
    required this.categoryName,
  });

  @override
  State<CategoryExamScreen> createState() => _CategoryExamScreenState();
}

class _CategoryExamScreenState extends State<CategoryExamScreen> {
  int _currentQuestionIndex = 0;
  List<VersusQuestion> _questions = [];
  bool _isLoadingQuestions = true;
  String? _loadError;

  int? _selectedAnswerIndex;
  bool _answered = false;

  int _correctAnswers = 0;
  List<bool> _answerResults = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    try {
      final auth = context.read<AuthProvider>();
      final supabaseClient = Supabase.instance.client;
      final cardRepo = CardRepository(
        local: CardLocalDataSource(),
        remote: CardRemoteDataSource(supabaseClient),
        isAuthenticated: () => auth.isAuthenticated,
      );

      final List<TareaCardModel> allCards = [];
      for (final taskId in widget.taskIds) {
        final cards = cardRepo.getCardsForTask(taskId);
        allCards.addAll(cards);
      }

      if (allCards.isEmpty) {
        setState(() {
          _loadError = 'No hay suficientes apuntes/tarjetas en las tareas seleccionadas para generar el examen.';
          _isLoadingQuestions = false;
        });
        return;
      }

      // Generar 10 preguntas (o la cantidad de tarjetas que haya, lo que sea menor)
      final rng = Random();
      allCards.shuffle(rng);
      final questionCount = min(10, allCards.length);

      final generated = <VersusQuestion>[];

      for (int i = 0; i < questionCount; i++) {
        final target = allCards[i];
        final askFront = rng.nextBool();
        final questionText = askFront ? target.frente : target.reverso;
        final correctAnswer = askFront ? target.reverso : target.frente;

        final distractors = <String>[];
        for (final c in allCards) {
          if (c.id == target.id) continue;
          final d = askFront ? c.reverso : c.frente;
          if (d != correctAnswer && !distractors.contains(d)) distractors.add(d);
          if (distractors.length >= 3) break;
        }

        while (distractors.length < 3) {
          distractors.add('—');
        }
        
        final options = [correctAnswer, ...distractors]..shuffle(rng);
        final correctIndex = options.indexOf(correctAnswer);

        generated.add(VersusQuestion(
          id: 'q_$i',
          questionType: 'multiple_choice',
          questionText: questionText,
          options: options,
          correctOptionIndex: correctIndex,
        ));
      }

      setState(() {
        _questions = generated;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Error al generar el examen: $e';
        _isLoadingQuestions = false;
      });
    }
  }

  void _onOptionSelected(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
    });

    final currentQ = _questions[_currentQuestionIndex];
    if (index == currentQ.correctOptionIndex) {
      _correctAnswers++;
      _answerResults.add(true);
    } else {
      _answerResults.add(false);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = null;
          _answered = false;
        });
      } else {
        setState(() {
          _isFinished = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _loadError!,
              style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultScreen();
    }

    final q = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'PREGUNTA ${_currentQuestionIndex + 1} DE ${_questions.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(_questions.length, (index) {
                  Color c = AppColors.surfaceLight;
                  if (index < _currentQuestionIndex) {
                    c = _answerResults[index] ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                  } else if (index == _currentQuestionIndex) {
                    c = AppColors.primary;
                  }
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Question Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  q.questionText,
                  style: AppTypography.h3.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: List.generate(q.options.length, (index) {
                  final text = q.options[index];
                  bool isSelected = _selectedAnswerIndex == index;
                  bool isCorrect = index == q.correctOptionIndex;

                  Color bgColor = AppColors.surfaceLight;
                  Color borderColor = AppColors.cardBorder;

                  if (_answered) {
                    if (isCorrect) {
                      bgColor = const Color(0xFF10B981).withValues(alpha: 0.2);
                      borderColor = const Color(0xFF10B981);
                    } else if (isSelected) {
                      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
                      borderColor = const Color(0xFFEF4444);
                    }
                  } else if (isSelected) {
                    bgColor = AppColors.primary.withValues(alpha: 0.2);
                    borderColor = AppColors.primary;
                  }

                  return GestureDetector(
                    onTap: () => _onOptionSelected(index),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              text,
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final double percentage = (_correctAnswers / _questions.length) * 100;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF10B981), size: 80),
              ),
              const SizedBox(height: 32),
              Text(
                '¡Examen Finalizado!',
                style: AppTypography.h1,
              ),
              const SizedBox(height: 16),
              Text(
                'Misión Inicial: Examen Diagnóstico',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Calificación: ${percentage.toStringAsFixed(1)}%',
                      style: AppTypography.h2.copyWith(color: const Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '($_correctAnswers/${_questions.length} correctas)',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Volver a la Materia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
