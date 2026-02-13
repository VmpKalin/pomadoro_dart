import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: AppColors.surfaceLight,
      ),
    );
  }
}
