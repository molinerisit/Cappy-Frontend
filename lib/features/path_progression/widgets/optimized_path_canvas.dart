import 'package:flutter/material.dart';
import '../domain/optimized_layout_engine.dart';
import '../domain/models/path_node.dart';
import '../../learning/widgets/skill_node.dart';
import 'roadmap_painter.dart';
import 'level_section.dart';
import 'path_group_header.dart';
import '../../../theme/colors.dart';

class OptimizedPathCanvas extends StatefulWidget {
  final OptimizedLayoutResult layout;
  final void Function(PathNode node) onNodeTap;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  const OptimizedPathCanvas({
    super.key,
    required this.layout,
    required this.onNodeTap,
    this.scrollController,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  State<OptimizedPathCanvas> createState() => _OptimizedPathCanvasState();
}

class _OptimizedPathCanvasState extends State<OptimizedPathCanvas> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(OptimizedPathCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController.removeListener(_onScroll);
      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null || !widget.hasMore || widget.isLoadingMore) {
      return;
    }

    final threshold = 200.0;
    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _buildItemAtIndex(index);
          }, childCount: _calculateItemCount()),
        ),
        if (widget.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _calculateItemCount() {
    int count = 0;
    for (int i = 0; i < widget.layout.levelGroups.length; i++) {
      final header = _findHeaderForLevel(i);
      if (header != null) count++;
      count++;
    }
    return count;
  }

  Widget _buildItemAtIndex(int index) {
    int itemIndex = 0;

    for (
      int levelIndex = 0;
      levelIndex < widget.layout.levelGroups.length;
      levelIndex++
    ) {
      final header = _findHeaderForLevel(levelIndex);

      if (header != null) {
        if (itemIndex == index) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: PathGroupHeader(title: header.title, index: levelIndex),
          );
        }
        itemIndex++;
      }

      if (itemIndex == index) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label de nivel (solo para debug/visualización)
            if (levelIndex > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nivel ${widget.layout.levelGroups[levelIndex].level}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            _buildLevelWithConnections(levelIndex),
          ],
        );
      }
      itemIndex++;
    }

    return const SizedBox.shrink();
  }

  GroupHeaderData? _findHeaderForLevel(int levelIndex) {
    if (widget.layout.groupHeaders.isEmpty) return null;

    final levelGroup = widget.layout.levelGroups[levelIndex];

    for (final header in widget.layout.groupHeaders) {
      if ((header.y - levelGroup.startY).abs() < 50) {
        return header;
      }
    }

    return null;
  }

  Widget _buildLevelWithConnections(int levelIndex) {
    final levelGroup = widget.layout.levelGroups[levelIndex];

    // Calcular altura dinámica basada en nodos por fila
    final nodeCount = levelGroup.nodes.length;

    // Altura base de un nodo: ~120px círculo + ~40px título = 160px
    // Con padding y wrap spacing: +24px entre filas
    final double nodeHeight = 160.0;
    final double rowSpacing = 24.0;

    double calculatedHeight;
    if (nodeCount == 1) {
      // 1 nodo: altura single
      calculatedHeight = nodeHeight + 32.0; // +padding
    } else if (nodeCount == 2) {
      // 2 nodos: 1 fila
      calculatedHeight = nodeHeight + 24.0;
    } else if (nodeCount <= 4) {
      // 3-4 nodos: 2 filas
      calculatedHeight = (nodeHeight * 2) + rowSpacing + 24.0;
    } else {
      // 5+ nodos: 3 filas
      calculatedHeight = (nodeHeight * 3) + (rowSpacing * 2) + 24.0;
    }

    return SizedBox(
      height: calculatedHeight,
      child: LevelSection(levelGroup: levelGroup, onNodeTap: widget.onNodeTap),
    );
  }
}
