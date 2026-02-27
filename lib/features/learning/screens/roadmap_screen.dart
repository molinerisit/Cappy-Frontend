import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../widgets/progress_card.dart';
import '../models/level_model.dart';
import '../widgets/level_row.dart';

class RoadmapController extends ChangeNotifier {
  List<LevelModel> _levels = const [];
  RoadmapMetrics _metrics = const RoadmapMetrics(
    completedCount: 0,
    totalCount: 0,
    currentLevel: 1,
  );

  List<LevelModel> get levels => _levels;
  RoadmapMetrics get metrics => _metrics;

  void setData({
    required List<LevelModel> levels,
    required RoadmapMetrics metrics,
  }) {
    _levels = levels;
    _metrics = metrics;
    notifyListeners();
  }
}

class RoadmapScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;
  final List<dynamic> rawNodes;
  final List<dynamic> rawGroups;
  final ScrollController scrollController;
  final Future<void> Function(String nodeId, String title, String nodeType)
  onStartLesson;

  const RoadmapScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
    required this.rawNodes,
    required this.rawGroups,
    required this.scrollController,
    required this.onStartLesson,
  });

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  late final RoadmapController _controller;
  bool _didAutoScroll = false;

  bool get _isCookingVisualPreviewPath =>
      widget.pathTitle.toLowerCase().contains('aprender a cocinar');

  @override
  void initState() {
    super.initState();
    _controller = RoadmapController();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant RoadmapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathId != widget.pathId ||
        oldWidget.rawNodes.length != widget.rawNodes.length) {
      _didAutoScroll = false;
      _hydrate();
    }
  }

  String? _extractEntityId(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'] ?? raw[r'$oid'];
      return _extractEntityId(id);
    }
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? _extractGroupTitle(dynamic raw) {
    bool isLikelyObjectId(String value) =>
        RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);

    String? sanitize(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty || isLikelyObjectId(trimmed)) return null;
      return trimmed;
    }

    if (raw is String) return sanitize(raw);
    if (raw is! Map) return null;
    return sanitize(raw['title']?.toString() ?? raw['name']?.toString());
  }

  LevelStatus _mapStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'completed':
        return LevelStatus.completed;
      case 'available':
      case 'active':
      case 'unlocked':
        return LevelStatus.available;
      case 'inprogress':
      case 'in_progress':
      case 'current':
        return LevelStatus.inProgress;
      case 'locked':
      default:
        return LevelStatus.locked;
    }
  }

  void _injectVisualPreviewNodes(
    Map<String, Map<int, List<LevelNodeModel>>> grouped,
    List<String> orderedGroupIds,
  ) {
    final firstContentGroupId = orderedGroupIds.firstWhere(
      (groupId) => groupId != '__ungrouped__',
      orElse: () => '',
    );

    for (final groupId in orderedGroupIds) {
      if (groupId == '__ungrouped__') continue;
      final perLevel = grouped[groupId];
      if (perLevel == null || perLevel.isEmpty) continue;

      final maxLevel = perLevel.keys.fold<int>(
        0,
        (max, value) => value > max ? value : max,
      );

      final levelA = maxLevel + 1;
      final levelB = maxLevel + 2;
      final isFirstGroup = groupId == firstContentGroupId;

      if (isFirstGroup) {
        final levelC = maxLevel + 3;
        final levelD = maxLevel + 4;

        perLevel[levelA] = [
          LevelNodeModel(
            id: '${groupId}_preview_${levelA}_1',
            title: 'Práctica base',
            type: 'recipe',
            status: LevelStatus.locked,
          ),
        ];

        perLevel[levelB] = [
          LevelNodeModel(
            id: '${groupId}_preview_${levelB}_1',
            title: 'Técnica puntual',
            type: 'technique',
            status: LevelStatus.locked,
          ),
        ];

        perLevel[levelC] = [
          LevelNodeModel(
            id: '${groupId}_preview_${levelC}_1',
            title: 'Quiz rápido',
            type: 'quiz',
            status: LevelStatus.locked,
          ),
        ];

        perLevel[levelD] = [
          LevelNodeModel(
            id: '${groupId}_preview_${levelD}_1',
            title: 'Desafío corto',
            type: 'challenge',
            status: LevelStatus.locked,
          ),
          LevelNodeModel(
            id: '${groupId}_preview_${levelD}_2',
            title: 'Práctica extra',
            type: 'recipe',
            status: LevelStatus.locked,
          ),
        ];
        continue;
      }

      perLevel[levelA] = [
        LevelNodeModel(
          id: '${groupId}_preview_${levelA}_1',
          title: 'Práctica guiada',
          type: 'recipe',
          status: LevelStatus.locked,
        ),
        LevelNodeModel(
          id: '${groupId}_preview_${levelA}_2',
          title: 'Reto rápido',
          type: 'challenge',
          status: LevelStatus.locked,
        ),
      ];

      perLevel[levelB] = [
        LevelNodeModel(
          id: '${groupId}_preview_${levelB}_1',
          title: 'Técnica fina',
          type: 'technique',
          status: LevelStatus.locked,
        ),
        LevelNodeModel(
          id: '${groupId}_preview_${levelB}_2',
          title: 'Quiz express',
          type: 'quiz',
          status: LevelStatus.locked,
        ),
        LevelNodeModel(
          id: '${groupId}_preview_${levelB}_3',
          title: 'Desafío final',
          type: 'challenge',
          status: LevelStatus.locked,
        ),
      ];
    }
  }

  void _hydrate() {
    final nodeList = widget.rawNodes.whereType<Map<String, dynamic>>().toList();
    final groups = widget.rawGroups.whereType<Map<String, dynamic>>().toList();

    final groupOrder = <String, int>{};
    final groupTitleById = <String, String>{};

    for (final group in groups) {
      final id = _extractEntityId(group);
      if (id == null) continue;
      groupOrder[id] = (group['order'] as num?)?.toInt() ?? 0;
      final title = _extractGroupTitle(group);
      if (title != null) {
        groupTitleById[id] = title;
      }
    }

    final rows = <_RawRow>[];
    for (final node in nodeList) {
      final level = (node['level'] as num?)?.toInt() ?? 1;
      final positionIndex = (node['positionIndex'] as num?)?.toInt() ?? 0;
      final order = (node['order'] as num?)?.toInt() ?? 0;
      final groupId = _extractEntityId(node['groupId']) ?? '__ungrouped__';
      final groupTitle =
          _extractGroupTitle(node['groupTitle']) ?? groupTitleById[groupId];
      if (groupTitle != null && groupId != '__ungrouped__') {
        groupTitleById.putIfAbsent(groupId, () => groupTitle);
      }

      final nodeId = _extractEntityId(node['_id'] ?? node['id']) ?? '';
      if (nodeId.isEmpty) continue;

      rows.add(
        _RawRow(
          groupId: groupId,
          groupOrder: groupOrder[groupId] ?? 999,
          level: level,
          positionIndex: positionIndex,
          order: order,
          node: LevelNodeModel(
            id: nodeId,
            title: (node['title']?.toString().trim().isNotEmpty ?? false)
                ? node['title'].toString().trim()
                : 'Nodo',
            type: (node['type'] ?? 'recipe').toString(),
            status: _mapStatus(node['status']?.toString()),
          ),
        ),
      );
    }

    rows.sort((a, b) {
      if (a.groupOrder != b.groupOrder)
        return a.groupOrder.compareTo(b.groupOrder);
      final groupCmp = a.groupId.compareTo(b.groupId);
      if (groupCmp != 0 && a.groupOrder == b.groupOrder) {
        // preserve deterministic grouping when order equal
        return groupCmp;
      }
      if (a.level != b.level) return a.level.compareTo(b.level);
      if (a.positionIndex != b.positionIndex)
        return a.positionIndex.compareTo(b.positionIndex);
      return a.order.compareTo(b.order);
    });

    final grouped = <String, Map<int, List<LevelNodeModel>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.groupId, () => <int, List<LevelNodeModel>>{});
      grouped[row.groupId]!.putIfAbsent(row.level, () => <LevelNodeModel>[]);
      grouped[row.groupId]![row.level]!.add(row.node);
    }

    final orderedGroupIds = grouped.keys.toList()
      ..sort((a, b) {
        final oa = groupOrder[a] ?? 999;
        final ob = groupOrder[b] ?? 999;
        if (oa != ob) return oa.compareTo(ob);
        return a.compareTo(b);
      });

    if (_isCookingVisualPreviewPath) {
      _injectVisualPreviewNodes(grouped, orderedGroupIds);
    }

    final levels = <LevelModel>[];
    for (final groupId in orderedGroupIds) {
      final perLevel = grouped[groupId]!;
      final levelKeys = perLevel.keys.toList()..sort();
      for (final levelKey in levelKeys) {
        final nodes = perLevel[levelKey]!.take(3).toList();
        levels.add(
          LevelModel(
            level: levelKey,
            groupId: groupId,
            groupTitle: groupId == '__ungrouped__'
                ? null
                : groupTitleById[groupId],
            nodes: nodes,
          ),
        );
      }
    }

    final totalCount = levels.fold<int>(
      0,
      (acc, item) => acc + item.nodes.length,
    );
    final completedCount = levels
        .expand((level) => level.nodes)
        .where((node) => node.status == LevelStatus.completed)
        .length;

    int currentLevel = 1;
    final firstInProgress = levels.indexWhere(
      (level) =>
          level.nodes.any((node) => node.status == LevelStatus.inProgress),
    );
    final firstAvailable = levels.indexWhere(
      (level) =>
          level.nodes.any((node) => node.status == LevelStatus.available),
    );

    if (firstInProgress >= 0) {
      currentLevel = firstInProgress + 1;
    } else if (firstAvailable >= 0) {
      currentLevel = firstAvailable + 1;
    } else if (levels.isNotEmpty) {
      currentLevel = (completedCount + 1).clamp(1, levels.length);
    }

    _controller.setData(
      levels: levels,
      metrics: RoadmapMetrics(
        completedCount: completedCount,
        totalCount: totalCount,
        currentLevel: currentLevel,
      ),
    );

    if (!_didAutoScroll && levels.isNotEmpty) {
      _didAutoScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.scrollController.hasClients) return;
        final rowExtent = 122.0;
        final targetOffset = ((currentLevel - 1) * rowExtent)
            .clamp(0.0, widget.scrollController.position.maxScrollExtent)
            .toDouble();
        widget.scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final levels = _controller.levels;
        final metrics = _controller.metrics;

        if (levels.isEmpty) {
          return const Center(child: Text('No hay niveles disponibles'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: ProgressCard(
                levelText: 'Nivel ${metrics.currentLevel}',
                progress: metrics.totalCount > 0
                    ? metrics.completedCount / metrics.totalCount
                    : 0,
                subtitle:
                    '${metrics.completedCount} de ${metrics.totalCount} lecciones completadas',
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: levels.length,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final previousGroupId = index > 0
                      ? levels[index - 1].groupId
                      : null;
                  final showHeader =
                      level.groupTitle != null &&
                      level.groupId != previousGroupId;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  level.groupTitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      LevelRow(
                        level: level,
                        index: index,
                        showTopConnector: index > 0,
                        showBottomConnector: index < levels.length - 1,
                        onNodeTap: (node) {
                          widget.onStartLesson(node.id, node.title, node.type);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RawRow {
  final String groupId;
  final int groupOrder;
  final int level;
  final int positionIndex;
  final int order;
  final LevelNodeModel node;

  const _RawRow({
    required this.groupId,
    required this.groupOrder,
    required this.level,
    required this.positionIndex,
    required this.order,
    required this.node,
  });
}
