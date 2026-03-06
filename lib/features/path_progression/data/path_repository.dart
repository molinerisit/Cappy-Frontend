import '../../../core/api_service.dart';
import '../domain/models/path_model.dart';
import '../domain/models/path_node.dart';
import '../domain/models/path_group.dart';

class PathRepository {
  final String pathId;

  PathRepository(this.pathId);

  Future<PathModel> fetchPath({required int page, required int limit}) async {
    final data = await ApiService.getPath(pathId, page: page, limit: limit);

    final normalized = _normalizePathData(data);
    final nodesList = normalized['nodes'] as List<dynamic>? ?? [];
    final groupsList = normalized['groups'] as List<dynamic>? ?? [];

    final nodes = nodesList
        .whereType<Map<String, dynamic>>()
        .map((json) => PathNode.fromJson(json))
        .toList();

    final groups = groupsList
        .whereType<Map<String, dynamic>>()
        .map((json) => PathGroup.fromJson(json))
        .toList();

    final pagination = data['pagination'] as Map<String, dynamic>?;
    final hasMore = pagination?['hasMore'] == true;

    return PathModel(
      nodes: nodes,
      groups: groups,
      hasMore: hasMore,
      currentPage: page,
    );
  }

  Map<String, dynamic> _normalizePathData(dynamic data) {
    if (data is Map) {
      return {
        'nodes': data['nodes'] ?? <dynamic>[],
        'groups': data['groups'] ?? <dynamic>[],
      };
    }

    if (data is List) {
      final match = data.firstWhere((item) {
        if (item is! Map) return false;
        final id = item['_id'] ?? item['id'];
        return id?.toString() == pathId;
      }, orElse: () => null);

      if (match is Map) {
        return {
          'nodes': match['nodes'] ?? <dynamic>[],
          'groups': match['groups'] ?? <dynamic>[],
        };
      }
    }

    return {'nodes': <dynamic>[], 'groups': <dynamic>[]};
  }
}
