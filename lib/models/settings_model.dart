import '../core/timer_mode.dart';

class SettingsModel {
  int focusMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  bool hapticEnabled;
  bool soundEnabled;
  bool notificationsEnabled;

  SettingsModel({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.hapticEnabled = true,
    this.soundEnabled = true,
    this.notificationsEnabled = true,
  });

  /// Returns durations in seconds keyed by [TimerMode].
  Map<TimerMode, int> get durations => {
        TimerMode.focus: focusMinutes * 60,
        TimerMode.shortBreak: shortBreakMinutes * 60,
        TimerMode.longBreak: longBreakMinutes * 60,
      };

  SettingsModel copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? hapticEnabled,
    bool? soundEnabled,
    bool? notificationsEnabled,
  }) {
    return SettingsModel(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
