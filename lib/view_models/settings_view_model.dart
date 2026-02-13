import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsModel settings;

  SettingsViewModel({required this.settings});

  // ─── Getters ──────────────────────────────────────────────────────────

  int get focusMinutes => settings.focusMinutes;
  int get shortBreakMinutes => settings.shortBreakMinutes;
  int get longBreakMinutes => settings.longBreakMinutes;
  bool get hapticEnabled => settings.hapticEnabled;
  bool get soundEnabled => settings.soundEnabled;
  bool get notificationsEnabled => settings.notificationsEnabled;

  // ─── Duration Options ─────────────────────────────────────────────────

  List<int> get focusOptions => [15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
  List<int> get shortBreakOptions => [1, 2, 3, 5, 7, 10, 15];
  List<int> get longBreakOptions => [10, 15, 20, 25, 30];

  // ─── Setters ──────────────────────────────────────────────────────────

  void setFocusDuration(int minutes) {
    settings.focusMinutes = minutes;
    _persist();
  }

  void setShortBreak(int minutes) {
    settings.shortBreakMinutes = minutes;
    _persist();
  }

  void setLongBreak(int minutes) {
    settings.longBreakMinutes = minutes;
    _persist();
  }

  void toggleHaptic() {
    settings.hapticEnabled = !settings.hapticEnabled;
    _persist();
  }

  void toggleSound() {
    settings.soundEnabled = !settings.soundEnabled;
    _persist();
    if (settings.soundEnabled) {
      SoundService.playCompletion();
    }
  }

  void toggleNotifications() {
    settings.notificationsEnabled = !settings.notificationsEnabled;
    _persist();
  }

  // ─── Persistence ──────────────────────────────────────────────────────

  void _persist() {
    notifyListeners();
    StorageService.saveSettings(settings);
  }
}
