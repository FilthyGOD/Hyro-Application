import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Animation;
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/focus_provider.dart';
import '../providers/focus_state.dart';
import '../../settings/settings_provider.dart';
import '../../mascot/mascot_controller.dart';
import 'package:provider/provider.dart';
import '../../stats/stats_provider.dart';
import '../../../core/theme/app_colors.dart';

class CompletedSessionView extends StatefulWidget {
  final int streak;
  final bool initialShowStreakScreen;
  final bool isDebugMode;
  const CompletedSessionView({
    super.key,
    required this.streak,
    this.initialShowStreakScreen = false,
    this.isDebugMode = false,
  });

  @override
  State<CompletedSessionView> createState() => _CompletedSessionViewState();
}

class _CompletedSessionViewState extends State<CompletedSessionView> {
  late bool _showStreakScreen;

  @override
  void initState() {
    super.initState();
    _showStreakScreen = widget.initialShowStreakScreen;
    // Dispara la animación adecuada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showStreakScreen) {
        context.read<MascotController>().triggerRacha(widget.streak);
      } else {
        context.read<MascotController>().triggerFestejo();
      }
    });
  }

  int get streak => widget.streak;

  void _onFinalizar() {
    final statsProvider = context.read<StatsProvider>();
    final todaysStats = statsProvider.todaysStats;
    final sessionsToday = todaysStats?.focusSessions ?? 0;
    
    // Si es la primera sesion del dia, mostrar racha del dia
    if (sessionsToday == 1 && !_showStreakScreen) {
      setState(() {
        _showStreakScreen = true;
      });
      context.read<MascotController>().triggerRacha(streak);
    } else {
      if (widget.isDebugMode) {
        Navigator.of(context).pop();
      } else {
        context.read<FocusProvider>().reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _showStreakScreen 
            ? _buildStreakScreen(context)
            : _buildSessionFinishedScreen(context),
      ),
    );
  }

  Widget _buildSessionFinishedScreen(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final settings = context.read<SettingsProvider>();
    final pomodoroMins = settings.pomodoroDuration.toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 24 : 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: isMobile ? 250 : 300,
                      height: isMobile ? 250 : 300,
                      child: _buildMascotAnimation(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '!Terminaste tu sesion!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRewardCard(
                        title: 'Experiencia Total',
                        titleColor: const Color(0xFF3B82F6),
                        value: '+$pomodoroMins XP',
                      ),
                      const SizedBox(width: 8),
                      _buildRewardCard(
                        title: 'Monedas',
                        titleColor: const Color(0xFFF59E0B),
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset('assets/icons/Moneda3.svg', width: 24, height: 24),
                            const SizedBox(width: 8),
                            const Text(
                              '+10',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRewardCard(
                        title: 'Tiempo',
                        titleColor: const Color(0xFF3B82F6),
                        value: '$pomodoroMins\nminutos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Column(
                    children: [
                      _GradientButton(
                        label: 'Finalizar',
                        width: 250,
                        height: 45,
                        onTap: _onFinalizar,
                      ),
                      const SizedBox(height: 16),
                      _GradientButton(
                        label: 'Descanso',
                        width: 250,
                        height: 45,
                        onTap: () {
                          if (widget.isDebugMode) {
                            Navigator.of(context).pop();
                          } else {
                            final focusProvider = context.read<FocusProvider>();
                            focusProvider.setMode(TimerMode.shortBreak);
                            focusProvider.start();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardCard({
    required String title,
    required Color titleColor,
    String? value,
    Widget? valueWidget,
  }) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF191D28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: valueWidget ?? Text(
                  value ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakScreen(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 24 : 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: isMobile ? 250 : 300,
                      height: isMobile ? 250 : 300,
                      child: _buildMascotAnimation(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'dia de racha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF57C00), 
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191D28),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildWeekDays(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: _GradientButton(
                      label: 'ok',
                      width: 200,
                      height: 50,
                      gradientColors: const [
                        Color(0xFFFF9800), // Lighter orange
                        Color(0xFFF57C00), // Darker orange
                      ],
                      shadowColor: const Color(0xFFF57C00).withAlpha(60),
                      onTap: () {
                        if (widget.isDebugMode) {
                          Navigator.of(context).pop();
                        } else {
                          context.read<FocusProvider>().reset();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildWeekDays() {
    final now = DateTime.now();
    // Monday is 1, Sunday is 7. Calculate start of current week.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final List<Widget> widgets = [];
    final daysOfWeek = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
    final statsProvider = context.read<StatsProvider>();
    
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
      final dayName = daysOfWeek[i];
      
      final stats = statsProvider.getStatsForDate(day);
      final hasStreak = (stats != null && stats.focusSessions > 0) || isToday;
      
      widgets.add(
        Column(
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: hasStreak ? const Color(0xFFF57C00) : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasStreak ? const Color(0xFFF57C00) : const Color(0xFF2D3748),
              ),
              child: hasStreak 
                ? const Icon(Icons.check, size: 20, color: Colors.black)
                : null,
            ),
          ],
        ),
      );
      
      if (i < 6) {
        widgets.add(const SizedBox(width: 8));
      }
    }
    return widgets;
  }

  Widget _buildMascotAnimation() {
    return Consumer<MascotController>(
      builder: (context, mascot, _) {
        if (!mascot.isLoaded) {
          return const Center(
            child: Icon(Icons.star_rounded, size: 60, color: Color(0xFFF59E0B)),
          );
        }
        return RiveWidget(
          controller: mascot.controller!,
          fit: Fit.contain,
        );
      },
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Color? shadowColor;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.width = 250,
    this.height = 45,
    this.icon,
    this.gradientColors,
    this.shadowColor,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors ?? const [
                  Color.fromARGB(255, 0, 149, 255),
                  Color.fromARGB(255, 32, 43, 200),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor ?? AppColors.primary.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
