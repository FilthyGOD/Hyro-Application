import 'package:flutter/material.dart';

class UiProvider with ChangeNotifier {
  bool _isMusicBarVisible = true;

  bool get isMusicBarVisible => _isMusicBarVisible;

  void toggleMusicBar() {
    _isMusicBarVisible = !_isMusicBarVisible;
    notifyListeners();
  }

  void setMusicBarVisibility(bool visible) {
    _isMusicBarVisible = visible;
    notifyListeners();
  }
}
