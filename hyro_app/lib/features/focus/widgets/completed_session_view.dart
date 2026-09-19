import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Animation;
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/focus_provider.dart';
import '../providers/focus_state.dart';
import '../../settings/settings_provider.dart';
import '../../mascot/mascot_controller.dart';
import 'package:provider/provider.dart';
import '../../stats/stats_provider.dart';

class CompletedSessionView extends StatefulWidget {
  final int streak;
  final bool initialShowStreakScreen;
  const CompletedSessionView({
    super.key,
    required this.streak,
    this.initialShowStreakScreen = false,
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
    // Dispara la animación de festejo cuando aparece esta vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotController>().triggerFestejo();
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
    } else {
      if (widget.initialShowStreakScreen) {
        Navigator.of(context).pop();
      } else {
        context.read<FocusProvider>().reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showStreakScreen) {
      return _buildStreakScreen(context);
    }
    return _buildSessionFinishedScreen(context);
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
                    child: _buildFestejoAnimation(isMobile),
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
                      SizedBox(
                        width: 250,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: _onFinalizar,
                          child: const Text('Finalizar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 250,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: () {
                            if (widget.initialShowStreakScreen) {
                              Navigator.of(context).pop();
                            } else {
                              final focusProvider = context.read<FocusProvider>();
                              focusProvider.setMode(TimerMode.shortBreak);
                              focusProvider.start();
                            }
                          },
                          child: const Text('Descanso', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
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
                      width: isMobile ? 180 : 250,
                      height: isMobile ? 220 : 300,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: 0,
                            child: _buildFestejoAnimation(isMobile),
                          ),
                          Positioned(
                            top: -20,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/LlamaRacha.svg',
                                  width: 100,
                                  height: 100,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    '$streak',
                                    style: const TextStyle(
                                      color: Color(0xFFC62828), 
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          if (widget.initialShowStreakScreen) {
                            Navigator.of(context).pop();
                          } else {
                            context.read<FocusProvider>().reset();
                          }
                        },
                        child: const Text('ok', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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
    final List<Widget> widgets = [];
    final daysOfWeek = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final isToday = (i == 0);
      final dayName = daysOfWeek[day.weekday - 1];
      bool isChecked = isToday;
      
      widgets.add(
        Column(
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isChecked ? const Color(0xFFF57C00) : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? const Color(0xFFF57C00) : const Color(0xFF2D3748),
              ),
              child: isChecked 
                ? const Icon(Icons.check, size: 20, color: Colors.black)
                : null,
            ),
          ],
        ),
      );
      
      if (i > 0) {
        widgets.add(const SizedBox(width: 8));
      }
    }
    return widgets;
  }

  Widget _buildFestejoAnimation(bool isMobile) {
    final size = isMobile ? 150.0 : 200.0;
    return Consumer<MascotController>(
      builder: (context, mascot, _) {
        if (!mascot.isLoaded) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: Icon(Icons.star_rounded, size: 60, color: Color(0xFFF59E0B)),
            ),
          );
        }
        return SizedBox(
          width: size,
          height: size,
          child: RiveWidget(
            controller: mascot.controller!,
            fit: Fit.contain,
          ),
        );
      },
    );
  }
}
