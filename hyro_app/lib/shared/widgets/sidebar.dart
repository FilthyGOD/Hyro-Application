import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Sidebar navigation for the Hyro app.
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
      label: 'Focus',
    ),
    _SidebarItemData(
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle,
      label: 'Tasks',
    ),
    _SidebarItemData(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Stats',
    ),
    _SidebarItemData(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Shop',
    ),
    _SidebarItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
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
          // ── Logo ──
          _buildLogo(),
          const SizedBox(height: 36),
          // ── Nav items ──
          ...List.generate(_items.length, (i) {
            return _SidebarItem(
              icon: selectedIndex == i ? _items[i].activeIcon : _items[i].icon,
              label: _items[i].label,
              isActive: selectedIndex == i,
              collapsed: collapsed,
              onTap: () => onItemSelected(i),
            );
          }),
          const Spacer(),
          // ── Settings ──
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: false,
            collapsed: collapsed,
            onTap: () => onItemSelected(5),
          ),
          const SizedBox(height: 12),
          // ── User avatar ──
          if (!collapsed) _buildUserInfo(),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
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

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('H', style: AppTypography.labelLarge),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User',
                    style: AppTypography.labelLarge.copyWith(fontSize: 13),
                  ),
                  Text(
                    'Free Plan',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _SidebarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
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
