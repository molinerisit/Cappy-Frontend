import 'dart:ui';
import 'models/path_data.dart';

class LayoutResult {
  final List<Offset> positions;
  final List<List<int>> connections;
  LayoutResult({required this.positions, required this.connections});
}

class PathLayoutEngine {
  LayoutResult compute({required List<PathNode> nodes, required double width}) {
    final levels = <int, List<int>>{};
    for (int i = 0; i < nodes.length; i++) {
      levels.putIfAbsent(nodes[i].level, () => []).add(i);
    }
    final sortedLevels = levels.keys.toList()..sort();
    final positions = List<Offset>.filled(nodes.length, Offset.zero);
    final connections = <List<int>>[];
    final leftX = width * 0.22;
    final rightX = width * 0.78;
    final centerX = width / 2;
    const rowSpacing = 140.0; // Más aire premium
    var currentY = 100.0;
    for (final level in sortedLevels) {
      final indices = levels[level]!;
      if (indices.length == 1) {
        positions[indices[0]] = Offset(centerX, currentY);
      } else if (indices.length == 2) {
        positions[indices[0]] = Offset(leftX, currentY);
        positions[indices[1]] = Offset(rightX, currentY);
      } else {
        // Si hay más de 2, solo mostrar los 2 primeros (máximo 2 por fila)
        positions[indices[0]] = Offset(leftX, currentY);
        positions[indices[1]] = Offset(rightX, currentY);
        // Los demás se apilan fuera de pantalla (o se pueden mostrar en otra fila si se desea)
      }
      currentY += rowSpacing;
    }
    // Conexiones suaves entre niveles
    for (int i = 1; i < sortedLevels.length; i++) {
      final prev = levels[sortedLevels[i - 1]]!;
      final curr = levels[sortedLevels[i]]!;
      for (final from in prev.take(2)) {
        for (final to in curr.take(2)) {
          connections.add([from, to]);
        }
      }
    }
    return LayoutResult(positions: positions, connections: connections);
  }
}
