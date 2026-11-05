import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'global_create_modal.dart';

/// Barra de navegación flotante tipo cápsula glassmórfica con botón central '+' saliente.
/// Utilizada en MainLayout, AgendaScreen y CategoryDetailScreen para mantener una experiencia unificada.
class FloatingGlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onAddTap;

  const FloatingGlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SizedBox(
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── Cápsula Glassmórfica ──
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C101A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 0,
                                  icon: Icons.storefront_outlined,
                                  activeIcon: Icons.storefront,
                                ),
                              ),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 1,
                                  icon: Icons.calendar_month_outlined,
                                  activeIcon: Icons.calendar_month_rounded,
                                ),
                              ),
                              // Espacio reservado para el botón central '+'
                              const SizedBox(width: 70),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 2,
                                  icon: Icons.timer_outlined,
                                  activeIcon: Icons.timer,
                                ),
                              ),
                              Expanded(
                                child: _buildGlassNavItem(
                                  index: 3,
                                  icon: Icons.person_outline_rounded,
                                  activeIcon: Icons.person_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Botón Agregar Central (+) Estilo Saliente Aplastado ──
                  Center(
                    child: Container(
                      width: 74,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF266EFA), Color(0xFF0448DB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0052E0).withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          onTap: onAddTap ?? () => GlobalCreateModal.show(context),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNavigate(index),
        borderRadius: BorderRadius.circular(30),
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : const Color(0xFF8A93A6),
                size: 26,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

