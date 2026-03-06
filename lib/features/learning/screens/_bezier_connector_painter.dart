import 'package:flutter/material.dart';

class BezierConnectorPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double strokeWidth;

  BezierConnectorPainter(this.path, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BezierConnectorPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
