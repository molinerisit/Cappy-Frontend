import 'package:flutter/material.dart';
import 'models/path_data.dart';
import 'lesson_node_widget.dart';

class LevelRowWidget extends StatelessWidget {
  final List<PathNode> nodes;
  final List<Offset> positions;
  final double height;
  final void Function(PathNode)? onTap;
  const LevelRowWidget({
    required this.nodes,
    required this.positions,
    required this.height,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          for (int i = 0; i < nodes.length; i++)
            Positioned(
              left: positions[i].dx - 36,
              top:
                  (height / 2) - 36, // Centrar verticalmente el nodo en la fila
              child: LessonNodeWidget(node: nodes[i], onTap: onTap),
            ),
        ],
      ),
    );
  }
}
