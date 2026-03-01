import 'package:flutter/material.dart';
import '../domain/models/path_node.dart';

class LevelGroup {
  final int level;
  final List<PathNode> nodes;
  final double startY;
  final double endY;
  final List<Offset> nodePositions;
  final Map<int, double> nodeTitleWidths;

  const LevelGroup({
    required this.level,
    required this.nodes,
    required this.startY,
    required this.endY,
    required this.nodePositions,
    required this.nodeTitleWidths,
  });

  double get height => endY - startY;
}

class OptimizedLayoutResult {
  final List<LevelGroup> levelGroups;
  final List<ConnectionData> connections;
  final List<GroupHeaderData> groupHeaders;
  final double totalHeight;

  const OptimizedLayoutResult({
    required this.levelGroups,
    required this.connections,
    required this.groupHeaders,
    required this.totalHeight,
  });
}

class ConnectionData {
  final int fromLevelIndex;
  final int fromNodeIndex;
  final int toLevelIndex;
  final int toNodeIndex;
  final Offset startPoint;
  final Offset endPoint;

  const ConnectionData({
    required this.fromLevelIndex,
    required this.fromNodeIndex,
    required this.toLevelIndex,
    required this.toNodeIndex,
    required this.startPoint,
    required this.endPoint,
  });
}

class GroupHeaderData {
  final String title;
  final double y;

  const GroupHeaderData(this.title, this.y);
}

class OptimizedLayoutEngine {
  static const double rowSpacing = 280.0;
  static const double groupGap = 120.0;
  static const double nodeCircleDiameter = 76.0;
  static const double connectorStartYOffset = 178.0;
  static const double connectorEndYOffset = 10.0;
  static const double connectorHorizontalNudge = 14.0;

  static OptimizedLayoutResult calculateOptimizedLayout({
    required List<PathNode> nodes,
    required Map<String, String> groupTitles,
    required double canvasWidth,
  }) {
    if (nodes.isEmpty) {
      return const OptimizedLayoutResult(
        levelGroups: [],
        connections: [],
        groupHeaders: [],
        totalHeight: 100.0,
      );
    }

    final minX = canvasWidth * 0.14;
    final maxX = canvasWidth * 0.86;

    final nodesByLevel = <int, List<PathNode>>{};
    for (final node in nodes) {
      nodesByLevel.putIfAbsent(node.level, () => []).add(node);
    }

    final sortedLevels = nodesByLevel.keys.toList()..sort();
    final levelGroups = <LevelGroup>[];
    final connections = <ConnectionData>[];
    final groupHeaders = <GroupHeaderData>[];

    var currentY = 60.0;
    String? lastGroupId;

    for (int levelIndex = 0; levelIndex < sortedLevels.length; levelIndex++) {
      final level = sortedLevels[levelIndex];
      final levelNodes = nodesByLevel[level]!
        ..sort((a, b) {
          if (a.positionIndex != b.positionIndex) {
            return a.positionIndex.compareTo(b.positionIndex);
          }
          return a.order.compareTo(b.order);
        });

      final firstNodeGroupId = levelNodes.first.groupId;
      if (firstNodeGroupId != null &&
          firstNodeGroupId != lastGroupId &&
          groupTitles.containsKey(firstNodeGroupId)) {
        if (levelGroups.isNotEmpty) {
          currentY += groupGap;
        }
        groupHeaders.add(
          GroupHeaderData(groupTitles[firstNodeGroupId]!, currentY - 36),
        );
        lastGroupId = firstNodeGroupId;
      }

      final startY = currentY;
      final levelCount = levelNodes.length;
      final titleMaxWidth = levelCount <= 1
          ? 170.0
          : (((maxX - minX) / (levelCount - 1)) - 20).clamp(128.0, 170.0);

      final nodePositions = <Offset>[];
      final nodeTitleWidths = <int, double>{};

      for (int j = 0; j < levelCount; j++) {
        final x = levelCount == 1
            ? canvasWidth * 0.5
            : minX + ((maxX - minX) * (j / (levelCount - 1)));
        nodePositions.add(Offset(x, 0));
        nodeTitleWidths[j] = titleMaxWidth;
      }

      final endY = currentY + rowSpacing;

      levelGroups.add(
        LevelGroup(
          level: level,
          nodes: levelNodes,
          startY: startY,
          endY: endY,
          nodePositions: nodePositions,
          nodeTitleWidths: nodeTitleWidths,
        ),
      );

      currentY = endY;
    }

    for (int i = 0; i < levelGroups.length - 1; i++) {
      final currentGroup = levelGroups[i];
      final nextGroup = levelGroups[i + 1];

      final currentCount = currentGroup.nodes.length;
      final nextCount = nextGroup.nodes.length;

      if (currentCount == nextCount) {
        for (int j = 0; j < currentCount; j++) {
          connections.add(
            _createConnection(currentGroup, j, i, nextGroup, j, i + 1),
          );
        }
      } else if (currentCount > nextCount) {
        for (int j = 0; j < currentCount; j++) {
          final mappedIndex = nextCount == 1
              ? 0
              : ((j * (nextCount - 1)) / (currentCount - 1)).round();
          connections.add(
            _createConnection(
              currentGroup,
              j,
              i,
              nextGroup,
              mappedIndex,
              i + 1,
            ),
          );
        }
      } else {
        for (int j = 0; j < nextCount; j++) {
          final mappedIndex = currentCount == 1
              ? 0
              : ((j * (currentCount - 1)) / (nextCount - 1)).round();
          connections.add(
            _createConnection(
              currentGroup,
              mappedIndex,
              i,
              nextGroup,
              j,
              i + 1,
            ),
          );
        }
      }
    }

    return OptimizedLayoutResult(
      levelGroups: levelGroups,
      connections: connections,
      groupHeaders: groupHeaders,
      totalHeight: currentY + 100,
    );
  }

  static ConnectionData _createConnection(
    LevelGroup fromGroup,
    int fromNodeIndex,
    int fromLevelIndex,
    LevelGroup toGroup,
    int toNodeIndex,
    int toLevelIndex,
  ) {
    final startPos = fromGroup.nodePositions[fromNodeIndex];
    final endPos = toGroup.nodePositions[toNodeIndex];

    final startAbsolute = Offset(startPos.dx, fromGroup.startY);
    final endAbsolute = Offset(endPos.dx, toGroup.startY);

    final deltaX = endAbsolute.dx - startAbsolute.dx;
    final direction = deltaX > 0
        ? 1.0
        : deltaX < 0
        ? -1.0
        : 0.0;

    final startPoint = Offset(
      startAbsolute.dx + (direction * connectorHorizontalNudge),
      startAbsolute.dy + connectorStartYOffset,
    );

    final endPoint = Offset(
      endAbsolute.dx - (direction * connectorHorizontalNudge),
      endAbsolute.dy + connectorEndYOffset,
    );

    return ConnectionData(
      fromLevelIndex: fromLevelIndex,
      fromNodeIndex: fromNodeIndex,
      toLevelIndex: toLevelIndex,
      toNodeIndex: toNodeIndex,
      startPoint: startPoint,
      endPoint: endPoint,
    );
  }
}
