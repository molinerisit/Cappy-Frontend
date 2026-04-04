import '../../../learning/widgets/skill_node.dart' show NodeStatus;

class PathNode {
  final String id;
  final String title;
  final String? groupId;
  final String? groupTitle;
  final int level;
  final int positionIndex;
  final int order;
  final int xpReward;
  final String type;
  final NodeStatus status;

  const PathNode({
    required this.id,
    required this.title,
    this.groupId,
    this.groupTitle,
    required this.level,
    required this.positionIndex,
    required this.order,
    required this.xpReward,
    required this.type,
    required this.status,
  });

  factory PathNode.fromJson(Map<String, dynamic> json) {
    return PathNode(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      groupId: _extractId(json['groupId']),
      groupTitle: json['groupTitle']?.toString(),
      level: (json['order'] as int?) ?? (json['level'] as int?) ?? 1,
      positionIndex: json['positionIndex'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      type: json['type']?.toString() ?? 'recipe',
      status: _parseStatus(json['status']?.toString()),
    );
  }

  static String? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'] ?? raw['\$oid'];
      if (id == null) return null;
      return _extractId(id);
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static NodeStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return NodeStatus.completed;
      case 'available':
      case 'unlocked':
      case 'active':
        return NodeStatus.active;
      case 'locked':
      default:
        return NodeStatus.locked;
    }
  }
}
