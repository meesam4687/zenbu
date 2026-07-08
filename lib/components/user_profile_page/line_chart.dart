import 'dart:math';
import 'package:flutter/material.dart';

class LineChart extends StatefulWidget {
  const LineChart({super.key, required this.title, required this.data});

  final String title;
  final Map<int, int> data;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (widget.data.isEmpty) {
      return Container();
    }

    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sortedData = Map.fromEntries(sortedEntries);

    final minYear = sortedData.keys.first;
    final maxYear = sortedData.keys.last;
    final maxCount = sortedData.values.fold(
      0,
      (max, val) => val > max ? val : max,
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.onInverseSurface,
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
              widget.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final int yearRange = max(1, maxYear - minYear);

                return GestureDetector(
                  onTapUp: (details) {
                    final localPos = details.localPosition;
                    int? closestYear;
                    double closestDist = double.infinity;

                    sortedData.forEach((year, count) {
                      final double x =
                          ((year - minYear) / yearRange) * chartWidth;
                      final dist = (x - localPos.dx).abs();
                      if (dist < closestDist) {
                        closestDist = dist;
                        closestYear = year;
                      }
                    });

                    if (closestYear != null && closestDist < 30.0) {
                      setState(() {
                        _selectedYear = (_selectedYear == closestYear)
                            ? null
                            : closestYear;
                      });
                    }
                  },
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        data: sortedData,
                        minYear: minYear,
                        maxYear: maxYear,
                        maxCount: maxCount,
                        selectedYear: _selectedYear,
                        primaryColor: theme.colorScheme.primary,
                        gridColor: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.2,
                        ),
                        labelStyle: textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minYear',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${minYear + (maxYear - minYear) ~/ 2}',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$maxYear',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _LineChartPainter extends CustomPainter {
  final Map<int, int> data;
  final int minYear;
  final int maxYear;
  final int maxCount;
  final int? selectedYear;
  final Color primaryColor;
  final Color gridColor;
  final TextStyle labelStyle;

  _LineChartPainter({
    required this.data,
    required this.minYear,
    required this.maxYear,
    required this.maxCount,
    required this.selectedYear,
    required this.primaryColor,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final y = height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      final labelVal = maxCount - (maxCount * (i / 2)).toInt();
      final textSpan = TextSpan(text: '$labelVal', style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(4, y - 12));
    }

    final int yearRange = max(1, maxYear - minYear);
    final double maxVal = max(1, maxCount).toDouble();

    final List<Offset> points = [];
    data.forEach((year, count) {
      final double x = ((year - minYear) / yearRange) * width;
      final double y = height - ((count / maxVal) * height);
      points.add(Offset(x, y));
    });

    if (points.isEmpty) return;

    final fillPath = Path()..moveTo(points.first.dx, height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.3),
          primaryColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 4.0, dotStrokePaint);
    }

    if (selectedYear != null && data.containsKey(selectedYear)) {
      final count = data[selectedYear]!;
      final double x = ((selectedYear! - minYear) / yearRange) * width;
      final double y = height - ((count / maxVal) * height);
      final selectedOffset = Offset(x, y);

      final guidePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, 0), Offset(x, height), guidePaint);

      final highlightPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      final highlightStroke = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(selectedOffset, 6.0, highlightPaint);
      canvas.drawCircle(selectedOffset, 6.0, highlightStroke);

      final tooltipText = "$count entries in $selectedYear";
      final textSpan = TextSpan(
        text: tooltipText,
        style: labelStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final tooltipX = (x - textPainter.width / 2).clamp(
        4.0,
        width - textPainter.width - 4.0,
      );
      final tooltipY = (y - 28.0).clamp(4.0, height - 15.0);

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          tooltipX - 6,
          tooltipY - 4,
          textPainter.width + 12,
          textPainter.height + 8,
        ),
        const Radius.circular(6),
      );
      final bgPaint = Paint()..color = primaryColor;
      canvas.drawRRect(bgRect, bgPaint);

      textPainter.paint(canvas, Offset(tooltipX, tooltipY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
