import 'package:flutter/material.dart';
import '../domain/optimized_layout_engine.dart';

class RoadmapPainter extends CustomPainter {
  final List<ConnectionData> connections;
  final Color lineColor;
  final double strokeWidth;

  const RoadmapPainter({
    required this.connections,
    required this.lineColor,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final conn in connections) {
      final path = Path();
      path.moveTo(conn.startPoint.dx, conn.startPoint.dy);

      final dx = (conn.endPoint.dx - conn.startPoint.dx).abs();
      final dy = conn.endPoint.dy - conn.startPoint.dy;

      if (dx > 20) {
        final controlPointOffset = dy * 0.3;
        path.cubicTo(
          conn.startPoint.dx,
          conn.startPoint.dy + controlPointOffset,
          conn.endPoint.dx,
          conn.endPoint.dy - controlPointOffset,
          conn.endPoint.dx,
          conn.endPoint.dy,
        );
      } else {
        path.lineTo(conn.endPoint.dx, conn.endPoint.dy);
      }

      canvas.drawPath(path, paint);
    }

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (final conn in connections) {
      final midX = (conn.startPoint.dx + conn.endPoint.dx) / 2;
      final midY = (conn.startPoint.dy + conn.endPoint.dy) / 2;
      canvas.drawCircle(Offset(midX, midY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RoadmapPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
