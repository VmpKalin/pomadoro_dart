import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class TickPainter extends CustomPainter {
  final Color activeColor;
  final double progress;

  TickPainter({required this.activeColor, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width - 6) / 2;
    const tickLength = 6.0;

    for (int i = 0; i < 60; i++) {
      final angle = -pi / 2 + (2 * pi * i / 60);
      final isMajor = i % 5 == 0;
      final len = isMajor ? tickLength + 2 : tickLength;
      final fraction = i / 60;
      final isActive = fraction <= progress;

      final outerPoint = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (outerRadius - len) * cos(angle),
        center.dy + (outerRadius - len) * sin(angle),
      );

      final paint = Paint()
        ..color = isActive
            ? activeColor.withOpacity(isMajor ? 0.5 : 0.2)
            : AppColors.textMuted.withOpacity(isMajor ? 0.3 : 0.1)
        ..strokeWidth = isMajor ? 1.5 : 0.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TickPainter old) =>
      old.progress != progress || old.activeColor != activeColor;
}
