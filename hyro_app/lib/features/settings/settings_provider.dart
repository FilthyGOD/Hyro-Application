import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  double _pomodoroDuration = 25;
  double _shortBreakDuration = 5;
  double _longBreakDuration = 15;
  bool _notificationsEnabled = true;

  double get pomodoroDuration => _pomodoroDuration;
  double get shortBreakDuration => _shortBreakDuration;
  double get longBreakDuration => _longBreakDuration;
  bool get notificationsEnabled => _notificationsEnabled;

  void setPomodoroDuration(double value) {
    if (_pomodoroDuration == value) return;
    _pomodoroDuration = value;
    notifyListeners();
  }

  void setShortBreakDuration(double value) {
    if (_shortBreakDuration == value) return;
    _shortBreakDuration = value;
    notifyListeners();
  }

  void setLongBreakDuration(double value) {
    if (_longBreakDuration == value) return;
    _longBreakDuration = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
  }
}
