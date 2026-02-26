import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
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

  const PathProgressionScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
    this.showAppBar = true,
  });

  @override
  State<PathProgressionScreen> createState() => _PathProgressionScreenState();
}

class _PathProgressionScreenState extends State<PathProgressionScreen>
    with TickerProviderStateMixin {
  late Future<dynamic> futurePathData;
  final List<Offset> nodePositions = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    futurePathData = ApiService.getPath(widget.pathId);

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
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startLesson(
    String nodeId,
    String title,
    String nodeType,
  ) async {
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

      // Refresh path data if lesson was completed successfully
      if (result == true && mounted) {
        setState(() {
          futurePathData = ApiService.getPath(widget.pathId);
          _fadeController.reset();
          _fadeController.forward();
        });
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
      final idCandidate = raw['_id'] ?? raw['id'] ?? raw['\$oid'];
      if (idCandidate != null) {
        final nested = _extractEntityId(idCandidate);
        if (nested != null && nested.isNotEmpty) return nested;
      }
      return null;
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
    final content = FutureBuilder<dynamic>(
      future: futurePathData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (snapshot.hasError) {
          return _buildErrorState();
        }

        final normalized = _normalizePathData(snapshot.data);
        final nodes = normalized['nodes'] as List<dynamic>? ?? [];
        final groups = normalized['groups'] as List<dynamic>? ?? [];

        if (nodes.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildNodePath(nodes, groups),
        );
      },
    );

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
      title: Text(widget.pathTitle, style: AppTypography.cardTitle),
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
      if (id != null && id.isNotEmpty && title != null && title.isNotEmpty) {
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

      final nodeGroupTitle = _extractGroupTitle(rawGroupId);
      if (normalizedGroupId != ungroupedKey &&
          nodeGroupTitle != null &&
          nodeGroupTitle.isNotEmpty) {
        groupTitleById.putIfAbsent(normalizedGroupId, () => nodeGroupTitle);
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
        final leftX = width * 0.25;
        final rightX = width * 0.75;
        final verticalSpacing = 240.0; // Increased spacing
        const headerOffset = 120.0;
        const nodeRadius = 56.0;

        // Calcular posiciones de nodos
        nodePositions.clear();
        for (int i = 0; i < orderedNodes.length; i++) {
          final isLeft = i % 2 == 0;
          final x = isLeft ? leftX : rightX;
          final y = 20.0 + (i * verticalSpacing);
          nodePositions.add(Offset(x, y));
        }

        // Usar las posiciones de nodos directamente para las líneas
        final linePositions = nodePositions;

        final groupHeaders = <Map<String, dynamic>>[];
        final breakIndices = <int>{}; // Índices donde cortar las líneas

        print('🎯 [PathProgressionScreen] Group separation:');
        for (final groupId in orderedGroupIds) {
          if (groupId == ungroupedKey) continue;
          final index = groupStartIndex[groupId];
          final title = groupTitleById[groupId] ?? '';
          final groupNodeCount = (groupedNodes[groupId] ?? []).length;

          // Mostrar separación de grupo solo si tiene nodos
          if (index == null || groupNodeCount < 1) continue;

          final resolvedTitle = title.trim();

          print('  Group "$resolvedTitle" starts at index $index');

          // Añadir índice de corte (excepto el primero)
          if (index > 0) {
            breakIndices.add(index);
            print('    -> Added break at index $index');
          }

          // Posicionar el título ANTES del primer nodo del grupo
          final nodeY = 20.0 + (index * 240.0);
          final y = (nodeY - 80).clamp(0.0, double.infinity);
          if (resolvedTitle.isNotEmpty) {
            groupHeaders.add({'title': resolvedTitle, 'y': y});
          }
        }
        print('  Total breakIndices: $breakIndices');

        return Column(
          children: [
            // Bloque de progreso (Fixed at top)
            Padding(
              padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: orderedNodes.isNotEmpty
                      ? 20 + (orderedNodes.length * 240.0) + 120
                      : 100,
                  child: Stack(
                    children: [
                      // Dibujar lineas de conexion
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathConnectorPainter(
                            nodePositions: linePositions,
                            lineColor: AppColors.border,
                            strokeWidth: 2,
                            breakIndices: breakIndices,
                          ),
                        ),
                      ),

                      // Dibujar conectores entre nodos
                      ...List.generate(orderedNodes.length - 1, (index) {
                        if (index + 1 >= linePositions.length) {
                          return const SizedBox.shrink();
                        }

                        // Saltar conectores en puntos de corte de grupo
                        if (breakIndices.contains(index + 1)) {
                          return const SizedBox.shrink();
                        }

                        final start = linePositions[index];
                        final end = linePositions[index + 1];
                        final midX = (start.dx + end.dx) / 2;
                        final midY = (start.dy + end.dy) / 2;

                        return Positioned(
                          left: midX - 6,
                          top: midY - 6,
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

                          return Positioned(
                            left: position.dx - 56,
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
                setState(() {
                  futurePathData = ApiService.getPath(widget.pathId);
                  _fadeController.reset();
                  _fadeController.forward();
                });
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
