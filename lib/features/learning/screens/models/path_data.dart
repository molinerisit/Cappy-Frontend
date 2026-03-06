enum NodeStatus { locked, active, completed }

enum NodeType {
  recipe,
  explanation,
  tips,
  quiz,
  technique,
  cultural,
  challenge,
}

class PathGroup {
  final String id;
  final String title;
  final int order;
  PathGroup({required this.id, required this.title, required this.order});
  factory PathGroup.fromJson(Map<String, dynamic> json) => PathGroup(
    id: json['_id'] as String,
    title: json['title'] as String,
    order: json['order'] as int,
  );
}

class PathNode {
  final String id;
  final String title;
  final String groupId;
  final int level;
  final int positionIndex;
  final int xpReward;
  final NodeType type;
  final NodeStatus status;
  PathNode({
    required this.id,
    required this.title,
    required this.groupId,
    required this.level,
    required this.positionIndex,
    required this.xpReward,
    required this.type,
    required this.status,
  });
  factory PathNode.fromJson(Map<String, dynamic> json) => PathNode(
    id: json['_id'] as String,
    title: json['title'] as String,
    groupId: json['groupId'] as String,
    level: json['level'] as int,
    positionIndex: json['positionIndex'] as int,
    xpReward: json['xpReward'] as int,
    type: NodeType.values.firstWhere((e) => e.name == (json['type'] as String)),
    status: NodeStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String),
    ),
  );
}

class PathData {
  final List<PathGroup> groups;
  final List<PathNode> nodes;
  PathData({required this.groups, required this.nodes});
  factory PathData.fromJson(Map<String, dynamic> json) => PathData(
    groups: (json['groups'] as List).map((g) => PathGroup.fromJson(g)).toList(),
    nodes: (json['nodes'] as List).map((n) => PathNode.fromJson(n)).toList(),
  );
}
