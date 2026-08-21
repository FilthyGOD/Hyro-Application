import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Barra de navegación lateral para la aplicación Hyro.
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool collapsed;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.collapsed = false,
  });

  static const _items = [
    _SidebarItemData(
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer,
      label: 'Enfoque',
      targetIndex: 2,
    ),
    _SidebarItemData(
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle,
      label: 'Tareas',
      targetIndex: 3,
    ),
    _SidebarItemData(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Desafíos',
      targetIndex: 1,
    ),
    _SidebarItemData(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Tienda',
      targetIndex: 0,
    ),
    _SidebarItemData(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Amigos',
      targetIndex: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: collapsed ? 72 : 220,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // ── Logotipo ──
          _buildLogo(),
          const SizedBox(height: 36),
          // ── Elementos de navegación ──
          ..._items.map((item) {
            return _SidebarItem(
              icon:
                  selectedIndex == item.targetIndex
                      ? item.activeIcon
                      : item.icon,
              label: item.label,
              isActive: selectedIndex == item.targetIndex,
              collapsed: collapsed,
              onTap: () => onItemSelected(item.targetIndex),
            );
          }),
          const Spacer(),
          // ── Avatar del usuario ──
          _buildUserInfo(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 16 : 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Text('Hyro', style: AppTypography.h2),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final isActive = selectedIndex == 5;
    final String? rawName = context.watch<AuthProvider>().currentUser?.name;
    final String userName =
        (rawName != null && rawName.isNotEmpty) ? rawName : 'Usuario';
    final String initial = userName.substring(0, 1).toUpperCase();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onItemSelected(5),
          child: Container(
            padding: EdgeInsets.all(collapsed ? 6 : 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.sidebarActive : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: collapsed ? 14 : 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: collapsed ? 12 : 14,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int targetIndex;

  const _SidebarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.targetIndex,
  });
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? 12 : 12,
        vertical: 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.collapsed ? 0 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isActive
                          ? AppColors.sidebarActive
                          : _hovering
                          ? AppColors.surfaceLight.withAlpha(80)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment:
                      widget.collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color:
                          widget.isActive
                              ? AppColors.sidebarActiveText
                              : AppColors.textSecondary,
                    ),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style:
                            widget.isActive
                                ? AppTypography.sidebarItemActive
                                : AppTypography.sidebarItem,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
