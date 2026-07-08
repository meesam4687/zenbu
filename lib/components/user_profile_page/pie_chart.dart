import 'dart:math';
import 'package:flutter/material.dart';

class PieChart extends StatelessWidget {
  const PieChart({super.key, required this.title, required this.data});

  final String title;
  final Map<String, int> data;

  static const List<Color> _defaultColors = [
    Color(0xFF6750A4),
    Color(0xFF0288D1),
    Color(0xFF00796B),
    Color(0xFFE65100),
    Color(0xFFC2185B),
    Color(0xFF388E3C),
    Color(0xFFD32F2F),
    Color(0xFF7B1FA2),
    Color(0xFFFBC02D),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (data.isEmpty) {
      return Container();
    }

    final totalCount = data.values.fold(0, (sum, val) => sum + val);

    final List<_PieSegment> segments = [];
    int colorIdx = 0;
    data.forEach((label, count) {
      final color = _defaultColors[colorIdx % _defaultColors.length];
      segments.add(
        _PieSegment(
          label: label,
          count: count,
          color: color,
          percentage: totalCount > 0 ? (count / totalCount) : 0.0,
        ),
      );
      colorIdx++;
    });

    final cardBgColor = theme.colorScheme.onInverseSurface;

    return Card(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      segments: segments,
                      backgroundColor: cardBgColor,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments.map((seg) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: seg.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seg.label,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${seg.count} (${(seg.percentage * 100).toStringAsFixed(1)}%)',
                              style: textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PieSegment {
  final String label;
  final int count;
  final Color color;
  final double percentage;

  const _PieSegment({
    required this.label,
    required this.count,
    required this.color,
    required this.percentage,
  });
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final Color backgroundColor;

  _PieChartPainter({required this.segments, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    double startAngle = -pi / 2;

    for (final seg in segments) {
      final sweepAngle = seg.percentage * 2 * pi;
      if (sweepAngle > 0) {
        paint.color = seg.color;
        canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
        startAngle += sweepAngle;
      }
    }

    final innerPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
