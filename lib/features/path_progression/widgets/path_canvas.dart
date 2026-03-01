import 'package:flutter/material.dart';
import '../domain/path_layout_engine.dart';
import '../domain/models/path_node.dart';
import '../../learning/widgets/skill_node.dart';
import '../../learning/widgets/path_connector_painter.dart';
import '../../../theme/colors.dart';
import 'path_group_header.dart';

class PathCanvas extends StatelessWidget {
  final PathLayoutResult layout;
  final List<PathNode> nodes;
  final void Function(PathNode node) onNodeTap;

  const PathCanvas({
    super.key,
    required this.layout,
    required this.nodes,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    const nodeCircleDiameter = 76.0;
    const connectorStartYOffset = 136.0;
    const connectorEndYOffset = 6.0;
    const connectorHorizontalNudge = 14.0;

    Offset connectorStartAnchor(Offset startRaw, Offset endRaw) {
      final deltaX = endRaw.dx - startRaw.dx;
      final direction = deltaX > 0
          ? 1.0
          : deltaX < 0
          ? -1.0
          : 0.0;
      return Offset(
        startRaw.dx + (direction * connectorHorizontalNudge),
        startRaw.dy + connectorStartYOffset,
      );
    }

    Offset connectorEndAnchor(Offset startRaw, Offset endRaw) {
      final deltaX = endRaw.dx - startRaw.dx;
      final direction = deltaX > 0
          ? 1.0
          : deltaX < 0
          ? -1.0
          : 0.0;
      return Offset(
        endRaw.dx - (direction * connectorHorizontalNudge),
        endRaw.dy + connectorEndYOffset,
      );
    }

    final connectionPairs = layout.connections
        .map((conn) => [conn.fromIndex, conn.toIndex])
        .toList();

    return SizedBox(
      width: double.infinity,
      height: layout.totalHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PathConnectorPainter(
                nodePositions: layout.nodePositions,
                lineColor: AppColors.border,
                strokeWidth: 3,
                breakIndices: const {},
                connectionPairs: connectionPairs,
                nodeCircleDiameter: nodeCircleDiameter,
                lineStartYOffset: connectorStartYOffset,
                lineEndYOffset: connectorEndYOffset,
                horizontalAnchorNudge: connectorHorizontalNudge,
                curveHorizontalFactor: 0.2,
              ),
            ),
          ),
          ...List.generate(layout.connections.length, (index) {
            final conn = layout.connections[index];
            if (conn.fromIndex >= layout.nodePositions.length ||
                conn.toIndex >= layout.nodePositions.length) {
              return const SizedBox.shrink();
            }

            final startRaw = layout.nodePositions[conn.fromIndex];
            final endRaw = layout.nodePositions[conn.toIndex];
            final start = connectorStartAnchor(startRaw, endRaw);
            final end = connectorEndAnchor(startRaw, endRaw);
            final midX = (start.dx + end.dx) / 2;
            final midY = (start.dy + end.dy) / 2;

            return Positioned(
              left: midX - 4,
              top: midY - 4,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 150)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.border,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          ...List.generate(layout.groupHeaders.length, (index) {
            final header = layout.groupHeaders[index];
            return Positioned(
              left: 0,
              top: header.y,
              right: 0,
              child: PathGroupHeader(title: header.title, index: index),
            );
          }),
          ...List.generate(nodes.length, (index) {
            if (index >= layout.nodePositions.length) {
              return const SizedBox.shrink();
            }

            final node = nodes[index];
            final position = layout.nodePositions[index];
            final titleMaxWidth = layout.nodeTitleWidths[index] ?? 110.0;
            final nodeWidgetWidth = titleMaxWidth < nodeCircleDiameter
                ? nodeCircleDiameter
                : titleMaxWidth;

            return Positioned(
              left: position.dx - (nodeWidgetWidth / 2),
              top: position.dy,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(node.id),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
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
          }),
        ],
      ),
    );
  }
}
