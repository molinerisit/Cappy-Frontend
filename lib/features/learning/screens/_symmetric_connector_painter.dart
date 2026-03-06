import 'package:flutter/material.dart';

class SymmetricConnectorPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final List<List<int>> connectionPairs;
  final Color color;
  final double strokeWidth;

  SymmetricConnectorPainter({
    required this.nodePositions,
    required this.connectionPairs,
    this.color = const Color(0xFFE5E7EB),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final pair in connectionPairs) {
      if (pair.length < 2) continue;
      final from = pair[0];
      final to = pair[1];
      if (from < 0 || to < 0) continue;
      if (from >= nodePositions.length || to >= nodePositions.length) continue;
      final start = nodePositions[from];
      final end = nodePositions[to];

      // Solo conectar verticalmente, con curva suave
      final midY = (start.dy + end.dy) / 2;
      final path = Path();
      path.moveTo(start.dx, start.dy + 72 * 0.5);
      path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy - 72 * 0.5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SymmetricConnectorPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.connectionPairs != connectionPairs ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
