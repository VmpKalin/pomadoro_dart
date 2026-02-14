import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/timer_mode.dart';
import '../models/timer_state.dart';
import '../models/settings_model.dart';
import '../models/session_stats.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';

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
        ) {
    // Listen for notification-button actions (Pause / Resume / Stop)
    // that the user triggers from the lock-screen or notification shade.
    NotificationService.onServiceAction = _onServiceAction;
  }

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

  // ─── Actions (from Flutter UI) ────────────────────────────────────────

  void toggleTimer() {
    final running = !_state.isRunning;
    _state = _state.copyWith(isRunning: running);

    if (running) {
      _startTimerInternal();
      // ── Notification: start countdown ──
      if (settings.notificationsEnabled) {
        NotificationService.start(
          endTimeMillis: _targetEndTime!.millisecondsSinceEpoch,
          title: _state.modeLabel,
          mode: _state.mode.name,
        );
      }
    } else {
      _pauseTimerInternal();
      // ── Notification: show "Paused" ──
      if (settings.notificationsEnabled) {
        NotificationService.pause(
          remainingMillis: _state.remainingSeconds * 1000,
        );
      }
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

    // ── Notification: remove ──
    NotificationService.stop();

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

    // ── Notification: remove (mode changed, old countdown is invalid) ──
    NotificationService.stop();

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
      // The foreground service keeps the notification alive — no extra call
      // needed here. The service already has the correct endTimeMillis.
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

  // ─── Notification-button callbacks ────────────────────────────────────

  /// Handles actions triggered from the Android notification buttons.
  ///
  /// These arrive via [NotificationService.onServiceAction] when the Flutter
  /// engine is attached. The native service has **already** updated its own
  /// state, so we only need to sync the Flutter-side ViewModel — no need to
  /// call back into the service.
  void _onServiceAction(String action, int remainingMillis, bool isPaused) {
    switch (action) {
      case 'paused':
        if (!_state.isRunning) return; // already paused in Flutter
        _pauseTimerInternal();
        _state = _state.copyWith(
          isRunning: false,
          remainingSeconds: (remainingMillis / 1000).round(),
        );
        notifyListeners();
        break;

      case 'resumed':
        if (_state.isRunning) return; // already running
        _state = _state.copyWith(isRunning: true);
        _startTimerInternal();
        notifyListeners();
        break;

      case 'stopped':
        _timer?.cancel();
        _targetEndTime = null;
        final total = settings.durations[_state.mode]!;
        _state = _state.copyWith(
          totalSeconds: total,
          remainingSeconds: total,
          isRunning: false,
        );
        notifyListeners();
        break;

      case 'toggleRequested':
        // Pause/Resume requested from notification (iOS Live Activity button).
        toggleTimer();
        break;

      case 'skipRequested':
        // Skip to next session requested from notification button.
        _handleSkipFromNotification();
        break;
    }
  }

  // ─── Skip from notification ──────────────────────────────────────────

  /// Handles a "Skip" action from the notification or Live Activity.
  ///
  /// Advances to the next session (focus→break or break→focus) and
  /// auto-starts the new timer with an updated notification — no need
  /// for the user to open the app.
  void _handleSkipFromNotification() {
    _timer?.cancel();
    _targetEndTime = null;

    if (settings.hapticEnabled) HapticFeedback.heavyImpact();
    // No completion sound on skip — it's intentional, not a timer finish.

    // ── Switch to next mode (same logic as _onTimerComplete) ──
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

    // ── Auto-start the new timer ──
    _state = _state.copyWith(isRunning: true);
    _startTimerInternal();

    if (settings.notificationsEnabled) {
      NotificationService.start(
        endTimeMillis: _targetEndTime!.millisecondsSinceEpoch,
        title: _state.modeLabel,
        mode: _state.mode.name,
      );
    }

    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  /// Starts the Dart-side periodic timer and records the absolute end time.
  void _startTimerInternal() {
    _targetEndTime =
        DateTime.now().add(Duration(seconds: _state.remainingSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Cancels the Dart-side periodic timer.
  void _pauseTimerInternal() {
    _timer?.cancel();
    _targetEndTime = null;
  }

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

    // ── Notification: remove (service shows "Finished!" on its own) ──
    NotificationService.stop();

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
    NotificationService.onServiceAction = null;
    super.dispose();
  }
}
