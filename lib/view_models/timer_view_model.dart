import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/timer_mode.dart';
import '../models/timer_state.dart';
import '../models/settings_model.dart';
import '../models/session_stats.dart';
import '../services/sound_service.dart';

class TimerViewModel extends ChangeNotifier {
  final SettingsModel settings;
  final SessionStats stats;

  TimerState _state;
  Timer? _timer;
  DateTime? _targetEndTime;

  TimerViewModel({required this.settings, required this.stats})
      : _state = TimerState(
          totalSeconds: settings.durations[TimerMode.focus]!,
          remainingSeconds: settings.durations[TimerMode.focus]!,
        );

  // ─── Getters ──────────────────────────────────────────────────────────

  TimerState get state => _state;
  TimerMode get mode => _state.mode;
  bool get isRunning => _state.isRunning;
  double get progress => _state.progress;
  String get timeDisplay => _state.timeDisplay;
  String get modeLabel => _state.modeLabel;
  int get completedPomodoros => _state.completedPomodoros;

  Color get activeColor =>
      _state.mode == TimerMode.focus
          ? const Color(0xFFE8533E)
          : const Color(0xFF3ECE8E);

  Color get activeGlow =>
      _state.mode == TimerMode.focus
          ? const Color(0x40E8533E)
          : const Color(0x403ECE8E);

  // ─── Actions ──────────────────────────────────────────────────────────

  void toggleTimer() {
    final running = !_state.isRunning;
    _state = _state.copyWith(isRunning: running);

    if (running) {
      _targetEndTime =
          DateTime.now().add(Duration(seconds: _state.remainingSeconds));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _timer?.cancel();
      _targetEndTime = null;
    }

    if (settings.hapticEnabled) HapticFeedback.lightImpact();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _targetEndTime = null;
    final total = settings.durations[_state.mode]!;
    _state = _state.copyWith(
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: false,
    );
    if (settings.hapticEnabled) HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void switchMode(TimerMode mode) {
    _timer?.cancel();
    _targetEndTime = null;
    final total = settings.durations[mode]!;
    _state = _state.copyWith(
      mode: mode,
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: false,
    );
    notifyListeners();
  }

  void skipToNext() {
    if (!_state.isRunning) _onTimerComplete();
  }

  // ─── Background Lifecycle ─────────────────────────────────────────────

  void onAppPaused() {
    if (_state.isRunning) {
      _targetEndTime =
          DateTime.now().add(Duration(seconds: _state.remainingSeconds));
      _timer?.cancel();
    }
  }

  void onAppResumed() {
    if (_targetEndTime == null) return;
    final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
    _targetEndTime = null;

    if (remaining <= 0) {
      _state = _state.copyWith(remainingSeconds: 0);
      _onTimerComplete();
    } else {
      _state = _state.copyWith(remainingSeconds: remaining);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      notifyListeners();
    }
  }

  // ─── Private ──────────────────────────────────────────────────────────

  void _tick() {
    if (_state.remainingSeconds > 0) {
      _state =
          _state.copyWith(remainingSeconds: _state.remainingSeconds - 1);
      notifyListeners();
    } else {
      _onTimerComplete();
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _targetEndTime = null;
    if (settings.hapticEnabled) HapticFeedback.heavyImpact();
    if (settings.soundEnabled) SoundService.playCompletion();

    if (_state.mode == TimerMode.focus) {
      final count = _state.completedPomodoros + 1;
      stats.recordSession(settings.focusMinutes);
      final nextMode =
          count % 4 == 0 ? TimerMode.longBreak : TimerMode.shortBreak;
      final total = settings.durations[nextMode]!;
      _state = TimerState(
        mode: nextMode,
        totalSeconds: total,
        remainingSeconds: total,
        completedPomodoros: count,
      );
    } else {
      final total = settings.durations[TimerMode.focus]!;
      _state = _state.copyWith(
        mode: TimerMode.focus,
        totalSeconds: total,
        remainingSeconds: total,
        isRunning: false,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
