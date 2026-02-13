import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class DurationPickerSheet extends StatelessWidget {
  final String title;
  final int current;
  final List<int> options;
  final ValueChanged<int> onSelected;

  const DurationPickerSheet({
    super.key,
    required this.title,
    required this.current,
    required this.options,
    required this.onSelected,
  });

  /// Convenience method to show this sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required String title,
    required int current,
    required List<int> options,
    required ValueChanged<int> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DurationPickerSheet(
        title: title,
        current: current,
        options: options,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select duration in minutes',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: options.map((min) {
                  final isSelected = min == current;
                  return GestureDetector(
                    onTap: () {
                      onSelected(min);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: AppColors.textMuted.withOpacity(0.3),
                                width: 0.5,
                              ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                  color: AppColors.accentGlow,
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$min',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
