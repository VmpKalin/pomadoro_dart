import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../models/session_stats.dart';

/// Persists settings and session statistics to device storage.
class StorageService {
  static SharedPreferences? _prefs;

  // ─── Keys ────────────────────────────────────────────────────────────────

  // Settings
  static const _kFocusMinutes = 'settings_focusMinutes';
  static const _kShortBreak = 'settings_shortBreakMinutes';
  static const _kLongBreak = 'settings_longBreakMinutes';
  static const _kHaptic = 'settings_hapticEnabled';
  static const _kSound = 'settings_soundEnabled';
  static const _kNotifications = 'settings_notificationsEnabled';

  // Stats
  static const _kTodaySessions = 'stats_todaySessions';
  static const _kTodayFocusMinutes = 'stats_todayFocusMinutes';
  static const _kWeekSessions = 'stats_weekSessions';
  static const _kStreakDays = 'stats_streakDays';
  static const _kLastActiveDate = 'stats_lastActiveDate';
  static const _kWeekStartDate = 'stats_weekStartDate';
  static const _kTotalSessions = 'stats_totalSessions';
  static const _kTotalFocusMinutes = 'stats_totalFocusMinutes';

  // ─── Init ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  static SettingsModel loadSettings() {
    final prefs = _prefs;
    if (prefs == null) return SettingsModel();

    return SettingsModel(
      focusMinutes: prefs.getInt(_kFocusMinutes) ?? 25,
      shortBreakMinutes: prefs.getInt(_kShortBreak) ?? 5,
      longBreakMinutes: prefs.getInt(_kLongBreak) ?? 15,
      hapticEnabled: prefs.getBool(_kHaptic) ?? true,
      soundEnabled: prefs.getBool(_kSound) ?? true,
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
    );
  }

  static Future<void> saveSettings(SettingsModel s) async {
    final prefs = _prefs;
    if (prefs == null) return;

    await Future.wait([
      prefs.setInt(_kFocusMinutes, s.focusMinutes),
      prefs.setInt(_kShortBreak, s.shortBreakMinutes),
      prefs.setInt(_kLongBreak, s.longBreakMinutes),
      prefs.setBool(_kHaptic, s.hapticEnabled),
      prefs.setBool(_kSound, s.soundEnabled),
      prefs.setBool(_kNotifications, s.notificationsEnabled),
    ]);
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  static SessionStats loadStats() {
    final prefs = _prefs;
    if (prefs == null) return SessionStats();

    final now = DateTime.now();
    final todayStr = _dateKey(now);
    final storedDate = prefs.getString(_kLastActiveDate) ?? '';
    final storedWeekStart = prefs.getString(_kWeekStartDate) ?? '';
    final currentWeekStart = _dateKey(_startOfWeek(now));

    // If a new day, reset daily counters
    int todaySessions;
    int todayFocusMinutes;
    if (storedDate == todayStr) {
      todaySessions = prefs.getInt(_kTodaySessions) ?? 0;
      todayFocusMinutes = prefs.getInt(_kTodayFocusMinutes) ?? 0;
    } else {
      todaySessions = 0;
      todayFocusMinutes = 0;
    }

    // If a new week, reset weekly counter
    int weekSessions;
    if (storedWeekStart == currentWeekStart) {
      weekSessions = prefs.getInt(_kWeekSessions) ?? 0;
    } else {
      weekSessions = 0;
    }

    // Streak: if user skipped a whole day, reset streak
    int streakDays = prefs.getInt(_kStreakDays) ?? 0;
    if (storedDate.isNotEmpty && storedDate != todayStr) {
      final lastActive = DateTime.tryParse(storedDate);
      if (lastActive != null) {
        final diff = now.difference(lastActive).inDays;
        if (diff > 1) {
          // Missed a day — streak broken
          streakDays = 0;
        }
      }
    }

    return SessionStats(
      todaySessions: todaySessions,
      todayFocusMinutes: todayFocusMinutes,
      weekSessions: weekSessions,
      streakDays: streakDays,
      totalSessions: prefs.getInt(_kTotalSessions) ?? 0,
      totalFocusMinutes: prefs.getInt(_kTotalFocusMinutes) ?? 0,
      lastActiveDate: storedDate,
    );
  }

  static Future<void> saveStats(SessionStats s) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final now = DateTime.now();
    await Future.wait([
      prefs.setInt(_kTodaySessions, s.todaySessions),
      prefs.setInt(_kTodayFocusMinutes, s.todayFocusMinutes),
      prefs.setInt(_kWeekSessions, s.weekSessions),
      prefs.setInt(_kStreakDays, s.streakDays),
      prefs.setInt(_kTotalSessions, s.totalSessions),
      prefs.setInt(_kTotalFocusMinutes, s.totalFocusMinutes),
      prefs.setString(_kLastActiveDate, _dateKey(now)),
      prefs.setString(_kWeekStartDate, _dateKey(_startOfWeek(now))),
    ]);
  }

  static Future<void> clearStats() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await Future.wait([
      prefs.remove(_kTodaySessions),
      prefs.remove(_kTodayFocusMinutes),
      prefs.remove(_kWeekSessions),
      prefs.remove(_kStreakDays),
      prefs.remove(_kTotalSessions),
      prefs.remove(_kTotalFocusMinutes),
      prefs.remove(_kLastActiveDate),
      prefs.remove(_kWeekStartDate),
    ]);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));
}
