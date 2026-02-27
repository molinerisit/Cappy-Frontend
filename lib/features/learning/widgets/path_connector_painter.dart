import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PathConnectorPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Color lineColor;
  final double strokeWidth;
  final List<List<int>> connectionPairs;
  final double nodeCircleDiameter;
  final double lineStartYOffset;
  final double lineEndYOffset;
  final double horizontalAnchorNudge;
  final double curveHorizontalFactor;
  final Set<int>
  breakIndices; // Índices donde NO dibujar línea (inicio de grupos)

  PathConnectorPainter({
    required this.nodePositions,
    this.lineColor = AppColors.border,
    this.strokeWidth = 2.0,
    this.connectionPairs = const [],
    this.nodeCircleDiameter = 76.0,
    this.lineStartYOffset = 116.0,
    this.lineEndYOffset = 4.0,
    this.horizontalAnchorNudge = 10.0,
    this.curveHorizontalFactor = 0.18,
    this.breakIndices = const {},
  });

  Offset _startAnchor(Offset startRaw, Offset endRaw) {
    final isDescending = endRaw.dy >= startRaw.dy;
    final deltaX = endRaw.dx - startRaw.dx;
    final direction = deltaX > 0
        ? 1.0
        : deltaX < 0
        ? -1.0
        : 0.0;

    if (isDescending) {
      return Offset(
        startRaw.dx + (direction * horizontalAnchorNudge),
        startRaw.dy + lineStartYOffset,
      );
    }

    return Offset(startRaw.dx, startRaw.dy + lineEndYOffset);
  }

  Offset _endAnchor(Offset startRaw, Offset endRaw) {
    final isDescending = endRaw.dy >= startRaw.dy;
    final deltaX = endRaw.dx - startRaw.dx;
    final direction = deltaX > 0
        ? 1.0
        : deltaX < 0
        ? -1.0
        : 0.0;

    if (isDescending) {
      return Offset(
        endRaw.dx - (direction * horizontalAnchorNudge),
        endRaw.dy + lineEndYOffset,
      );
    }

    return Offset(endRaw.dx, endRaw.dy + lineStartYOffset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (connectionPairs.isNotEmpty) {
      for (final pair in connectionPairs) {
        if (pair.length < 2) continue;
        final from = pair[0];
        final to = pair[1];
        if (from < 0 || to < 0) continue;
        if (from >= nodePositions.length || to >= nodePositions.length) {
          continue;
        }

        final startRaw = nodePositions[from];
        final endRaw = nodePositions[to];
        final start = _startAnchor(startRaw, endRaw);
        final end = _endAnchor(startRaw, endRaw);

        final path = Path();
        path.moveTo(start.dx, start.dy);

        final deltaX = end.dx - start.dx;

        final controlPoint1 = Offset(
          start.dx + (deltaX * curveHorizontalFactor),
          start.dy + (end.dy - start.dy) * 0.4,
        );
        final controlPoint2 = Offset(
          end.dx - (deltaX * curveHorizontalFactor),
          start.dy + (end.dy - start.dy) * 0.6,
        );

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
      return;
    }

    // Dibujar líneas curvas entre cada par de nodos (modo secuencial legacy)
    for (int i = 0; i < nodePositions.length - 1; i++) {
      if (breakIndices.contains(i + 1)) continue;

      final startRaw = nodePositions[i];
      final endRaw = nodePositions[i + 1];
      final start = _startAnchor(startRaw, endRaw);
      final end = _endAnchor(startRaw, endRaw);

      // Crear path con curva suave
      final path = Path();
      path.moveTo(start.dx, start.dy);

      final deltaX = end.dx - start.dx;

      // Calcular puntos de control para curva Bezier
      final controlPoint1 = Offset(
        start.dx + (deltaX * curveHorizontalFactor),
        start.dy + (end.dy - start.dy) * 0.4,
      );

      final controlPoint2 = Offset(
        end.dx - (deltaX * curveHorizontalFactor),
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
        oldDelegate.connectionPairs != connectionPairs ||
        oldDelegate.nodeCircleDiameter != nodeCircleDiameter ||
        oldDelegate.lineStartYOffset != lineStartYOffset ||
        oldDelegate.lineEndYOffset != lineEndYOffset ||
        oldDelegate.horizontalAnchorNudge != horizontalAnchorNudge ||
        oldDelegate.curveHorizontalFactor != curveHorizontalFactor ||
        oldDelegate.breakIndices != breakIndices;
  }
}
