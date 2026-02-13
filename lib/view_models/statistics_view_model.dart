import 'package:flutter/foundation.dart';
import '../models/session_stats.dart';
import '../services/storage_service.dart';

class StatisticsViewModel extends ChangeNotifier {
  final SessionStats stats;

  StatisticsViewModel({required this.stats});

  int get todaySessions => stats.todaySessions;
  int get todayFocusMinutes => stats.todayFocusMinutes;
  int get weekSessions => stats.weekSessions;
  int get streakDays => stats.streakDays;
  int get totalSessions => stats.totalSessions;
  int get totalFocusMinutes => stats.totalFocusMinutes;
  bool get hasSessions => stats.todaySessions > 0 || stats.totalSessions > 0;

  int get avgSessionMinutes => todaySessions > 0
      ? (todayFocusMinutes / todaySessions).round()
      : 0;

  double get dailyGoalProgress => (todaySessions / 8).clamp(0.0, 1.0);

  void resetStats() {
    stats.reset();
    StorageService.clearStats();
    notifyListeners();
  }

  /// Call this after a session is recorded externally to save & update UI.
  void refresh() {
    StorageService.saveStats(stats);
    notifyListeners();
  }
}
