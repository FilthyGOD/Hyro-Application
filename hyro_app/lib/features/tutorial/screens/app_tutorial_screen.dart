import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/tutorial_step.dart';
import '../services/tutorial_service.dart';
import '../widgets/interactive_simulators.dart';

class AppTutorialScreen extends StatefulWidget {
  final int initialStep;

  const AppTutorialScreen({super.key, this.initialStep = 0});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  late final PageController _pageController;
  late int _currentStep;

  final List<TutorialStep> _steps = const [
    TutorialStep(
      type: TutorialStepType.welcome,
      stepNumber: 1,
      tag: 'BIENVENIDA',
      title: 'Domina tu estudio y sube de nivel',
      highlightPhrase:
          'Tu compañero ideal para concentrarte y divertirte aprendiendo.',
      description:
          'Hyro combina la técnica Pomodoro, organización académica y gamificación con Jairito, tu mascota de estudio.',
      mascotSvg: 'assets/images/JairitoHD_Saludo.svg',
      accentColor: AppColors.primary,
      badgeIcon: Icons.waving_hand_rounded,
      bulletPoints: [
        '🍅 Estudia en bloques con descansos inteligentes y automáticos.',
        '📁 Organiza materias, tareas, notas y flashcards por colores.',
        '🎮 Gana monedas, sube de nivel y compite sanamente con amigos.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.pomodoro,
      stepNumber: 2,
      tag: 'TEMPORIZADOR',
      title: 'Cómo iniciar y configurar tu Pomodoro',
      highlightPhrase:
          'Configura el tiempo, las recompensas y el material a estudiar.',
      description:
          'Al presionar Iniciar se abre la configuración del Pomodoro. Puedes elegir la duración y cómo deseas enfocarte.',
      mascotSvg: 'assets/images/JairitoHD_Apuntando.svg',
      accentColor: AppColors.timerColor,
      badgeIcon: Icons.timer_rounded,
      bulletPoints: [
        '⏱️ Duraciones: 25m (+10 🪙), 45m (+20 🪙), 60m (+30 🪙) o 90m (+50 🪙).',
        '⚡ Sin tarea: pulsa "Empezar sin tarea" para un estudio libre y rápido.',
        '📚 Toda la materia: selecciona una categoría completa sin tarea puntual.',
        '🎯 Con tarea: selecciona una tarea específica para sumar pomodoros a su meta.',
        '⚠️ Pausas: tienes hasta 2 minutos de pausa máxima antes de que se cancele.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.categoriesAndTasks,
      stepNumber: 3,
      tag: 'ORGANIZACIÓN',
      title: 'Crea Categorías y luego sus Tareas',
      highlightPhrase:
          '¡Al crear una categoría se abre automáticamente su pantalla!',
      description:
          'Usa el botón "+" para organizar tu semestre. Primero crea la materia y luego añade sus tareas.',
      mascotSvg: 'assets/images/Jairo_Constructor.svg',
      accentColor: AppColors.pomodoroRed,
      badgeIcon: Icons.create_new_folder_rounded,
      bulletPoints: [
        '1️⃣ Toca el botón "+" en la barra y elige la pestaña "Categoría".',
        '2️⃣ Asígnale nombre, color distintivo e icono para identificarla.',
        '3️⃣ ¡Paso clave!: Al guardar, la app te abre automáticamente la pantalla de esa categoría.',
        '4️⃣ En esa pantalla crea sus Tareas con prioridad (Alta/Media/Baja), pomodoros y fecha.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.strictMode,
      stepNumber: 4,
      tag: 'MODO ESTRICTO',
      title: 'Cero distracciones en celular y PC',
      highlightPhrase:
          'Te devuelve a la app y protege tu tiempo si intentas salir.',
      description:
          'El Modo Estricto es tu escudo contra redes sociales, mensajería y distracciones mientras corre tu temporizador.',
      mascotSvg: 'assets/images/JairitoHD_Pensando.svg',
      accentColor: AppColors.breakGreen,
      badgeIcon: Icons.shield_rounded,
      bulletPoints: [
        '⚙️ Cómo activarlo: Ve a Ajustes (desde Perfil) y enciende "Modo Estricto".',
        '🚨 Detección activa: Si sales de Hyro o abres otra app, el cronómetro se pausa de inmediato.',
        '🛡️ Jairito te muestra una alerta: "¡Distracción detectada! Vuelve a enfocarte".',
        '📱 En Android usa servicio en primer plano para traerte de vuelta.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.agenda,
      stepNumber: 5,
      tag: 'AGENDA & CALENDARIO',
      title: 'Tu calendario de entregas y estudio',
      highlightPhrase:
          'Planifica tus semanas y visualiza tus exámenes a tiempo.',
      description:
          'La Agenda centraliza todas las tareas con fecha límite, próximos exámenes y horarios semanales.',
      mascotSvg: 'assets/images/JairitoHD_DeHechoBueno.svg',
      accentColor: Colors.blueAccent,
      badgeIcon: Icons.calendar_month_rounded,
      bulletPoints: [
        '📅 Accede pulsando "Agenda" en la pantalla de inicio o "Calendario" en la barra.',
        '🔍 Vistas Día, Semana y Mes con códigos de colores según cada materia.',
        '📊 Gráfico de análisis: tareas completadas vs pendientes en tiempo real.',
        '⏰ Horario semanal: visualiza qué materias y salones te tocan cada día.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.friendsAndDuels,
      stepNumber: 6,
      tag: 'AMIGOS & DUELOS',
      title: 'Compite con amigos y gana duelos',
      highlightPhrase:
          'Ranking semanal y combates de preguntas con apuestas de monedas.',
      description:
          'Estudiar acompañado es más divertido. Reta a tus amigos a combates de preguntas en vivo.',
      mascotSvg: 'assets/images/JairitoHD_Apuntando.svg',
      accentColor: Colors.amber,
      badgeIcon: Icons.sports_esports_rounded,
      bulletPoints: [
        '👥 Pestaña Amigos: Entra desde el botón "Amigos" de la pantalla principal.',
        '🏆 Ranking Semanal: Descubre quién acumuló más minutos de enfoque.',
        '⚔️ Duelos Versus: Reta en "Misma Materia" o "Choque de Materias".',
        '🪙 Apuesta HyroCoins: El ganador de 3 rondas se lleva el botín acumulado.',
      ],
    ),
    TutorialStep(
      type: TutorialStepType.dailyMissions,
      stepNumber: 7,
      tag: 'MISIONES & RACHA',
      title: 'Misiones diarias, Racha y Tienda',
      highlightPhrase:
          'Gana XP, sube de nivel y viste a Jairito con ropa y sombreros.',
      description:
          'Cada día tienes 3 misiones que se renuevan a medianoche para mantener tu hábito constante.',
      mascotSvg: 'assets/images/JairitoRecompensaRemake.svg',
      accentColor: Colors.deepOrangeAccent,
      badgeIcon: Icons.military_tech_rounded,
      bulletPoints: [
        '🎯 Tarjeta de Misiones: visible en la pantalla principal (fácil, media y difícil).',
        '🔥 Racha diaria: completa al menos 1 sesión al día para mantenerla encendida.',
        '🛡️ Escudos: protegen tu racha si un día no puedes estudiar.',
        '🛍️ Tienda de Cosméticos: viste a Jairito con trajes, sombreros y accesorios.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _steps.length - 1);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _steps.length) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishTutorial() async {
    await TutorialService.instance.markTutorialSeen();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra Superior (Header & Quick Jumper) ──
            _buildHeader(step),
            const SizedBox(height: 4),

            // ── Barra horizontal de píldoras para salto directo ──
            _buildPillStepBar(),
            const SizedBox(height: 8),

            // ── Contenido Principal (PageView) ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                itemBuilder: (context, index) {
                  return _buildStepContent(_steps[index]);
                },
              ),
            ),

            // ── Barra Inferior (Navegación & Acción) ──
            _buildBottomBar(isLastStep),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Logo & Título
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 30,
              height: 30,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guía de Uso de Hyro',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Paso ${_currentStep + 1} de ${_steps.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: step.accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botón Cerrar / Omitir
          TextButton.icon(
            onPressed: _finishTutorial,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.white60,
            ),
            label: const Text(
              'Omitir',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillStepBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final isSelected = _currentStep == index;
          final stepItem = _steps[index];
          return GestureDetector(
            onTap: () => _goToStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? stepItem.accentColor.withValues(alpha: 0.22)
                        : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected
                          ? stepItem.accentColor
                          : AppColors.cardBorder.withValues(alpha: 0.8),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stepItem.badgeIcon,
                    size: 14,
                    color: isSelected ? stepItem.accentColor : Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${index + 1}. ${stepItem.tag}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(TutorialStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera del paso con Mascota ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mascota Jairito en SVG con aura
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: step.accentColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: step.accentColor.withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SvgPicture.asset(step.mascotSvg, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              // Textos de título y tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.tag,
                        style: TextStyle(
                          color: step.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.title,
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.highlightPhrase,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Simulador Interactivo Específico ──
          TutorialSimulatorContainer(
            title: 'Simulación del Paso ${step.stepNumber}: ${step.tag}',
            icon: step.badgeIcon,
            accentColor: step.accentColor,
            child: _buildSimulatorForStep(step.type),
          ),
          const SizedBox(height: 18),

          // ── Claves del funcionamiento (Bullets explicativos) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: step.accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Puntos Importantes a Recordar:',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...step.bulletPoints.map((bullet) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: step.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSimulatorForStep(TutorialStepType type) {
    switch (type) {
      case TutorialStepType.welcome:
        return const WelcomeSimulator();
      case TutorialStepType.pomodoro:
        return const PomodoroSimulator();
      case TutorialStepType.categoriesAndTasks:
        return const CategoryTaskSimulator();
      case TutorialStepType.strictMode:
        return const StrictModeSimulator();
      case TutorialStepType.agenda:
        return const AgendaSimulator();
      case TutorialStepType.friendsAndDuels:
        return const FriendsDuelsSimulator();
      case TutorialStepType.dailyMissions:
        return const MissionsRachaSimulator();
    }
  }

  Widget _buildBottomBar(bool isLastStep) {
    final step = _steps[_currentStep];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Botón Anterior
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => _goToStep(_currentStep - 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Anterior', style: TextStyle(fontSize: 13)),
            )
          else
            const SizedBox(width: 70),

          const Spacer(),

          // Indicador de Puntos (Dots)
          Row(
            children: List.generate(_steps.length, (index) {
              final isCurrent = index == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent ? step.accentColor : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          const Spacer(),

          // Botón Siguiente o Finalizar
          ElevatedButton(
            onPressed: () {
              if (isLastStep) {
                _finishTutorial();
              } else {
                _goToStep(_currentStep + 1);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLastStep ? AppColors.primary : step.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLastStep ? '¡Empezar! 🚀' : 'Siguiente',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (!isLastStep) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
