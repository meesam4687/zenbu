import 'package:flutter/material.dart';

class PieProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final bool isPaused;

  const PieProgressIndicator({
    super.key,
    required this.progress,
    required this.isPaused,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: PieProgressPainter(
            progress: progress,
            color: isPaused ? colorScheme.outline : colorScheme.primary,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        if (isPaused)
          Icon(
            Icons.pause_rounded,
            size: size * 0.6,
            color: colorScheme.outline,
          ),
      ],
    );
  }
}

class PieProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  PieProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = backgroundColor;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);

    paint.color = color;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sweepAngle = (progress.clamp(0.0, 1.0)) * 2 * 3.141592653589793;
    canvas.drawArc(rect, -3.141592653589793 / 2, sweepAngle, true, paint);
  }

  @override
  bool shouldRepaint(covariant PieProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
