import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/versus_provider.dart';
import '../friends/widgets/static_mascot_widget.dart';
import 'models/versus_models.dart';
import 'widgets/versus_drag_drop_widget.dart';

/// Pantalla de Combate Versus (Durante el juego).
/// Implementa estrictamente el encabezado (Header) requerido, la barra de progreso por guiones,
/// y la lógica interactiva de respuesta y avance de rondas.
///
/// Conectada a Supabase a través de [VersusProvider] para:
/// - Cargar preguntas reales desde `batalla_preguntas`.
/// - Guardar respuestas en `batalla_respuestas` con tiempo en ms.
/// - Actualizar el marcador en `batallas_versus` al finalizar ronda.
class VersusCombatScreen extends StatefulWidget {
  final VersusMatch match;

  const VersusCombatScreen({super.key, required this.match});

  @override
  State<VersusCombatScreen> createState() => _VersusCombatScreenState();
}

enum AnswerStatus { pending, correct, incorrect }

class _VersusCombatScreenState extends State<VersusCombatScreen> {
  // ── Variables de Estado del Juego ──
  late int _currentRound; // 1, 2 o 3 (Desempate)
  int _localRoundsWon = 0;
  int _opponentRoundsWon = 0;

  int _currentQuestionIndex = 0;
  late int _totalQuestionsInRound; // 5 en rondas 1 y 2, 6 en ronda 3 (desempate)
  late List<AnswerStatus> _dashProgress;

  int? _selectedAnswerIndex;
  bool _answered = false;

  // ── Datos reales de preguntas (cargadas desde Supabase) ──
  List<VersusQuestion> _questions = [];
  bool _isLoadingQuestions = true;
  String? _loadError;

  // ── Cronómetro de respuesta (para medir tiempo en ms) ──
  late Stopwatch _answerStopwatch;

  // ── Preguntas de fallback por si no hay preguntas en la BD ──
  static const List<VersusQuestion> _fallbackQuestions = [
    VersusQuestion(
      id: 'fallback_1',
      questionType: 'multiple_choice',
      questionText: '¿Cuál es la capital de Francia?',
      options: ['Madrid', 'París', 'Roma', 'Berlín'],
      correctOptionIndex: 1,
    ),
    VersusQuestion(
      id: 'fallback_2',
      questionType: 'multiple_choice',
      questionText: '¿Cuál es el resultado de 5 x 5?',
      options: ['20', '25', '30', '35'],
      correctOptionIndex: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentRound = widget.match.currentRound;
    _localRoundsWon = widget.match.localRoundsWon;
    _opponentRoundsWon = widget.match.opponentRoundsWon;
    _answerStopwatch = Stopwatch();

    _initRoundProgress();
    _cargarPreguntas();
  }

  /// Inicializa la cantidad de espacios de la barra por guiones según la regla estricta:
  /// - Rondas 1 y 2: 5 guiones (5 preguntas)
  /// - Ronda 3 (Desempate): 6 guiones (3 de tus apuntes + 3 del rival)
  void _initRoundProgress() {
    _totalQuestionsInRound = (_currentRound == 3) ? 6 : 5;
    _dashProgress = List.generate(_totalQuestionsInRound, (_) => AnswerStatus.pending);
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _answered = false;
  }

  /// Carga las preguntas de la ronda actual desde Supabase.
  Future<void> _cargarPreguntas() async {
    setState(() {
      _isLoadingQuestions = true;
      _loadError = null;
    });

    try {
      final versus = context.read<VersusProvider>();
      final preguntas = await versus.cargarPreguntasRonda(
        batallaId: widget.match.id,
        ronda: _currentRound,
      );

      if (mounted) {
        setState(() {
          _questions = preguntas.isNotEmpty ? preguntas : _fallbackQuestions;
          // Ajustar la barra de progreso al número real de preguntas
          _totalQuestionsInRound = _questions.length;
          _dashProgress = List.generate(_totalQuestionsInRound, (_) => AnswerStatus.pending);
          _isLoadingQuestions = false;
          // Iniciar cronómetro para la primera pregunta
          _answerStopwatch.reset();
          _answerStopwatch.start();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Error cargando preguntas: $e';
          _questions = _fallbackQuestions;
          _totalQuestionsInRound = _questions.length;
          _dashProgress = List.generate(_totalQuestionsInRound, (_) => AnswerStatus.pending);
          _isLoadingQuestions = false;
        });
      }
    }
  }

  void _onAnswerSelected({int? index, String? textAnswer, bool? overrideIsCorrect}) {
    if (_answered) return;
    final currentQ = _questions[_currentQuestionIndex];
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUserId;
    final versus = context.read<VersusProvider>();

    _answerStopwatch.stop();
    final tiempoMs = _answerStopwatch.elapsedMilliseconds;

    bool isCorrect = false;
    String finalAnswer = '';

    if (overrideIsCorrect != null) {
      isCorrect = overrideIsCorrect;
      finalAnswer = textAnswer ?? '';
    } else if (index != null) {
      isCorrect = index == currentQ.correctOptionIndex;
      finalAnswer = currentQ.options[index];
    }

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      _dashProgress[_currentQuestionIndex] = isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect;
    });

    if (userId != null && currentQ.id != 'fallback_1') {
      versus.guardarRespuesta(
        preguntaId: currentQ.id,
        batallaId: widget.match.id,
        jugadorId: userId,
        respuestaDada: finalAnswer,
        esCorrecta: isCorrect,
        tiempoRespuestaMs: tiempoMs,
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _totalQuestionsInRound - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
        // Reiniciar cronómetro para la siguiente pregunta
        _answerStopwatch.reset();
        _answerStopwatch.start();
      });
    } else {
      _finishRound();
    }
  }

  void _finishRound() {
    final correctCount = _dashProgress.where((s) => s == AnswerStatus.correct).length;
    final roundWon = correctCount >= (_totalQuestionsInRound / 2).ceil();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              roundWon ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
              color: roundWon ? AppColors.breakGreen : AppColors.pomodoroRedLight,
            ),
            const SizedBox(width: 10),
            Text(
              roundWon ? '¡Ronda Ganada!' : 'Ronda Perdida',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Acertaste $correctCount de $_totalQuestionsInRound preguntas en la Ronda $_currentRound.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final versusProvider = context.read<VersusProvider>();
              final auth = context.read<AuthProvider>();
              final battleId = widget.match.id;
              final userId = auth.supabaseUserId;

              Navigator.pop(context); // Cierra el dialogo
              Navigator.pop(context); // Cierra la pantalla de combate

              // ── Finalizar turno: pasar turno al oponente o marcar ronda completa ──
              if (userId != null) {
                versusProvider.finalizarTurno(
                  batallaId: battleId,
                  jugadorActualId: userId,
                  oponenteId: widget.match.opponent.id,
                  isChallenger: widget.match.isChallenger,
                  rondaActual: _currentRound,
                );
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.match.localPlayer;
    final opponent = widget.match.opponent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────────
            // 1. CABECERA STRICTA DE COMBATE (Header)
            // ─────────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Esquina Superior Izquierda: Jairo Local + Rondar Ganadas
                      _buildHeaderPlayer(
                        player: local,
                        roundsWon: _localRoundsWon,
                        isLocal: true,
                      ),

                      // Centro Superior: Pozo de Monedas Apostado
                      _buildBetCoinsPool(),

                      // Esquina Superior Derecha: Jairo Oponente + Rondas Ganadas
                      _buildHeaderPlayer(
                        player: opponent,
                        roundsWon: _opponentRoundsWon,
                        isLocal: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─────────────────────────────────────────────────────────
                  // 2. BARRA DE PROGRESO POR GUIONES (Dash Progress Bar)
                  // ─────────────────────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Ronda $_currentRound: ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            _totalQuestionsInRound,
                            (index) => Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _getDashColor(_dashProgress[index], index == _currentQuestionIndex),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: _dashProgress[index] == AnswerStatus.correct
                                      ? [
                                          BoxShadow(
                                            color: AppColors.breakGreen.withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
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
            ),

            // ─────────────────────────────────────────────────────────────
            // 3. CONTENEDOR DE LA PREGUNTA Y OPCIONES DE RESPUESTA
            // ─────────────────────────────────────────────────────────────
            if (_isLoadingQuestions)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Cargando preguntas...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loadError != null && _questions.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarPreguntas,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge del autor de los apuntes (útil en desempates)
                      if (_questions[_currentQuestionIndex].authorName != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _questions[_currentQuestionIndex].authorName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      if (_questions[_currentQuestionIndex].questionType == 'drag_drop')
                        VersusDragDropWidget(
                          textWithBlanks: _questions[_currentQuestionIndex].questionText,
                          originalBlanks: (_questions[_currentQuestionIndex].extraData['blanks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                          availableWords: (_questions[_currentQuestionIndex].extraData['available_words'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                          answered: _answered,
                          onVerify: (isCorrect, answerText) {
                            _onAnswerSelected(overrideIsCorrect: isCorrect, textAnswer: answerText);
                          },
                        )
                      else ...[
                        // Tarjeta de la Pregunta
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            _questions[_currentQuestionIndex].questionText,
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Opciones de respuesta
                        ...List.generate(
                          _questions[_currentQuestionIndex].options.length,
                          (index) => _buildOptionButton(
                            index: index,
                            text: _questions[_currentQuestionIndex].options[index],
                            correctIndex: _questions[_currentQuestionIndex].correctOptionIndex,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botón de Siguiente Pregunta
              if (_answered)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentQuestionIndex < _totalQuestionsInRound - 1 ? 'SIGUIENTE PREGUNTA' : 'FINALIZAR RONDA',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Retorna el color correspondiente para cada guión según la regla de feedback:
  /// - Verde: Correcta
  /// - Rojo: Incorrecta
  /// - Azul primario: Pregunta actual
  /// - Gris/Apagado: Pendiente
  Color _getDashColor(AnswerStatus status, bool isCurrent) {
    switch (status) {
      case AnswerStatus.correct:
        return AppColors.breakGreen;
      case AnswerStatus.incorrect:
        return const Color(0xFFEF4444);
      case AnswerStatus.pending:
        return isCurrent ? AppColors.primary : AppColors.cardBorder;
    }
  }

  /// Widget del Header para cada Jugador + Indicador de rondas (máximo 3)
  Widget _buildHeaderPlayer({
    required VersusPlayer player,
    required int roundsWon,
    required bool isLocal,
  }) {
    final avatarWidget = SizedBox(
      width: 42,
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isLocal ? AppColors.primary : AppColors.pomodoroRedLight,
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: StaticMascotWidget(
            sombrero: player.sombreroId,
            cosmetico: player.cosmeticoId,
            traje: player.trajeId,
          ),
        ),
      ),
    );

    final roundsIndicator = Row(
      children: List.generate(3, (i) {
        final won = i < roundsWon;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            won ? Icons.stars_rounded : Icons.star_border_rounded,
            size: 16,
            color: won ? const Color(0xFFF59E0B) : AppColors.textTertiary,
          ),
        );
      }),
    );

    return Row(
      children: isLocal
          ? [
              avatarWidget,
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.username,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  roundsIndicator,
                ],
              ),
            ]
          : [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    player.username,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  roundsIndicator,
                ],
              ),
              const SizedBox(width: 8),
              avatarWidget,
            ],
    );
  }

  /// Widget del centro superior: Pozo de monedas
  Widget _buildBetCoinsPool() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 4),
              Text(
                '${widget.match.betCoins * 2}',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            'POZO TOTAL',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFF59E0B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ronda $_currentRound: $_localRoundsWon - $_opponentRoundsWon',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón interactivo de opción de respuesta
  Widget _buildOptionButton({
    required int index,
    required String text,
    required int correctIndex,
  }) {
    final isSelected = _selectedAnswerIndex == index;
    Color buttonColor = AppColors.surfaceLight;
    Color borderColor = AppColors.cardBorder;

    if (_answered) {
      if (index == correctIndex) {
        buttonColor = AppColors.breakGreen.withValues(alpha: 0.2);
        borderColor = AppColors.breakGreen;
      } else if (isSelected) {
        buttonColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
        borderColor = const Color(0xFFEF4444);
      }
    } else if (isSelected) {
      buttonColor = AppColors.primary.withValues(alpha: 0.2);
      borderColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onAnswerSelected(index: index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected || (_answered && index == correctIndex) ? 2.0 : 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.2),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_answered && index == correctIndex)
                  const Icon(Icons.check_circle_rounded, color: AppColors.breakGreen),
                if (_answered && isSelected && index != correctIndex)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
