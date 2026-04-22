import 'package:flutter/material.dart';

enum TimerSize { small, medium }

class SettingsProvider extends ChangeNotifier {
  double _pomodoroDuration = 25;
  double _shortBreakDuration = 5;
  double _longBreakDuration = 15;
  bool _notificationsEnabled = true;
  TimerSize _timerSize = TimerSize.medium;
  bool _autoPauseTimer = true;
  bool _minimizeToTray = true;
  bool _strictMode = false;
  bool _hideFocusCards = false;
  bool _focusQuizEnabled = true;
  double _focusQuizIntervalMinutes = 5;

  double get pomodoroDuration => _pomodoroDuration;
  double get shortBreakDuration => _shortBreakDuration;
  double get longBreakDuration => _longBreakDuration;
  bool get notificationsEnabled => _notificationsEnabled;
  TimerSize get timerSize => _timerSize;
  bool get autoPauseTimer => _autoPauseTimer;
  bool get minimizeToTray => _minimizeToTray;
  bool get strictMode => _strictMode;
  bool get hideFocusCards => _hideFocusCards;
  bool get focusQuizEnabled => _focusQuizEnabled;
  double get focusQuizIntervalMinutes => _focusQuizIntervalMinutes;

  double get timerSizeMultiplier {
    switch (_timerSize) {
      case TimerSize.small:
        return 0.8;
      case TimerSize.medium:
        return 1.0;
    }
  }

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

  void setTimerSize(TimerSize size) {
    if (_timerSize == size) return;
    _timerSize = size;
    notifyListeners();
  }

  void setAutoPauseTimer(bool value) {
    if (_autoPauseTimer == value) return;
    _autoPauseTimer = value;
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    if (_minimizeToTray == value) return;
    _minimizeToTray = value;
    notifyListeners();
  }

  void setStrictMode(bool value) {
    if (_strictMode == value) return;
    _strictMode = value;
    if (_strictMode) {
      _autoPauseTimer = true;
    }
    notifyListeners();
  }

  void setHideFocusCards(bool value) {
    if (_hideFocusCards == value) return;
    _hideFocusCards = value;
    notifyListeners();
  }

  void setFocusQuizEnabled(bool value) {
    if (_focusQuizEnabled == value) return;
    _focusQuizEnabled = value;
    notifyListeners();
  }

  void setFocusQuizIntervalMinutes(double value) {
    if (_focusQuizIntervalMinutes == value) return;
    _focusQuizIntervalMinutes = value;
    notifyListeners();
  }
}
