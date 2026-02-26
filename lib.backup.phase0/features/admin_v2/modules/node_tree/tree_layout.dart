class NodeLayoutRow<T> {
  final int level;
  final List<T> nodes;

  const NodeLayoutRow({required this.level, required this.nodes});
}

List<NodeLayoutRow<Map<String, dynamic>>> buildParallelLevelRows(
  List<Map<String, dynamic>> nodes,
) {
  final sorted = List<Map<String, dynamic>>.from(nodes)
    ..sort((a, b) {
      final levelA = (a['level'] ?? 1) as int;
      final levelB = (b['level'] ?? 1) as int;
      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }
      final posA = (a['positionIndex'] ?? 1) as int;
      final posB = (b['positionIndex'] ?? 1) as int;
      return posA.compareTo(posB);
    });

  final Map<int, List<Map<String, dynamic>>> grouped = {};
  for (final node in sorted) {
    final level = (node['level'] ?? 1) as int;
    grouped.putIfAbsent(level, () => []).add(node);
  }

  return grouped.entries
      .map((entry) => NodeLayoutRow(level: entry.key, nodes: entry.value))
      .toList();
}
