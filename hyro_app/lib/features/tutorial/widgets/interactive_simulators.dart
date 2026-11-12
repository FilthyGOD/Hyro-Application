import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Contenedor base para los simuladores interactivos del tutorial
class TutorialSimulatorContainer extends StatelessWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final Color accentColor;

  const TutorialSimulatorContainer({
    super.key,
    required this.child,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del simulador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Interactivo',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. SIMULADOR: BIENVENIDA
// ═════════════════════════════════════════════════════════════════════════════
class WelcomeSimulator extends StatelessWidget {
  const WelcomeSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeaturePill(
                icon: Icons.timer_outlined,
                title: 'Técnica Pomodoro',
                subtitle: '25m enfoque + 5m descanso',
                color: AppColors.timerBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FeaturePill(
                icon: Icons.folder_outlined,
                title: 'Materias y Tareas',
                subtitle: 'Organización total',
                color: AppColors.accentViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FeaturePill(
                icon: Icons.military_tech_outlined,
                title: 'Duelos & Amigos',
                subtitle: 'Compite en vivo',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FeaturePill(
                icon: Icons.shield_outlined,
                title: 'Modo Estricto',
                subtitle: 'Cero distracciones',
                color: AppColors.breakGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.touch_app_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Desliza o usa los botones para recorrer la guía paso a paso.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. SIMULADOR: POMODORO Y CONFIGURACIÓN
// ═════════════════════════════════════════════════════════════════════════════
class PomodoroSimulator extends StatefulWidget {
  const PomodoroSimulator({super.key});

  @override
  State<PomodoroSimulator> createState() => _PomodoroSimulatorState();
}

class _PomodoroSimulatorState extends State<PomodoroSimulator> {
  int _selectedMinutes = 25;
  int _studyModeIndex =
      0; // 0: Sin tarea, 1: Toda la materia, 2: Tarea específica

  @override
  Widget build(BuildContext context) {
    final coins =
        _selectedMinutes == 25
            ? 10
            : _selectedMinutes == 45
            ? 20
            : _selectedMinutes == 60
            ? 30
            : 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Selector de Duración
        Text(
          '1. SELECCIONA EL TIEMPO Y RECOMPENSA (+$coins 🪙):',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white60,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTimeChip(25, '10 🪙'),
            const SizedBox(width: 8),
            _buildTimeChip(45, '20 🪙'),
            const SizedBox(width: 8),
            _buildTimeChip(60, '30 🪙'),
            const SizedBox(width: 8),
            _buildTimeChip(90, '50 🪙'),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Tres Formas de Iniciar
        Text(
          '2. ¿CÓMO DESEAS ENFOCARTE? (Toca para probar):',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white60,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          index: 0,
          icon: Icons.flash_on_rounded,
          title: 'Empezar sin tarea (Estudio Libre)',
          description: 'Cronómetro rápido para estudiar sin asignar materia.',
          badge: 'Rápido',
        ),
        const SizedBox(height: 6),
        _buildModeOption(
          index: 1,
          icon: Icons.menu_book_rounded,
          title: 'Toda la categoría / materia',
          description:
              'Selecciona una materia (ej. Matemáticas) sin especificar tarea.',
          badge: 'General',
        ),
        const SizedBox(height: 6),
        _buildModeOption(
          index: 2,
          icon: Icons.check_circle_outline_rounded,
          title: 'Con una tarea específica',
          description:
              'Avanza y suma pomodoros completados a una tarea puntual.',
          badge: 'Enfocado',
        ),
        const SizedBox(height: 12),

        // Info caja: Pausas y Quizzes
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '💡 Pausa máx: 2 minutos. Si la superas, la sesión se cancela para cuidar tu disciplina.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(int minutes, String reward) {
    final isSelected = _selectedMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMinutes = minutes),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${minutes}m',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reward,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String badge,
  }) {
    final isSelected = _studyModeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _studyModeIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.timerBlue.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.timerBlue : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.timerBlue.withValues(alpha: 0.25)
                        : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.timerBlue : Colors.white60,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.timerBlue.withValues(alpha: 0.3)
                                  : Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? AppColors.timerBlue
                                    : Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.timerBlue : Colors.white30,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. SIMULADOR: CATEGORÍAS Y TAREAS (ORGANIZACIÓN)
// ═════════════════════════════════════════════════════════════════════════════
class CategoryTaskSimulator extends StatefulWidget {
  const CategoryTaskSimulator({super.key});

  @override
  State<CategoryTaskSimulator> createState() => _CategoryTaskSimulatorState();
}

class _CategoryTaskSimulatorState extends State<CategoryTaskSimulator> {
  int _activeStep = 0; // 0: Categoría, 1: Pantalla automática, 2: Tarea
  int _selectedColorIndex = 0;
  final List<Color> _colors = const [
    Color(0xFF22C55E), // Verde
    Color(0xFF3B82F6), // Azul
    Color(0xFFEF4444), // Rojo
    Color(0xFF8B5CF6), // Violeta
    Color(0xFFF59E0B), // Naranja
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs de flujo
        Row(
          children: [
            _buildFlowTab(0, '1. Crear Categoría'),
            const SizedBox(width: 6),
            _buildFlowTab(1, '2. Apertura Auto'),
            const SizedBox(width: 6),
            _buildFlowTab(2, '3. Crear Tarea'),
          ],
        ),
        const SizedBox(height: 14),

        // Vista según paso
        if (_activeStep == 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _colors[_selectedColorIndex].withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.school,
                        color: _colors[_selectedColorIndex],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre de la Categoría',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'Cálculo Integral y Álgebra',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Elige un color para identificarla:',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_colors.length, (i) {
                    final isSel = _selectedColorIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child:
                            isSel
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => _activeStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colors[_selectedColorIndex],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Simular: "Guardar Categoría"'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ] else if (_activeStep == 1) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _colors[_selectedColorIndex].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _colors[_selectedColorIndex].withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  color: _colors[_selectedColorIndex],
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡Se abre automáticamente la pantalla de la categoría!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Al crear una categoría, Hyro te lleva directamente adentro para que puedas comenzar a añadir sus tareas de inmediato.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => _activeStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ver cómo se crea la Tarea',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tarea: Guía de ejercicios tema 3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTaskTag('Prioridad ALTA', Colors.redAccent),
                    const SizedBox(width: 6),
                    _buildTaskTag('Meta: 4 Pomodoros 🍅', Colors.orangeAccent),
                    const SizedBox(width: 6),
                    _buildTaskTag('Entrega: Mañana 📅', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Puedes agregar Flashcards y Notas a cada tarea para repasarlas en los descansos.',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _activeStep = 0),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              'Reiniciar simulación de organización ↺',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlowTab(int step, String label) {
    final isSelected = _activeStep == step;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeStep = step),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentViolet : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.accentViolet : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. SIMULADOR: MODO ESTRICTO
// ═════════════════════════════════════════════════════════════════════════════
class StrictModeSimulator extends StatefulWidget {
  const StrictModeSimulator({super.key});

  @override
  State<StrictModeSimulator> createState() => _StrictModeSimulatorState();
}

class _StrictModeSimulatorState extends State<StrictModeSimulator> {
  bool _isStrictEnabled = true;
  bool _showInterception = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switch interactivo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/Escudo.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modo Estricto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _isStrictEnabled
                          ? 'Activado en Ajustes ⚙️'
                          : 'Desactivado',
                      style: TextStyle(
                        color:
                            _isStrictEnabled
                                ? AppColors.breakGreen
                                : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isStrictEnabled,
                activeColor: AppColors.breakGreen,
                onChanged: (v) => setState(() => _isStrictEnabled = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Botón para probar qué pasa si sales a otra app
        if (!_showInterception) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _showInterception = true),
            icon: const Icon(Icons.exit_to_app_rounded, size: 16),
            label: const Text('Simular: "Salir a WhatsApp o Instagram"'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else ...[
          // Simulación de la intercepción de Jairito
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1015),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '¡Distracción Detectada!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showInterception = false),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Qué hacías en otra app? Este tiempo es para enfocarte.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() => _showInterception = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Vuelve a enfocarte (Reanudar)',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          '📌 En Android funciona mediante servicio en segundo plano; en PC te alerta si cambias de ventana.',
          style: TextStyle(color: Colors.white54, fontSize: 10.5),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. SIMULADOR: AGENDA Y CALENDARIO
// ═════════════════════════════════════════════════════════════════════════════
class AgendaSimulator extends StatefulWidget {
  const AgendaSimulator({super.key});

  @override
  State<AgendaSimulator> createState() => _AgendaSimulatorState();
}

class _AgendaSimulatorState extends State<AgendaSimulator> {
  int _viewMode = 1; // 0: Día, 1: Semana, 2: Mes

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de vista
        Row(
          children: [
            _buildViewChip(0, 'Día'),
            const SizedBox(width: 6),
            _buildViewChip(1, 'Semana'),
            const SizedBox(width: 6),
            _buildViewChip(2, 'Mes'),
          ],
        ),
        const SizedBox(height: 12),

        // Vista de tareas agendadas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Entregas y Pomodoros programados',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildAgendaItem(
                time: 'Hoy 16:00',
                title: 'Examen de Física II',
                subject: 'Física',
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 6),
              _buildAgendaItem(
                time: 'Mañana 10:00',
                title: 'Entrega Ensayo Historia',
                subject: 'Historia',
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 6),
              _buildAgendaItem(
                time: 'Viernes 18:00',
                title: 'Proyecto Flutter',
                subject: 'Programación',
                color: AppColors.breakGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '💡 Toca "Agenda" en la pantalla de inicio o "Calendario" en la barra inferior para acceder.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildViewChip(int mode, String label) {
    final isSel = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color:
                isSel
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSel ? AppColors.primary : Colors.white60,
              fontSize: 11,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaItem({
    required String time,
    required String title,
    required String subject,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              subject,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 6. SIMULADOR: AMIGOS Y DUELOS (VERSUS)
// ═════════════════════════════════════════════════════════════════════════════
class FriendsDuelsSimulator extends StatefulWidget {
  const FriendsDuelsSimulator({super.key});

  @override
  State<FriendsDuelsSimulator> createState() => _FriendsDuelsSimulatorState();
}

class _FriendsDuelsSimulatorState extends State<FriendsDuelsSimulator> {
  int _tab = 1; // 0: Ranking, 1: Duelos Versus
  int _battleMode = 0; // 0: Misma Materia, 1: Choque de Materias

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Row(
          children: [
            Expanded(child: _buildTab(0, '👥 Ranking Amigos')),
            const SizedBox(width: 8),
            Expanded(child: _buildTab(1, '⚔️ Duelos (Versus)')),
          ],
        ),
        const SizedBox(height: 12),

        if (_tab == 0) ...[
          // Ranking
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildRankingRow(
                  1,
                  'Carlos_Study',
                  '340 min',
                  '🥇',
                  Colors.amber,
                ),
                const Divider(color: Colors.white10, height: 12),
                _buildRankingRow(2, 'Tú', '285 min', '🥈', Colors.white70),
                const Divider(color: Colors.white10, height: 12),
                _buildRankingRow(
                  3,
                  'Mariana_Focus',
                  '210 min',
                  '🥉',
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compite semanalmente con amigos. Puedes agregarlos por su Nombre#Código.',
            style: TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
        ] else ...[
          // Duelos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Retar a un amigo a un Duelo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildBattleModeChip(
                        0,
                        'Misma Materia',
                        'Mismas preguntas',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildBattleModeChip(
                        1,
                        'Choque de Materias',
                        'Cada quien su tema',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Apuesta: 50 HyroCoins 🪙',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Al mejor de 3 rondas',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '¡El ganador se lleva el botín de monedas apostadas en tiempo real!',
            style: TextStyle(color: Colors.white54, fontSize: 10.5),
          ),
        ],
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final isSel = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSel
                  ? Colors.amber.withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? Colors.amber : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSel ? Colors.amber : Colors.white60,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRankingRow(
    int pos,
    String name,
    String time,
    String medal,
    Color color,
  ) {
    return Row(
      children: [
        Text(medal, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildBattleModeChip(int mode, String title, String subtitle) {
    final isSel = _battleMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _battleMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSel ? Colors.amber.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? Colors.amber : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSel ? Colors.amber : Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 8.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 7. SIMULADOR: MISIONES DIARIAS Y RACHA
// ═════════════════════════════════════════════════════════════════════════════
class MissionsRachaSimulator extends StatefulWidget {
  const MissionsRachaSimulator({super.key});

  @override
  State<MissionsRachaSimulator> createState() => _MissionsRachaSimulatorState();
}

class _MissionsRachaSimulatorState extends State<MissionsRachaSimulator> {
  bool _missionClaimed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Racha bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/LlamaRacha.svg',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Racha: 5 Días Consecutivos 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/Escudo.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 4),
              const Text(
                '1 Escudo',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Misiones de ejemplo
        _buildMissionItem(
          title: 'Completar 2 Pomodoros',
          progress:
              _missionClaimed ? 'Reclamada ✅' : '2/2 (Toca para reclamar)',
          percent: 1.0,
          rewardXP: 25,
          rewardCoins: 10,
          isCompleted: true,
          isClaimed: _missionClaimed,
          onTap: () {
            setState(() => _missionClaimed = !_missionClaimed);
          },
        ),
        const SizedBox(height: 6),
        _buildMissionItem(
          title: 'Estudiar 60 minutos en total',
          progress: '45/60 min',
          percent: 0.75,
          rewardXP: 50,
          rewardCoins: 20,
          isCompleted: false,
        ),
        const SizedBox(height: 6),
        _buildMissionItem(
          title: 'Completar 2 tareas de materias',
          progress: '1/2',
          percent: 0.5,
          rewardXP: 35,
          rewardCoins: 15,
          isCompleted: false,
        ),
        const SizedBox(height: 10),
        const Text(
          '🎯 Las monedas te permiten comprar cosméticos para vestir a Jairito en la Tienda 🛍️.',
          style: TextStyle(color: Colors.white54, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildMissionItem({
    required String title,
    required String progress,
    required double percent,
    required int rewardXP,
    required int rewardCoins,
    required bool isCompleted,
    bool isClaimed = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              isClaimed
                  ? AppColors.breakGreen.withValues(alpha: 0.1)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isClaimed
                    ? AppColors.breakGreen
                    : isCompleted
                    ? AppColors.breakGreen.withValues(alpha: 0.4)
                    : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isClaimed
                      ? Icons.verified_rounded
                      : isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? AppColors.breakGreen : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '+$rewardXP XP / +$rewardCoins 🪙',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.breakGreen : AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                progress,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
