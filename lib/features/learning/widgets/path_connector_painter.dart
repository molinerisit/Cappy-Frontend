import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PathConnectorPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Color lineColor;
  final double strokeWidth;
  final Set<int>
  breakIndices; // Índices donde NO dibujar línea (inicio de grupos)

  PathConnectorPainter({
    required this.nodePositions,
    this.lineColor = AppColors.border,
    this.strokeWidth = 2.0,
    this.breakIndices = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dibujar líneas curvas entre cada par de nodos
    for (int i = 0; i < nodePositions.length - 1; i++) {
      // Saltar si el siguiente índice es un inicio de grupo (breakIndex)
      if (breakIndices.contains(i + 1)) {
        continue;
      }

      final start = nodePositions[i];
      final end = nodePositions[i + 1];

      // Crear path con curva suave
      final path = Path();
      path.moveTo(start.dx, start.dy);

      // Calcular puntos de control para curva Bezier
      final controlPoint1 = Offset(
        start.dx,
        start.dy + (end.dy - start.dy) * 0.4,
      );

      final controlPoint2 = Offset(
        end.dx,
        start.dy + (end.dy - start.dy) * 0.6,
      );

      // Dibujar curva cúbica de Bezier
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PathConnectorPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.breakIndices != breakIndices;
  }
}
