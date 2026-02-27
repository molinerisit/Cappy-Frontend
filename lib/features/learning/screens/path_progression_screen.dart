import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_service.dart';
import '../../../core/lives_service.dart';
import '../../../core/models/learning_node.dart';
import 'lesson_game_screen.dart';
import '../widgets/skill_node.dart';
import '../widgets/path_connector_painter.dart';
import '../../../widgets/progress_card.dart';
import '../../../widgets/user_xp_badge.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_scaffold.dart';

class PathProgressionScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;
  final bool showAppBar;
  final VoidCallback? onLessonExit;

  const PathProgressionScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
    this.showAppBar = true,
    this.onLessonExit,
  });

  @override
  State<PathProgressionScreen> createState() => _PathProgressionScreenState();
}

class _PathProgressionScreenState extends State<PathProgressionScreen>
    with TickerProviderStateMixin {
  final List<Offset> nodePositions = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final int _pageSize = 40;
  bool _isLoading = true;
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier(false);
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;
  DateTime? _lastLoadMoreAt;
  static const Duration _loadMoreCooldown = Duration(milliseconds: 450);
  double? _pendingRestoreOffset;
  Map<String, dynamic> _pathData = const {
    'nodes': <dynamic>[],
    'groups': <dynamic>[],
  };

  void _restoreScrollPositionIfNeeded() {
    final targetOffset = _pendingRestoreOffset;
    if (targetOffset == null) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPositionIfNeeded();
      });
      return;
    }

    final max = _scrollController.position.maxScrollExtent;
    final clamped = targetOffset.clamp(0.0, max);
    _scrollController.jumpTo(clamped);
    _pendingRestoreOffset = null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPathData();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void didUpdateWidget(covariant PathProgressionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathId != widget.pathId) {
      _pendingRestoreOffset = 0.0;
      _pathData = const {'nodes': <dynamic>[], 'groups': <dynamic>[]};
      _fadeController.reset();
      _fadeController.forward();
      _loadInitialPathData();
    }
  }

  Future<void> _loadInitialPathData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    await _fetchPathPage(page: 1, append: false);
  }

  Future<void> _loadMorePathData() async {
    if (_isLoadingMoreNotifier.value || !_hasMore) return;
    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < _loadMoreCooldown) {
      return;
    }
    _lastLoadMoreAt = now;

    _isLoadingMoreNotifier.value = true;
    await _fetchPathPage(page: _currentPage + 1, append: true);
    _isLoadingMoreNotifier.value = false;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore) return;
    if (_isLoading || _isLoadingMoreNotifier.value) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final triggerOffset = position.maxScrollExtent * 0.8;
    if (position.pixels >= triggerOffset) {
      _loadMorePathData();
    }
  }

  List<dynamic> _dedupeByEntityId(List<dynamic> source) {
    final unique = <dynamic>[];
    final seen = <String>{};

    for (final item in source) {
      final id = _extractEntityId(item);
      final key = id ?? '__fallback_${item.hashCode}_${unique.length}';
      if (seen.add(key)) {
        unique.add(item);
      }
    }

    return unique;
  }

  Future<void> _fetchPathPage({required int page, required bool append}) async {
    final stopwatch = Stopwatch()..start();
    int fetchedCount = 0;
    bool hasMore = false;
    String status = 'ok';

    try {
      final data = await ApiService.getPath(
        widget.pathId,
        page: page,
        limit: _pageSize,
      );

      final normalized = _normalizePathData(data);
      final nextNodes = List<dynamic>.from(normalized['nodes'] ?? <dynamic>[]);
      final nextGroups = List<dynamic>.from(
        normalized['groups'] ?? <dynamic>[],
      );
      fetchedCount = nextNodes.length;

      final pagination = data['pagination'] as Map<String, dynamic>?;
      hasMore = pagination?['hasMore'] == true;

      setState(() {
        _currentPage = page;
        _hasMore = hasMore;
        final previousNodes =
            _pathData['nodes'] as List<dynamic>? ?? <dynamic>[];
        final mergedNodes = append
            ? <dynamic>[...previousNodes, ...nextNodes]
            : <dynamic>[...nextNodes];

        _pathData = {
          'groups':
              append &&
                  _pathData['groups'] is List &&
                  (_pathData['groups'] as List).isNotEmpty
              ? _pathData['groups']
              : nextGroups,
          'nodes': _dedupeByEntityId(mergedNodes),
        };
      });
    } catch (e) {
      status = 'error';
      if (!append) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[Pagination][Path] pathId=${widget.pathId} page=$page append=$append fetched=$fetchedCount hasMore=$hasMore status=$status ms=${stopwatch.elapsedMilliseconds}',
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _isLoadingMoreNotifier.dispose();
    super.dispose();
  }

  Future<void> _startLesson(
    String nodeId,
    String title,
    String nodeType,
  ) async {
    final token = ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final livesService = LivesService(baseUrl: ApiService.baseUrl);
        final canStart = await livesService.canStartLesson(token);
        if (!canStart) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No tenés vidas disponibles. Esperá la recarga para continuar.',
              ),
              backgroundColor: AppColors.textStrong,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final nodeData = await ApiService.getLearningNode(nodeId);

      if (!mounted) return;
      Navigator.of(context).pop();

      // Convertir nodeData a LearningNode
      final learningNode = LearningNode.fromJson(nodeData);

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonGameScreen(node: learningNode),
        ),
      );

      widget.onLessonExit?.call();

      // Refresh path data if lesson was completed successfully
      if (result == true && mounted) {
        _pendingRestoreOffset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;
        _fadeController.reset();
        _fadeController.forward();
        await _loadInitialPathData();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _restoreScrollPositionIfNeeded();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar la lección: $e'),
          backgroundColor: AppColors.textStrong,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  NodeStatus _getNodeStatus(String status) {
    switch (status) {
      case 'completed':
        return NodeStatus.completed;
      case 'locked':
        return NodeStatus.locked;
      case 'available':
      case 'unlocked':
      case 'active':
        return NodeStatus.active;
      default:
        return NodeStatus.locked;
    }
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
        return id?.toString() == widget.pathId;
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

  String? _extractEntityId(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'] ?? raw['\$oid'];
      if (id == null) return null;
      return _extractEntityId(id);
    }

    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? _extractGroupTitle(dynamic raw) {
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    if (raw is! Map) return null;

    final title =
        raw['title']?.toString().trim() ?? raw['name']?.toString().trim() ?? '';
    return title.isEmpty ? null : title;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _pathData['nodes'] as List<dynamic>? ?? [];
    final groups = _pathData['groups'] as List<dynamic>? ?? [];

    Widget content;
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (_errorMessage != null) {
      content = _buildErrorState();
    } else if (nodes.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildNodePath(nodes, groups),
            if (_hasMore)
              Positioned(
                right: 16,
                bottom: 16,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingMoreNotifier,
                  builder: (context, isLoadingMore, _) => FilledButton(
                    onPressed: isLoadingMore ? null : _loadMorePathData,
                    child: isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cargar más'),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: IgnorePointer(
                ignoring: true,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingMoreNotifier,
                  builder: (context, isLoadingMore, _) => AnimatedOpacity(
                    opacity: isLoadingMore ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.showAppBar) {
      return Container(color: AppColors.background, child: content);
    }

    return AppScaffold(appBar: _buildAppBar(), body: content);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppHeader(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        color: AppColors.textSecondary,
      ),
      title: Text(
        widget.pathTitle,
        style: AppTypography.cardTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: Center(child: UserXPBadge()),
        ),
      ],
    );
  }

  Widget _buildNodePath(List<dynamic> nodes, List<dynamic> groups) {
    final nodeList = nodes.whereType<Map<String, dynamic>>().toList();
    final groupList = groups.whereType<Map<String, dynamic>>().toList();
    final groupTitleById = <String, String>{};
    for (final group in groupList) {
      final id = _extractEntityId(group);
      final title = _extractGroupTitle(group);
      if (id != null && title != null && title.isNotEmpty) {
        groupTitleById[id] = title;
      }
    }
    const ungroupedKey = '__ungrouped__';

    final groupedNodes = <String, List<Map<String, dynamic>>>{};
    for (final node in nodeList) {
      final rawGroupId = node['groupId'];
      final groupId = _extractEntityId(rawGroupId);
      final normalizedGroupId = groupId == null || groupId.isEmpty
          ? ungroupedKey
          : groupId;

      final mappedTitle = _extractGroupTitle(rawGroupId);
      if (normalizedGroupId != ungroupedKey &&
          mappedTitle != null &&
          mappedTitle.isNotEmpty) {
        groupTitleById.putIfAbsent(normalizedGroupId, () => mappedTitle);
      }

      final directGroupTitle = _extractGroupTitle(node['groupTitle']);
      if (normalizedGroupId != ungroupedKey &&
          directGroupTitle != null &&
          directGroupTitle.isNotEmpty) {
        groupTitleById.putIfAbsent(normalizedGroupId, () => directGroupTitle);
      }

      groupedNodes.putIfAbsent(normalizedGroupId, () => []).add(node);
    }

    groupList.sort(
      (a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num),
    );

    final orderedGroupIds = groupList
        .map((group) => group['_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final orderedGroupSet = orderedGroupIds.toSet();
    for (final groupId in groupedNodes.keys) {
      if (groupId == ungroupedKey) continue;
      if (!orderedGroupSet.contains(groupId)) {
        orderedGroupIds.add(groupId);
        orderedGroupSet.add(groupId);
      }
    }
    if (groupedNodes.containsKey(ungroupedKey)) {
      orderedGroupIds.add(ungroupedKey);
    }

    final orderedNodes = <Map<String, dynamic>>[];
    final orderedNodeGroupIds = <String>[];
    final groupStartIndex = <String, int>{};
    for (final groupId in orderedGroupIds) {
      final groupNodes = groupedNodes[groupId] ?? [];
      groupNodes.sort((a, b) {
        final levelA = (a['level'] ?? 1) as int;
        final levelB = (b['level'] ?? 1) as int;
        if (levelA != levelB) return levelA.compareTo(levelB);
        final posA = (a['positionIndex'] ?? 1) as int;
        final posB = (b['positionIndex'] ?? 1) as int;
        if (posA != posB) return posA.compareTo(posB);
        final orderA = (a['order'] ?? 0) as int;
        final orderB = (b['order'] ?? 0) as int;
        return orderA.compareTo(orderB);
      });
      if (groupNodes.isNotEmpty) {
        groupStartIndex[groupId] = orderedNodes.length;
        orderedNodes.addAll(groupNodes);
        orderedNodeGroupIds.addAll(List.filled(groupNodes.length, groupId));
      }
    }

    // Calcular estadísticas
    final completedCount = orderedNodes
        .where((n) => n['status'] == 'completed')
        .length;
    final totalCount = orderedNodes.length;
    var currentLevel = completedCount + 1;
    if (currentLevel < 1) currentLevel = 1;
    if (currentLevel > totalCount && totalCount > 0) {
      currentLevel = totalCount;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final minX = width * 0.2;
        final maxX = width * 0.8;
        const rowSpacing = 240.0;
        const groupGap = 120.0;
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

        int parseInt(dynamic value, {int fallback = 0}) {
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse(value?.toString() ?? '') ?? fallback;
        }

        nodePositions
          ..clear()
          ..addAll(List.filled(orderedNodes.length, Offset.zero));
        final nodeTitleWidthByIndex = <int, double>{};

        final connectionPairs = <List<int>>[];
        final connectionPairKeys = <String>{};

        void addConnectionPair(int from, int to) {
          final key = '$from->$to';
          if (connectionPairKeys.add(key)) {
            connectionPairs.add([from, to]);
          }
        }

        var currentY = 60.0;

        for (final groupId in orderedGroupIds) {
          final groupNodeIndices = <int>[];
          for (int i = 0; i < orderedNodeGroupIds.length; i++) {
            if (orderedNodeGroupIds[i] == groupId) {
              groupNodeIndices.add(i);
            }
          }
          if (groupNodeIndices.isEmpty) continue;

          final levelBuckets = <int, List<int>>{};
          final orderedLevels = <int>[];

          for (final nodeIndex in groupNodeIndices) {
            final node = orderedNodes[nodeIndex];
            final level = parseInt(node['level'], fallback: 1);
            if (!levelBuckets.containsKey(level)) {
              levelBuckets[level] = <int>[];
              orderedLevels.add(level);
            }
            levelBuckets[level]!.add(nodeIndex);
          }

          orderedLevels.sort();
          List<int>? previousLevelNodeIndices;

          for (final level in orderedLevels) {
            final levelNodeIndices = levelBuckets[level]!
              ..sort((a, b) {
                final posA = parseInt(
                  orderedNodes[a]['positionIndex'],
                  fallback: 0,
                );
                final posB = parseInt(
                  orderedNodes[b]['positionIndex'],
                  fallback: 0,
                );
                if (posA != posB) return posA.compareTo(posB);
                final orderA = parseInt(orderedNodes[a]['order'], fallback: 0);
                final orderB = parseInt(orderedNodes[b]['order'], fallback: 0);
                return orderA.compareTo(orderB);
              });

            final levelCount = levelNodeIndices.length;
            final titleMaxWidth = levelCount <= 1
                ? 124.0
                : (((maxX - minX) / (levelCount - 1)) - 18).clamp(74.0, 124.0);
            for (int j = 0; j < levelCount; j++) {
              final x = levelCount == 1
                  ? width * 0.5
                  : minX + ((maxX - minX) * (j / (levelCount - 1)));
              nodePositions[levelNodeIndices[j]] = Offset(x, currentY);
              nodeTitleWidthByIndex[levelNodeIndices[j]] = titleMaxWidth;
            }

            if (previousLevelNodeIndices != null &&
                previousLevelNodeIndices.isNotEmpty) {
              final prevCount = previousLevelNodeIndices.length;
              final currentCount = levelNodeIndices.length;

              if (prevCount == currentCount) {
                for (int j = 0; j < currentCount; j++) {
                  addConnectionPair(
                    previousLevelNodeIndices[j],
                    levelNodeIndices[j],
                  );
                }
              } else if (prevCount > currentCount) {
                for (int j = 0; j < prevCount; j++) {
                  final mappedIndex = currentCount == 1
                      ? 0
                      : ((j * (currentCount - 1)) / (prevCount - 1)).round();
                  addConnectionPair(
                    previousLevelNodeIndices[j],
                    levelNodeIndices[mappedIndex],
                  );
                }
              } else {
                for (int j = 0; j < currentCount; j++) {
                  final mappedIndex = prevCount == 1
                      ? 0
                      : ((j * (prevCount - 1)) / (currentCount - 1)).round();
                  addConnectionPair(
                    previousLevelNodeIndices[mappedIndex],
                    levelNodeIndices[j],
                  );
                }
              }
            }

            previousLevelNodeIndices = levelNodeIndices;
            currentY += rowSpacing;
          }

          currentY += groupGap;
        }

        final groupHeaders = <Map<String, dynamic>>[];
        final breakIndices = <int>{}; // Compatibilidad legacy para painter

        for (final groupId in orderedGroupIds) {
          if (groupId == ungroupedKey) continue;
          final index = groupStartIndex[groupId];
          final title = groupTitleById[groupId] ?? '';
          final groupNodeCount = (groupedNodes[groupId] ?? []).length;

          // Solo mostrar título si grupo tiene nodos y título no está vacío
          if (index == null || title.isEmpty || groupNodeCount < 1) continue;

          // Añadir índice de corte (excepto el primero)
          if (index > 0) {
            breakIndices.add(index);
          }

          // Posicionar el título ANTES del primer nodo del grupo
          final nodeY = (index < nodePositions.length
              ? nodePositions[index].dy
              : 20.0);
          final y = (nodeY - 96).clamp(0.0, double.infinity);
          groupHeaders.add({'title': title, 'y': y});
        }

        final totalHeight = orderedNodes.isNotEmpty
            ? ((nodePositions
                      .map((offset) => offset.dy)
                      .fold<double>(
                        0,
                        (maxValue, value) =>
                            value > maxValue ? value : maxValue,
                      )) +
                  200)
            : 100.0;

        return Column(
          children: [
            // Bloque de progreso (Fixed at top)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: ProgressCard(
                levelText: 'Nivel $currentLevel',
                progress: totalCount > 0 ? completedCount / totalCount : 0,
                subtitle:
                    '$completedCount de $totalCount lecciones completadas',
              ),
            ),

            // Contenido scrolleable (Expanded)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: totalHeight,
                  child: Stack(
                    children: [
                      // Dibujar lineas de conexion
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathConnectorPainter(
                            nodePositions: nodePositions,
                            lineColor: AppColors.border,
                            strokeWidth: 3,
                            breakIndices: breakIndices,
                            connectionPairs: connectionPairs,
                            nodeCircleDiameter: nodeCircleDiameter,
                            lineStartYOffset: connectorStartYOffset,
                            lineEndYOffset: connectorEndYOffset,
                            horizontalAnchorNudge: connectorHorizontalNudge,
                            curveHorizontalFactor: 0.2,
                          ),
                        ),
                      ),

                      // Dibujar conectores entre nodos
                      ...List.generate(connectionPairs.length, (index) {
                        final pair = connectionPairs[index];
                        if (pair.length < 2) {
                          return const SizedBox.shrink();
                        }

                        final from = pair[0];
                        final to = pair[1];
                        if (from >= nodePositions.length ||
                            to >= nodePositions.length) {
                          return const SizedBox.shrink();
                        }

                        final startRaw = nodePositions[from];
                        final endRaw = nodePositions[to];
                        final start = connectorStartAnchor(startRaw, endRaw);
                        final end = connectorEndAnchor(startRaw, endRaw);
                        final midX = (start.dx + end.dx) / 2;
                        final midY = (start.dy + end.dy) / 2;

                        return Positioned(
                          left: midX - 4,
                          top: midY - 4,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 600 + (index * 150),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.border,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                      // Dibujar títulos de grupos
                      ...List.generate(groupHeaders.length, (index) {
                        final groupHeader = groupHeaders[index];
                        final y = groupHeader['y'] as double;
                        final title = groupHeader['title'] as String;

                        return Positioned(
                          left: 0,
                          top: y,
                          right: 0,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, -10 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Dibujar nodos encima
                      ...List.generate(orderedNodes.length, (index) {
                        if (index >= nodePositions.length) {
                          return const SizedBox.shrink();
                        }

                        try {
                          final node =
                              orderedNodes[index] as Map<String, dynamic>?;
                          if (node == null) {
                            return const SizedBox.shrink();
                          }

                          final nodeId =
                              (node['_id'] ?? node['id'] ?? '') as String;
                          final title =
                              (node['title'] ?? 'Nodo ${index + 1}') as String;
                          final xpReward = (node['xpReward'] ?? 0) as int;
                          final status = _getNodeStatus(
                            (node['status'] ?? 'locked') as String,
                          );
                          final nodeType = (node['type'] ?? 'recipe') as String;

                          final position = nodePositions[index];
                          final titleMaxWidth =
                              nodeTitleWidthByIndex[index] ?? 110.0;
                          final nodeWidgetWidth =
                              titleMaxWidth < nodeCircleDiameter
                              ? nodeCircleDiameter
                              : titleMaxWidth;

                          return Positioned(
                            left: position.dx - (nodeWidgetWidth / 2),
                            top: position.dy,
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(nodeId),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
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
                                nodeId: nodeId,
                                title: title,
                                xpReward: xpReward,
                                status: status,
                                nodeType: nodeType,
                                index: index,
                                titleMaxWidth: titleMaxWidth,
                                nodeWidth: nodeWidgetWidth,
                                onTap: status != NodeStatus.locked
                                    ? () =>
                                          _startLesson(nodeId, title, nodeType)
                                    : null,
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Error renderizando nodo $index: $e');
                          return const SizedBox.shrink();
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "¡Oops! Algo salió mal",
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 8),
            Text(
              "No pudimos cargar el camino de aprendizaje",
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Reintentar',
              onPressed: () {
                _fadeController.reset();
                _fadeController.forward();
                _loadInitialPathData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Aun no hay lecciones',
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 8),
            Text(
              "Pronto habrán nuevas experiencias culinarias disponibles",
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final String nodeId;
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;
  final bool isLocked;
  final String nodeType;

  const _NodeCard({
    required this.nodeId,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isCompleted,
    required this.isLocked,
    required this.nodeType,
  });

  String _getNodeIcon() {
    switch (nodeType) {
      case 'recipe':
        return '🍳';
      case 'skill':
        return '🎓';
      case 'quiz':
        return '❓';
      default:
        return '📚';
    }
  }

  Color _getNodeColor() {
    if (isCompleted) return AppColors.success;
    if (isLocked) return AppColors.textSecondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface,
            border: Border(left: BorderSide(color: _getNodeColor(), width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getNodeIcon(), style: const TextStyle(fontSize: 32)),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    )
                  else if (isLocked)
                    const Icon(Icons.lock, color: Colors.grey, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLocked
                      ? AppColors.textSecondary
                      : AppColors.textStrong,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNodeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$xpReward XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getNodeColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineConnector extends StatelessWidget {
  final Widget child;
  final bool isLeft;
  final bool isFirst;
  final bool isLast;

  const _LineConnector({
    required this.child,
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineConnectorPainter(
        isLeft: isLeft,
        isFirst: isFirst,
        isLast: isLast,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isLeft ? 0 : 0,
          right: isLeft ? 0 : 0,
          top: isFirst ? 0 : 20,
          bottom: isLast ? 0 : 20,
        ),
        child: child,
      ),
    );
  }
}

class _LineConnectorPainter extends CustomPainter {
  final bool isLeft;
  final bool isFirst;
  final bool isLast;

  _LineConnectorPainter({
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!isFirst) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, 20),
        paint,
      );
    }

    if (!isLast) {
      canvas.drawLine(
        Offset(size.width / 2, size.height - 20),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LineConnectorPainter oldDelegate) => false;
}
