import 'path_node.dart';
import 'path_group.dart';
import '../../../learning/widgets/skill_node.dart' show NodeStatus;

class PathModel {
  final List<PathNode> nodes;
  final List<PathGroup> groups;
  final bool hasMore;
  final int currentPage;

  const PathModel({
    required this.nodes,
    required this.groups,
    required this.hasMore,
    required this.currentPage,
  });

  PathModel copyWith({
    List<PathNode>? nodes,
    List<PathGroup>? groups,
    bool? hasMore,
    int? currentPage,
  }) {
    return PathModel(
      nodes: nodes ?? this.nodes,
      groups: groups ?? this.groups,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  int get completedCount =>
      nodes.where((n) => n.status == NodeStatus.completed).length;
  int get totalCount => nodes.length;
  int get currentLevel =>
      (completedCount + 1).clamp(1, totalCount > 0 ? totalCount : 1);
}
