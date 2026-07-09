import 'package:flutter/material.dart';

class BufferedSeekBarPainter extends CustomPainter {
  final double played;
  final double buffered;
  final Color playedColor;
  final Color bufferedColor;
  final Color trackColor;
  final double trackHeight;
  final double thumbRadius;

  BufferedSeekBarPainter({
    required this.played,
    required this.buffered,
    required this.playedColor,
    required this.bufferedColor,
    required this.trackColor,
    required this.trackHeight,
    required this.thumbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double startX = thumbRadius;
    final double endX = size.width - thumbRadius;
    final double totalWidth = endX - startX;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    final bufferedPaint = Paint()
      ..color = bufferedColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    final playedPaint = Paint()
      ..color = playedColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, cy), Offset(endX, cy), trackPaint);

    final double bufX = startX + buffered.clamp(0.0, 1.0) * totalWidth;
    if (bufX > startX) {
      canvas.drawLine(Offset(startX, cy), Offset(bufX, cy), bufferedPaint);
    }

    final double playX = startX + played.clamp(0.0, 1.0) * totalWidth;
    if (playX > startX) {
      canvas.drawLine(Offset(startX, cy), Offset(playX, cy), playedPaint);
    }

    canvas.drawCircle(
      Offset(playX, cy),
      thumbRadius,
      Paint()..color = playedColor,
    );
  }

  @override
  bool shouldRepaint(BufferedSeekBarPainter old) =>
      old.played != played ||
      old.buffered != buffered ||
      old.playedColor != playedColor ||
      old.bufferedColor != bufferedColor ||
      old.trackColor != trackColor;
}
