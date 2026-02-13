import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/storage_service.dart';
import '../view_models/timer_view_model.dart';
import '../view_models/statistics_view_model.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/nav_item.dart';
import 'pomodoro/pomodoro_screen.dart';
import 'statistics/statistics_page.dart';
import 'settings/settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Shared models — loaded from device storage
  final _settings = StorageService.loadSettings();
  final _stats = StorageService.loadStats();

  // ViewModels
  late final TimerViewModel _timerVM;
  late final StatisticsViewModel _statsVM;
  late final SettingsViewModel _settingsVM;

  @override
  void initState() {
    super.initState();
    _timerVM = TimerViewModel(settings: _settings, stats: _stats);
    _statsVM = StatisticsViewModel(stats: _stats);
    _settingsVM = SettingsViewModel(settings: _settings);

    // When timer completes a session, refresh stats view
    _timerVM.addListener(_onTimerChanged);
    _settingsVM.addListener(_onSettingsChanged);
    _statsVM.addListener(_rebuild);
  }

  @override
  void dispose() {
    _timerVM.removeListener(_onTimerChanged);
    _settingsVM.removeListener(_onSettingsChanged);
    _statsVM.removeListener(_rebuild);
    _timerVM.dispose();
    _statsVM.dispose();
    _settingsVM.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTimerChanged() {
    _statsVM.refresh();
    setState(() {});
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PomodoroScreen(viewModel: _timerVM),
          StatisticsPage(viewModel: _statsVM),
          SettingsPage(
            viewModel: _settingsVM,
            statisticsViewModel: _statsVM,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceLight, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  icon: Icons.timer_rounded,
                  label: 'Pomodoro',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistics',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
