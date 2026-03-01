import 'package:flutter/material.dart';
import 'models/path_node.dart';
import 'models/path_group.dart';

class PathLayoutResult {
  final List<Offset> nodePositions;
  final List<LayoutConnection> connections;
  final List<GroupHeader> groupHeaders;
  final Map<int, double> nodeTitleWidths;
  final double totalHeight;

  const PathLayoutResult({
    required this.nodePositions,
    required this.connections,
    required this.groupHeaders,
    required this.nodeTitleWidths,
    required this.totalHeight,
  });
}

class LayoutConnection {
  final int fromIndex;
  final int toIndex;

  const LayoutConnection(this.fromIndex, this.toIndex);
}

class GroupHeader {
  final String title;
  final double y;

  const GroupHeader(this.title, this.y);
}

class PathLayoutEngine {
  static const double rowSpacing = 240.0;
  static const double groupGap = 120.0;
  static const double nodeCircleDiameter = 76.0;

  static PathLayoutResult calculateLayout({
    required List<PathNode> nodes,
    required List<PathGroup> groups,
    required double canvasWidth,
  }) {
    if (nodes.isEmpty) {
      return const PathLayoutResult(
        nodePositions: [],
        connections: [],
        groupHeaders: [],
        nodeTitleWidths: {},
        totalHeight: 100.0,
      );
    }

    final minX = canvasWidth * 0.2;
    final maxX = canvasWidth * 0.8;

    final groupTitleById = <String, String>{};
    for (final group in groups) {
      if (group.title.isNotEmpty) {
        groupTitleById[group.id] = group.title;
      }
    }

    const ungroupedKey = '__ungrouped__';
    final groupedNodes = <String, List<int>>{};
    final groupedNodeObjects = <String, List<PathNode>>{};

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final groupId = node.groupId?.isNotEmpty == true
          ? node.groupId!
          : ungroupedKey;

      if (node.groupTitle != null && node.groupTitle!.isNotEmpty) {
        groupTitleById.putIfAbsent(groupId, () => node.groupTitle!);
      }

      groupedNodes.putIfAbsent(groupId, () => []).add(i);
      groupedNodeObjects.putIfAbsent(groupId, () => []).add(node);
    }

    final sortedGroups = [...groups]
      ..sort((a, b) => a.order.compareTo(b.order));
    final orderedGroupIds = sortedGroups.map((g) => g.id).toList();

    final orderedGroupSet = orderedGroupIds.toSet();
    for (final groupId in groupedNodes.keys) {
      if (groupId == ungroupedKey) continue;
      if (!orderedGroupSet.contains(groupId)) {
        orderedGroupIds.add(groupId);
      }
    }
    if (groupedNodes.containsKey(ungroupedKey)) {
      orderedGroupIds.add(ungroupedKey);
    }

    final nodePositions = List<Offset>.filled(nodes.length, Offset.zero);
    final nodeTitleWidths = <int, double>{};
    final connections = <LayoutConnection>[];
    final connectionKeys = <String>{};
    final groupHeaders = <GroupHeader>[];
    final groupStartIndex = <String, int>{};

    void addConnection(int from, int to) {
      final key = '$from->$to';
      if (connectionKeys.add(key)) {
        connections.add(LayoutConnection(from, to));
      }
    }

    var currentY = 60.0;

    for (final groupId in orderedGroupIds) {
      final groupNodeIndices = groupedNodes[groupId];
      if (groupNodeIndices == null || groupNodeIndices.isEmpty) continue;

      if (groupId != ungroupedKey && groupNodeIndices.isNotEmpty) {
        groupStartIndex[groupId] = groupNodeIndices.first;
      }

      final groupNodes = groupNodeIndices.map((i) => nodes[i]).toList()
        ..sort((a, b) {
          if (a.level != b.level) return a.level.compareTo(b.level);
          if (a.positionIndex != b.positionIndex) {
            return a.positionIndex.compareTo(b.positionIndex);
          }
          return a.order.compareTo(b.order);
        });

      final sortedIndices = groupNodes
          .map((node) => nodes.indexOf(node))
          .toList();

      final levelBuckets = <int, List<int>>{};
      final orderedLevels = <int>[];

      for (final nodeIndex in sortedIndices) {
        final node = nodes[nodeIndex];
        if (!levelBuckets.containsKey(node.level)) {
          levelBuckets[node.level] = [];
          orderedLevels.add(node.level);
        }
        levelBuckets[node.level]!.add(nodeIndex);
      }

      orderedLevels.sort();
      List<int>? previousLevelIndices;

      for (final level in orderedLevels) {
        final levelNodeIndices = levelBuckets[level]!
          ..sort((a, b) {
            final nodeA = nodes[a];
            final nodeB = nodes[b];
            if (nodeA.positionIndex != nodeB.positionIndex) {
              return nodeA.positionIndex.compareTo(nodeB.positionIndex);
            }
            return nodeA.order.compareTo(nodeB.order);
          });

        final levelCount = levelNodeIndices.length;
        final titleMaxWidth = levelCount <= 1
            ? 124.0
            : (((maxX - minX) / (levelCount - 1)) - 18).clamp(74.0, 124.0);

        for (int j = 0; j < levelCount; j++) {
          final x = levelCount == 1
              ? canvasWidth * 0.5
              : minX + ((maxX - minX) * (j / (levelCount - 1)));
          nodePositions[levelNodeIndices[j]] = Offset(x, currentY);
          nodeTitleWidths[levelNodeIndices[j]] = titleMaxWidth;
        }

        if (previousLevelIndices != null && previousLevelIndices.isNotEmpty) {
          final prevCount = previousLevelIndices.length;
          final currentCount = levelNodeIndices.length;

          if (prevCount == currentCount) {
            for (int j = 0; j < currentCount; j++) {
              addConnection(previousLevelIndices[j], levelNodeIndices[j]);
            }
          } else if (prevCount > currentCount) {
            for (int j = 0; j < prevCount; j++) {
              final mappedIndex = currentCount == 1
                  ? 0
                  : ((j * (currentCount - 1)) / (prevCount - 1)).round();
              addConnection(
                previousLevelIndices[j],
                levelNodeIndices[mappedIndex],
              );
            }
          } else {
            for (int j = 0; j < currentCount; j++) {
              final mappedIndex = prevCount == 1
                  ? 0
                  : ((j * (prevCount - 1)) / (currentCount - 1)).round();
              addConnection(
                previousLevelIndices[mappedIndex],
                levelNodeIndices[j],
              );
            }
          }
        }

        previousLevelIndices = levelNodeIndices;
        currentY += rowSpacing;
      }

      currentY += groupGap;
    }

    for (final groupId in orderedGroupIds) {
      if (groupId == ungroupedKey) continue;
      final startIndex = groupStartIndex[groupId];
      final title = groupTitleById[groupId] ?? '';
      final nodeCount = groupedNodes[groupId]?.length ?? 0;

      if (startIndex == null || title.isEmpty || nodeCount < 1) continue;

      final nodeY = nodePositions[startIndex].dy;
      final y = (nodeY - 96).clamp(0.0, double.infinity);
      groupHeaders.add(GroupHeader(title, y));
    }

    final maxY = nodePositions.fold<double>(
      0,
      (max, offset) => offset.dy > max ? offset.dy : max,
    );
    final totalHeight = maxY + 200;

    return PathLayoutResult(
      nodePositions: nodePositions,
      connections: connections,
      groupHeaders: groupHeaders,
      nodeTitleWidths: nodeTitleWidths,
      totalHeight: totalHeight,
    );
  }
}
