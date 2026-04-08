import 'package:equatable/equatable.dart';

enum TimerStatus { idle, running, paused, finished }

enum TimerMode { pomodoro, shortBreak, longBreak }

class TimerState extends Equatable {
  final TimerStatus status;
  final TimerMode mode;
  final int remainingSeconds;
  final int totalSeconds;
  final int completedSessions;
  final int totalFocusMinutes;
  final String? activeTaskId;
  final String? activeTaskTitle;
  final bool quizDue;
  final int quizCorrectCount;
  final int quizTotalCount;

  const TimerState({
    this.status = TimerStatus.idle,
    this.mode = TimerMode.pomodoro,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.completedSessions = 0,
    this.totalFocusMinutes = 0,
    this.activeTaskId,
    this.activeTaskTitle,
    this.quizDue = false,
    this.quizCorrectCount = 0,
    this.quizTotalCount = 0,
  });

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;
  bool get isFinished => status == TimerStatus.finished;

  TimerState copyWith({
    TimerStatus? status,
    TimerMode? mode,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedSessions,
    int? totalFocusMinutes,
    String? activeTaskId,
    String? activeTaskTitle,
    bool? quizDue,
    int? quizCorrectCount,
    int? quizTotalCount,
  }) {
    return TimerState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      activeTaskTitle: activeTaskTitle ?? this.activeTaskTitle,
      quizDue: quizDue ?? this.quizDue,
      quizCorrectCount: quizCorrectCount ?? this.quizCorrectCount,
      quizTotalCount: quizTotalCount ?? this.quizTotalCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mode,
    remainingSeconds,
    totalSeconds,
    completedSessions,
    totalFocusMinutes,
    activeTaskId,
    activeTaskTitle,
    quizDue,
    quizCorrectCount,
    quizTotalCount,
  ];
}
