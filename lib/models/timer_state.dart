import '../core/timer_mode.dart';

class TimerState {
  final TimerMode mode;
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final int completedPomodoros;

  const TimerState({
    this.mode = TimerMode.focus,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.isRunning = false,
    this.completedPomodoros = 0,
  });

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  String get timeDisplay {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get modeLabel {
    switch (mode) {
      case TimerMode.focus:
        return 'FOCUS';
      case TimerMode.shortBreak:
        return 'SHORT BREAK';
      case TimerMode.longBreak:
        return 'LONG BREAK';
    }
  }

  TimerState copyWith({
    TimerMode? mode,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    int? completedPomodoros,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    );
  }
}
