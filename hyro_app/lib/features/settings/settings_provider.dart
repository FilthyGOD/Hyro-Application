import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerSize { small, medium }

enum MascotBubbleMode { normal, none, glass }

class SettingsProvider extends ChangeNotifier {
  double _pomodoroDuration = 25;
  double _shortBreakDuration = 5;
  double _longBreakDuration = 15;
  bool _notificationsEnabled = true;
  TimerSize _timerSize = TimerSize.medium;
  MascotBubbleMode _mascotBubbleMode = MascotBubbleMode.normal;
  bool _autoPauseTimer = true;
  bool _minimizeToTray = true;
  bool _strictMode = false;
  bool _hideFocusCards = false;
  bool _focusQuizEnabled = true;
  double _focusQuizIntervalMinutes = 5;

  SharedPreferences? _prefs;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _pomodoroDuration = _prefs?.getDouble('pomodoroDuration') ?? 25;
    _shortBreakDuration = _prefs?.getDouble('shortBreakDuration') ?? 5;
    _longBreakDuration = _prefs?.getDouble('longBreakDuration') ?? 15;
    _notificationsEnabled = _prefs?.getBool('notificationsEnabled') ?? true;
    _timerSize = TimerSize.values[_prefs?.getInt('timerSize') ?? 1]; // 1 is medium
    _mascotBubbleMode = MascotBubbleMode.values[
      (_prefs?.getInt('mascotBubbleMode') ?? 0).clamp(0, MascotBubbleMode.values.length - 1)
    ];
    _autoPauseTimer = _prefs?.getBool('autoPauseTimer') ?? true;
    _minimizeToTray = _prefs?.getBool('minimizeToTray') ?? true;
    _strictMode = _prefs?.getBool('strictMode') ?? false;
    _hideFocusCards = _prefs?.getBool('hideFocusCards') ?? false;
    _focusQuizEnabled = _prefs?.getBool('focusQuizEnabled') ?? true;
    _focusQuizIntervalMinutes = _prefs?.getDouble('focusQuizIntervalMinutes') ?? 5;

    notifyListeners();
  }

  double get pomodoroDuration => _pomodoroDuration;
  double get shortBreakDuration => _shortBreakDuration;
  double get longBreakDuration => _longBreakDuration;
  bool get notificationsEnabled => _notificationsEnabled;
  TimerSize get timerSize => _timerSize;
  MascotBubbleMode get mascotBubbleMode => _mascotBubbleMode;
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
    _prefs?.setDouble('pomodoroDuration', value);
    notifyListeners();
  }

  void setShortBreakDuration(double value) {
    if (_shortBreakDuration == value) return;
    _shortBreakDuration = value;
    _prefs?.setDouble('shortBreakDuration', value);
    notifyListeners();
  }

  void setLongBreakDuration(double value) {
    if (_longBreakDuration == value) return;
    _longBreakDuration = value;
    _prefs?.setDouble('longBreakDuration', value);
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    _prefs?.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  void setTimerSize(TimerSize size) {
    if (_timerSize == size) return;
    _timerSize = size;
    _prefs?.setInt('timerSize', size.index);
    notifyListeners();
  }

  void setMascotBubbleMode(MascotBubbleMode mode) {
    if (_mascotBubbleMode == mode) return;
    _mascotBubbleMode = mode;
    _prefs?.setInt('mascotBubbleMode', mode.index);
    notifyListeners();
  }

  void setAutoPauseTimer(bool value) {
    if (_autoPauseTimer == value) return;
    _autoPauseTimer = value;
    _prefs?.setBool('autoPauseTimer', value);
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    if (_minimizeToTray == value) return;
    _minimizeToTray = value;
    _prefs?.setBool('minimizeToTray', value);
    notifyListeners();
  }

  void setStrictMode(bool value) {
    if (_strictMode == value) return;
    _strictMode = value;
    _prefs?.setBool('strictMode', value);
    if (_strictMode) {
      _autoPauseTimer = true;
      _prefs?.setBool('autoPauseTimer', true);
    }
    notifyListeners();
  }

  void setHideFocusCards(bool value) {
    if (_hideFocusCards == value) return;
    _hideFocusCards = value;
    _prefs?.setBool('hideFocusCards', value);
    notifyListeners();
  }

  void setFocusQuizEnabled(bool value) {
    if (_focusQuizEnabled == value) return;
    _focusQuizEnabled = value;
    _prefs?.setBool('focusQuizEnabled', value);
    notifyListeners();
  }

  void setFocusQuizIntervalMinutes(double value) {
    if (_focusQuizIntervalMinutes == value) return;
    _focusQuizIntervalMinutes = value;
    _prefs?.setDouble('focusQuizIntervalMinutes', value);
    notifyListeners();
  }
}
