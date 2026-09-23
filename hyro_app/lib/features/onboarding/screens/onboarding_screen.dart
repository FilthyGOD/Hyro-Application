import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyro/core/theme/app_colors.dart';
import 'package:hyro/core/theme/app_typography.dart';
import 'package:hyro/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:hyro/features/onboarding/widgets/onboarding_option_card.dart';
import 'package:hyro/features/onboarding/screens/create_profile_screen.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selected options state
  String? _discoverySource;
  String? _studentProfile;
  String? _mainProblem;
  String? _studyTechnique;
  String? _dailyGoal;
  String? _rewardChoice;

  // Total pages: 8 (0 to 7)
  final int _totalPages = 8;

  bool _isLoadingComplete = false;
  String _loadingText = "Configurando tu plan de estudio personalizado...";
  final List<String> _loadingSubtexts = [
    "Preparando tu cronómetro...",
    "Escondiendo las distracciones...",
    "¡Todo listo para empezar a ganar monedas!",
  ];
  int _loadingSubtextIndex = 0;
  Timer? _loadingTimer;

  @override
  void dispose() {
    _pageController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      if (_currentPage == 6) {
        _startLoadingAnimation();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startLoadingAnimation() {
    int tick = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      tick++;
      if (tick < _loadingSubtexts.length) {
        setState(() {
          _loadingSubtextIndex = tick;
        });
      } else {
        timer.cancel();
        setState(() {
          _isLoadingComplete = true;
          _loadingText = "¡Todo listo!";
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _finishOnboarding();
          }
        });
      }
    });
  }

  void _finishOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFirstPage = _currentPage == 0;
    bool isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          isLastPage
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading:
                    isFirstPage
                        ? null
                        : IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _previousPage,
                        ),
                title:
                    isFirstPage
                        ? null
                        : OnboardingProgressBar(
                          currentStep: _currentPage,
                          totalSteps: _totalPages - 2,
                        ),
                centerTitle: true,
              ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildWelcomePage(),
          _buildDiscoveryPage(),
          _buildStudentProfilePage(),
          _buildMainProblemPage(),
          _buildSolutionPage(),
          _buildDailyGoalPage(),
          _buildRewardPage(),
          _buildLoadingPage(),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required bool isEnabled,
    required String text,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              isEnabled
                  ? const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 149, 255),
                      Color.fromARGB(255, 32, 43, 200),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                  : null,
          color: isEnabled ? null : AppColors.surfaceLight,
          boxShadow:
              isEnabled
                  ? [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        0,
                        149,
                        255,
                      ).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? (onPressed ?? _nextPage) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isEnabled ? Colors.white : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          SvgPicture.asset(
            'assets/images/JairitoHD_SaludoInv.svg',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            '¡Hola! Soy Jairo.',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '¿Listo para subir tus notas y\nvencer la procrastinación?',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildBottomButton(isEnabled: true, text: '¡VAMOS!'),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({
    required String question,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/JairitoHD_Encuesta.svg',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      16,
                    ).copyWith(topLeft: const Radius.circular(0)),
                  ),
                  child: Text(
                    question,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return OnboardingOptionCard(
                text: option['text']!,
                emoji: option['emoji'],
                isSelected: selectedValue == option['text'],
                onTap: () => onSelect(option['text']!),
              );
            },
          ),
        ),
        _buildBottomButton(isEnabled: selectedValue != null, text: 'CONTINUAR'),
      ],
    );
  }

  Widget _buildDiscoveryPage() {
    return _buildQuestionPage(
      question: "¿Cómo te enteraste de Hyro?",
      options: [
        {'text': 'TikTok', 'emoji': '📱'},
        {'text': 'Búsqueda en Google', 'emoji': '🔍'},
        {'text': 'Facebook/Instagram', 'emoji': '👥'},
        {'text': 'Play Store / App Store', 'emoji': '🏪'},
        {'text': 'Amigos/compañeros de clase', 'emoji': '🗣️'},
        {'text': 'Noticias/artículos/blog', 'emoji': '📰'},
      ],
      selectedValue: _discoverySource,
      onSelect: (val) => setState(() => _discoverySource = val),
    );
  }

  Widget _buildStudentProfilePage() {
    return _buildQuestionPage(
      question: "¿Qué tipo de estudiante eres?",
      options: [
        {'text': 'Universitario (Licenciatura / Ingeniería)', 'emoji': '📘'},
        {'text': 'Preparatoria / Bachillerato', 'emoji': '🎒'},
        {'text': 'Posgrado (Maestría / Doctorado)', 'emoji': '🎓'},
        {'text': 'Autodidacta / Cursos libres', 'emoji': '📚'},
      ],
      selectedValue: _studentProfile,
      onSelect: (val) => setState(() => _studentProfile = val),
    );
  }

  Widget _buildMainProblemPage() {
    return _buildQuestionPage(
      question: "Seamos honestos... ¿Cuál es tu mayor enemigo al estudiar?",
      options: [
        {'text': 'Las redes sociales (Me distraigo rápido)', 'emoji': '📱'},
        {
          'text': 'Dejar todo para el último minuto (Procrastinación)',
          'emoji': '⏳',
        },
        {'text': 'Me cuesta concentrarme por mucho tiempo', 'emoji': '🧠'},
        {'text': 'Me aburro rápido de los apuntes', 'emoji': '🥱'},
      ],
      selectedValue: _mainProblem,
      onSelect: (val) => setState(() => _mainProblem = val),
    );
  }

  Widget _buildSolutionPage() {
    return _buildQuestionPage(
      question: "¿Qué técnica de estudio quieres que probemos juntos?",
      options: [
        {
          'text': 'Pomodoro Clásico (25 min trabajo / 5 min descanso)',
          'emoji': '🍅',
        },
        {
          'text': 'Enfoque Profundo (50 min trabajo / 10 min descanso)',
          'emoji': '🔥',
        },
        {
          'text': 'Ráfagas Cortas (15 min trabajo / 3 min descanso)',
          'emoji': '⚡',
        },
        {'text': 'No sé, ¡Tú recomiéndame!', 'emoji': '🤔'},
      ],
      selectedValue: _studyTechnique,
      onSelect: (val) => setState(() => _studyTechnique = val),
    );
  }

  Widget _buildDailyGoalPage() {
    return _buildQuestionPage(
      question: "¿Cuánto tiempo quieres dedicarle al estudio cada día?",
      options: [
        {'text': 'Relajado (1 sesión Pomodoro - 25 min)', 'emoji': '😌'},
        {'text': 'Normal (2 sesiones Pomodoro - 50 min)', 'emoji': '🙂'},
        {'text': 'Intenso (4 sesiones Pomodoro - 100 min)', 'emoji': '💪'},
        {'text': 'Modo Bestia (6+ sesiones Pomodoro)', 'emoji': '🔥'},
      ],
      selectedValue: _dailyGoal,
      onSelect: (val) => setState(() => _dailyGoal = val),
    );
  }

  Widget _buildRewardPage() {
    return _buildQuestionPage(
      question:
          "¡Excelente meta! Por cada sesión completada ganarás Hyro-Monedas. ¿En qué te gustaría gastarlas primero?",
      options: [
        {'text': 'Accesorios y ropa nueva para mí (Jairo)', 'emoji': '🕶️'},
        {'text': 'Desafiar a mis amigos en un "Duelo"', 'emoji': '⚔️'},
        {'text': 'Subir de nivel en la liga semanal', 'emoji': '🏆'},
      ],
      selectedValue: _rewardChoice,
      onSelect: (val) => setState(() => _rewardChoice = val),
    );
  }

  Widget _buildLoadingPage() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/Jairo_Constructor.svg',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              Text(
                _loadingText,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 24,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _isLoadingComplete ? 1.0 : null,
                  minHeight: 12,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingSubtexts[_loadingSubtextIndex],
                  key: ValueKey<int>(_loadingSubtextIndex),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
