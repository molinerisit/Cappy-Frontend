import 'package:flutter/material.dart';
import '../models/level_model.dart';
import 'level_node.dart';

class LevelRow extends StatelessWidget {
  final LevelModel level;
  final int index;
  final bool showTopConnector;
  final bool showBottomConnector;
  final void Function(LevelNodeModel node)? onNodeTap;

  const LevelRow({
    super.key,
    required this.level,
    required this.index,
    this.showTopConnector = true,
    this.showBottomConnector = true,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final singleNode = level.nodes.length == 1;
    final isLeft = index.isEven;
    final rowHeight = singleNode ? 102.0 : 130.0;

    Widget nodesWidget;
    if (singleNode) {
      nodesWidget = Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(
            left: isLeft ? 20 : 0,
            right: isLeft ? 0 : 20,
          ),
          child: LevelNode(
            node: level.nodes.first,
            onTap: onNodeTap == null
                ? null
                : () => onNodeTap!(level.nodes.first),
          ),
        ),
      );
    } else {
      final limited = level.nodes.take(3).toList();
      nodesWidget = LayoutBuilder(
        builder: (context, constraints) {
          final count = limited.length;
          if (count == 2) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LevelNode(
                    node: limited[0],
                    onTap: onNodeTap == null
                        ? null
                        : () => onNodeTap!(limited[0]),
                  ),
                  const SizedBox(width: 32),
                  LevelNode(
                    node: limited[1],
                    onTap: onNodeTap == null
                        ? null
                        : () => onNodeTap!(limited[1]),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            width: constraints.maxWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: limited
                  .map(
                    (node) => LevelNode(
                      node: node,
                      onTap: onNodeTap == null ? null : () => onNodeTap!(node),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      );
    }

    return RepaintBoundary(
      child: SizedBox(height: rowHeight, child: nodesWidget),
    );
  }
}
