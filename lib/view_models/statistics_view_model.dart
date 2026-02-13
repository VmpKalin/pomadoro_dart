import 'package:flutter/foundation.dart';
import '../models/session_stats.dart';

class StatisticsViewModel extends ChangeNotifier {
  final SessionStats stats;

  StatisticsViewModel({required this.stats});

  int get todaySessions => stats.todaySessions;
  int get todayFocusMinutes => stats.todayFocusMinutes;
  int get weekSessions => stats.weekSessions;
  int get streakDays => stats.streakDays;
  bool get hasSessions => stats.todaySessions > 0;

  int get avgSessionMinutes => todaySessions > 0
      ? (todayFocusMinutes / todaySessions).round()
      : 0;

  double get dailyGoalProgress => (todaySessions / 8).clamp(0.0, 1.0);

  void resetStats() {
    stats.reset();
    notifyListeners();
  }

  /// Call this to notify the view after a session is recorded externally.
  void refresh() => notifyListeners();
}
