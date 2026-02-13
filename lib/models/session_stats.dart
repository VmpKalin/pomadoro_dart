class SessionStats {
  int todaySessions;
  int todayFocusMinutes;
  int weekSessions;
  int streakDays;

  SessionStats({
    this.todaySessions = 0,
    this.todayFocusMinutes = 0,
    this.weekSessions = 0,
    this.streakDays = 0,
  });

  void recordSession(int durationMinutes) {
    todaySessions++;
    todayFocusMinutes += durationMinutes;
    weekSessions++;
    if (todaySessions == 1) streakDays++;
  }

  void reset() {
    todaySessions = 0;
    todayFocusMinutes = 0;
    weekSessions = 0;
    streakDays = 0;
  }
}
