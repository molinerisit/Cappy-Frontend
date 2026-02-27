import 'package:flutter/material.dart';

enum LevelStatus { locked, available, inProgress, completed }

class LevelNodeModel {
  final String id;
  final String title;
  final String type;
  final LevelStatus status;

  const LevelNodeModel({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
  });
}

class LevelModel {
  final int level;
  final String groupId;
  final String? groupTitle;
  final List<LevelNodeModel> nodes;

  const LevelModel({
    required this.level,
    required this.groupId,
    required this.nodes,
    this.groupTitle,
  });

  bool get isCluster => nodes.length > 1;
}

class RoadmapMetrics {
  final int completedCount;
  final int totalCount;
  final int currentLevel;

  const RoadmapMetrics({
    required this.completedCount,
    required this.totalCount,
    required this.currentLevel,
  });
}

Color statusColor(LevelStatus status) {
  switch (status) {
    case LevelStatus.completed:
      return const Color(0xFF22C55E);
    case LevelStatus.inProgress:
      return const Color(0xFFF59E0B);
    case LevelStatus.available:
      return const Color(0xFF14B8A6);
    case LevelStatus.locked:
      return const Color(0xFF9CA3AF);
  }
}
