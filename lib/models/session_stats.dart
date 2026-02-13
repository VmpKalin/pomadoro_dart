class SessionStats {
  int todaySessions;
  int todayFocusMinutes;
  int weekSessions;
  int streakDays;
  int totalSessions;
  int totalFocusMinutes;
  String lastActiveDate; // yyyy-MM-dd

  SessionStats({
    this.todaySessions = 0,
    this.todayFocusMinutes = 0,
    this.weekSessions = 0,
    this.streakDays = 0,
    this.totalSessions = 0,
    this.totalFocusMinutes = 0,
    this.lastActiveDate = '',
  });

  void recordSession(int durationMinutes) {
    todaySessions++;
    todayFocusMinutes += durationMinutes;
    weekSessions++;
    totalSessions++;
    totalFocusMinutes += durationMinutes;
    if (todaySessions == 1) streakDays++;
  }

  void reset() {
    todaySessions = 0;
    todayFocusMinutes = 0;
    weekSessions = 0;
    streakDays = 0;
    totalSessions = 0;
    totalFocusMinutes = 0;
    lastActiveDate = '';
  }
}
