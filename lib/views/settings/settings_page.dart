import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../view_models/settings_view_model.dart';
import '../../view_models/statistics_view_model.dart';
import '../../widgets/settings/duration_row.dart';
import '../../widgets/settings/toggle_row.dart';
import '../../widgets/settings/info_row.dart';
import '../../widgets/settings/section_divider.dart';
import '../../widgets/settings/duration_picker_sheet.dart';

class SettingsPage extends StatelessWidget {
  final SettingsViewModel viewModel;
  final StatisticsViewModel statisticsViewModel;

  const SettingsPage({
    super.key,
    required this.viewModel,
    required this.statisticsViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize your experience',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Timer section
            _sectionTitle('Timer'),
            Container(
              decoration: _sectionDecoration(),
              child: Column(
                children: [
                  DurationRow(
                    icon: Icons.timer_rounded,
                    label: 'Focus duration',
                    minutes: viewModel.focusMinutes,
                    color: AppColors.accent,
                    onTap: () => DurationPickerSheet.show(
                      context,
                      title: 'Focus Duration',
                      current: viewModel.focusMinutes,
                      options: viewModel.focusOptions,
                      onSelected: viewModel.setFocusDuration,
                    ),
                  ),
                  const SectionDivider(),
                  DurationRow(
                    icon: Icons.coffee_rounded,
                    label: 'Short break',
                    minutes: viewModel.shortBreakMinutes,
                    color: AppColors.breakAccent,
                    onTap: () => DurationPickerSheet.show(
                      context,
                      title: 'Short Break',
                      current: viewModel.shortBreakMinutes,
                      options: viewModel.shortBreakOptions,
                      onSelected: viewModel.setShortBreak,
                    ),
                  ),
                  const SectionDivider(),
                  DurationRow(
                    icon: Icons.self_improvement_rounded,
                    label: 'Long break',
                    minutes: viewModel.longBreakMinutes,
                    color: const Color(0xFF7B8CDE),
                    onTap: () => DurationPickerSheet.show(
                      context,
                      title: 'Long Break',
                      current: viewModel.longBreakMinutes,
                      options: viewModel.longBreakOptions,
                      onSelected: viewModel.setLongBreak,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences section
            _sectionTitle('Preferences'),
            Container(
              decoration: _sectionDecoration(),
              child: Column(
                children: [
                  ToggleRow(
                    icon: Icons.volume_up_rounded,
                    label: 'Completion sound',
                    value: viewModel.soundEnabled,
                    color: const Color(0xFFF4A261),
                    onChanged: (_) => viewModel.toggleSound(),
                  ),
                  const SectionDivider(),
                  ToggleRow(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    value: viewModel.notificationsEnabled,
                    color: const Color(0xFFB983FF),
                    onChanged: (_) => viewModel.toggleNotifications(),
                  ),
                  const SectionDivider(),
                  ToggleRow(
                    icon: Icons.vibration_rounded,
                    label: 'Haptic feedback',
                    value: viewModel.hapticEnabled,
                    color: AppColors.accent,
                    onChanged: (_) => viewModel.toggleHaptic(),
                  ),
                  const SectionDivider(),
                  const InfoRow(
                    icon: Icons.dark_mode_rounded,
                    label: 'Theme',
                    value: 'Dark',
                    color: Color(0xFF7B8CDE),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About section
            _sectionTitle('About'),
            Container(
              decoration: _sectionDecoration(),
              child: const Column(
                children: [
                  InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    value: '1.0.0',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reset
            Center(
              child: TextButton(
                onPressed: () => _showResetConfirmation(context),
                child: const Text(
                  'Reset all statistics',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 2,
        ),
      ),
    );
  }

  BoxDecoration _sectionDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.surfaceLight, width: 0.5),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reset Statistics',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will clear all your session history. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              statisticsViewModel.resetStats();
              Navigator.pop(ctx);
            },
            child: const Text('Reset',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
