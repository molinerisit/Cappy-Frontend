import 'package:flutter/material.dart';
import 'dart:ui';
import 'path_layout_engine.dart';

class RoadmapCanvas extends StatelessWidget {
  final LayoutResult layout;
  final double width;
  final double height;
  const RoadmapCanvas({
    required this.layout,
    required this.width,
    required this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, height),
        painter: _RoadmapPainterPremium(layout),
      ),
    );
  }
}

class _RoadmapPainterPremium extends CustomPainter {
  final LayoutResult layout;
  _RoadmapPainterPremium(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF3B82F6) // premium blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final pair in layout.connections) {
      if (pair.length < 2) continue;
      final from = pair[0];
      final to = pair[1];
      final start = layout.positions[from];
      final end = layout.positions[to];
      final midY = (start.dy + end.dy) / 2;
      final path = Path();
      path.moveTo(start.dx, start.dy + 36);
      path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy - 36);
      canvas.drawShadow(
        path,
        const Color(0xFF3B82F6).withOpacity(0.10),
        6,
        false,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RoadmapPainterPremium oldDelegate) =>
      oldDelegate.layout != layout;
}
