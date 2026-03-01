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
    return SizedBox(
      height: levelGroup.height,
      child: Stack(
        children: [
          for (int i = 0; i < levelGroup.nodes.length; i++)
            Positioned(
              left:
                  levelGroup.nodePositions[i].dx -
                  (levelGroup.nodeTitleWidths[i]! / 2),
              top: 0,
              child: _buildNode(levelGroup.nodes[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildNode(PathNode node, int index) {
    final titleMaxWidth = levelGroup.nodeTitleWidths[index] ?? 110.0;
    final nodeWidgetWidth = titleMaxWidth < 136.0 ? 136.0 : titleMaxWidth;

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
