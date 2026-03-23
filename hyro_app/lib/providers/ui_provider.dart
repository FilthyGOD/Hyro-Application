import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

class UiProvider with ChangeNotifier {
  bool _isMusicBarVisible = true;
  bool _isMusicBarMinimized = false;
  bool _isMiniMode = false;

  bool get isMusicBarVisible => _isMusicBarVisible;
  bool get isMusicBarMinimized => _isMusicBarMinimized;
  bool get isMiniMode => _isMiniMode;

  void toggleMusicBar() {
    _isMusicBarVisible = !_isMusicBarVisible;
    notifyListeners();
  }

  void setMusicBarVisibility(bool visible) {
    _isMusicBarVisible = visible;
    notifyListeners();
  }

  void setMusicBarMinimized(bool minimized) {
    _isMusicBarMinimized = minimized;
    notifyListeners();
  }

  Future<void> setMiniMode(bool mini) async {
    if (_isMiniMode == mini) return;
    _isMiniMode = mini;
    
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mini) {
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setResizable(false);
        await windowManager.setMinimumSize(const Size(280, 380));
        await windowManager.setSize(const Size(280, 380));
      } else {
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setResizable(true);
        await windowManager.setMinimumSize(const Size(600, 800));
        await windowManager.setSize(const Size(1280, 800));
        await windowManager.center();
      }
    }
    notifyListeners();
  }
}
