import 'package:flutter/material.dart';

class UiProvider with ChangeNotifier {
  bool _isMusicBarVisible = true;
  bool _isMusicBarMinimized = false;

  bool get isMusicBarVisible => _isMusicBarVisible;
  bool get isMusicBarMinimized => _isMusicBarMinimized;

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
}
