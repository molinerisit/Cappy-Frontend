import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_scaffold.dart';

class FollowGoalsScreen extends StatefulWidget {
  const FollowGoalsScreen({super.key});

  @override
  State<FollowGoalsScreen> createState() => _FollowGoalsScreenState();
}

class _FollowGoalsScreenState extends State<FollowGoalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isChangingPath = false;
  final int _pageSize = 12;
  final List<dynamic> _goalPaths = [];
  bool _isLoading = true;
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier(false);
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;
  DateTime? _lastLoadMoreAt;
  static const Duration _loadMoreCooldown = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialGoals();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  Future<void> _loadInitialGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _goalPaths.clear();
      _currentPage = 1;
    });

    await _fetchGoalsPage(page: 1, append: false);
  }

  Future<void> _loadMoreGoals() async {
    if (_isLoadingMoreNotifier.value || !_hasMore) return;
    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < _loadMoreCooldown) {
      return;
    }
    _lastLoadMoreAt = now;

    _isLoadingMoreNotifier.value = true;
    await _fetchGoalsPage(page: _currentPage + 1, append: true);
    _isLoadingMoreNotifier.value = false;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore) return;
    if (_isLoading || _isLoadingMoreNotifier.value) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final triggerOffset = position.maxScrollExtent * 0.8;
    if (position.pixels >= triggerOffset) {
      _loadMoreGoals();
    }
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

  Future<void> _fetchGoalsPage({
    required int page,
    required bool append,
  }) async {
    final stopwatch = Stopwatch()..start();
    int fetchedCount = 0;
    bool hasMore = false;
    String status = 'ok';

    try {
      final response = await ApiService.getGoalPathsPaginated(
        page: page,
        limit: _pageSize,
      );

      final items = response['data'] as List<dynamic>? ?? <dynamic>[];
      final pagination = response['pagination'] as Map<String, dynamic>?;
      hasMore = pagination?['hasMore'] == true;
      fetchedCount = items.length;

      setState(() {
        _currentPage = page;
        _hasMore = hasMore;
        final merged = append
            ? <dynamic>[..._goalPaths, ...items]
            : <dynamic>[...items];
        _goalPaths
          ..clear()
          ..addAll(_dedupeByEntityId(merged));
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
          '[Pagination][Goals] page=$page append=$append fetched=$fetchedCount hasMore=$hasMore status=$status ms=${stopwatch.elapsedMilliseconds}',
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
    _animationController.dispose();
    _isLoadingMoreNotifier.dispose();
    super.dispose();
  }

  Future<void> _selectPath(String pathId, String pathTitle) async {
    setState(() => _isChangingPath = true);
    try {
      await ApiService.changeCurrentPath(pathId);
      if (!mounted) return;
      // Navega de vuelta a main experience (el árbol del camino)
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isChangingPath = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChangingPath) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Objetivos', style: AppTypography.cardTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF27AE60)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_goalPaths.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Cual es tu objetivo?', style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Elige un camino personalizado para alcanzar tu meta',
                  style: AppTypography.subtitle,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: _goalPaths.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _goalPaths.length) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingMoreNotifier,
                        builder: (context, isLoadingMore, _) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppButton(
                            label: isLoadingMore ? 'Cargando...' : 'Cargar más',
                            onPressed: isLoadingMore ? () {} : _loadMoreGoals,
                          ),
                        ),
                      );
                    }

                    final goalPath = _goalPaths[index];
                    final pathId = goalPath['_id'] ?? goalPath['id'] ?? '';
                    final title = goalPath['title'] ?? 'Objetivo';
                    final description = goalPath['description'] ?? '';
                    final icon = goalPath['icon'] ?? '🎯';
                    final goalType = goalPath['goalType'] ?? '';
                    final totalNodes =
                        (goalPath['totalNodes'] as num?)?.toInt() ??
                        ((goalPath['nodes'] as List<dynamic>?)?.length ?? 0);
                    final accentColor = _getGoalColor(goalType);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _GoalCard(
                        pathId: pathId,
                        title: title,
                        description: description,
                        icon: icon,
                        goalType: goalType,
                        nodesCount: totalNodes,
                        accentColor: accentColor,
                        onSelected: _selectPath,
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.md,
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
          ),
        ],
      ),
    );
  }

  Color _getGoalColor(String goalType) {
    switch (goalType) {
      case 'cooking_school':
        return const Color(0xFFB45309);
      case 'lose_weight':
        return const Color(0xFF1D4ED8);
      case 'gain_muscle':
        return const Color(0xFFB91C1C);
      case 'become_vegan':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
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
            Text('Error al cargar objetivos', style: AppTypography.cardTitle),
            const SizedBox(height: 8),
            Text(
              'Intenta de nuevo en unos momentos',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Reintentar',
              onPressed: () {
                _loadInitialGoals();
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
            const Text('🎯', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text('Aun no hay objetivos', style: AppTypography.cardTitle),
            const SizedBox(height: 8),
            Text(
              'Pronto agregaremos nuevos caminos de aprendizaje',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final String pathId;
  final String title;
  final String description;
  final String icon;
  final String goalType;
  final int nodesCount;
  final Color accentColor;
  final Function(String, String) onSelected;

  const _GoalCard({
    required this.pathId,
    required this.title,
    required this.description,
    required this.icon,
    required this.goalType,
    required this.nodesCount,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => widget.onSelected(widget.pathId, widget.title),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(widget.icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                const SizedBox(height: 10),
                AppBadge(text: '${widget.nodesCount} lecciones'),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
