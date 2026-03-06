import 'package:flutter/material.dart';
import '../domain/optimized_layout_engine.dart';
import '../domain/models/path_node.dart';
import '../../learning/widgets/skill_node.dart';

class LevelSection extends StatelessWidget {
  final LevelGroup levelGroup;
  final void Function(PathNode node) onNodeTap;

  const LevelSection({
    super.key,
    required this.levelGroup,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay múltiples nodos en el mismo nivel, mostrar horizontalmente
    // Si hay 1 nodo, centrado
    final nodeCount = levelGroup.nodes.length;

    if (nodeCount == 1) {
      // Un solo nodo: centrado verticalmente
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: _buildNode(levelGroup.nodes[0], 0),
        ),
      );
    } else {
      // Múltiples nodos: distribuir horizontalmente (lado a lado)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0, // Espacio horizontal entre nodos
          runSpacing: 20.0, // Espacio vertical entre filas
          children: [
            for (int i = 0; i < levelGroup.nodes.length; i++)
              _buildNode(levelGroup.nodes[i], i),
          ],
        ),
      );
    }
  }

  Widget _buildNode(PathNode node, int index) {
    // Ancho fijo para que quepan 2 nodos lado a lado en pantalla móvil
    // En pantallas de ~360px, con spacing de 16px: (360 - 32 padding - 16 spacing) / 2 = 156px por nodo
    final nodeWidgetWidth = 140.0; // Ancho fijo más compacto
    final titleMaxWidth = 120.0; // Título más compacto

    return RepaintBoundary(
      child: SizedBox(
        width: nodeWidgetWidth,
        child: LessonNode(
          nodeId: node.id,
          title: node.title,
          xpReward: node.xpReward,
          status: node.status,
          nodeType: node.type,
          index: index,
          titleMaxWidth: titleMaxWidth,
          nodeWidth: nodeWidgetWidth,
          onTap: node.status != NodeStatus.locked
              ? () => onNodeTap(node)
              : null,
        ),
      ),
    );
  }
}
