import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  Widget _buildWindowAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color:
            isClose
                ? Colors.red.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      color: const Color.fromARGB(255, 11, 16, 30),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(left: 16),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          _buildWindowAction(
            icon: Icons.remove,
            onTap: () async => await windowManager.minimize(),
          ),
          const SizedBox(width: 8),
          _buildWindowAction(
            icon: Icons.crop_square,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          const SizedBox(width: 8),
          _buildWindowAction(
            icon: Icons.close,
            isClose: true,
            onTap: () async => await windowManager.close(),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
