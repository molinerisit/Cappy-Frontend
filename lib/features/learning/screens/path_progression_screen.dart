import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../../core/api_service.dart';
import '../../../core/lives_service.dart';
import '../../../core/models/learning_node.dart';
import '../../../providers/auth_provider.dart';
import '../../path_progression/data/path_repository.dart';
import '../../path_progression/presentation/path_controller.dart';
import '../../path_progression/domain/optimized_layout_engine.dart';
import '../../path_progression/domain/models/path_node.dart';
import '../../path_progression/widgets/optimized_path_canvas.dart';
import '../../path_progression/widgets/path_progress_header.dart';
import 'lesson_game_screen.dart';
import '../../../widgets/user_xp_badge.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/lives_widget.dart';

class PathProgressionScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;
  final bool showAppBar;
  final VoidCallback? onLessonExit;
  final VoidCallback? onChangeRoute;

  const PathProgressionScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
    this.showAppBar = true,
    this.onLessonExit,
    this.onChangeRoute,
  });

  @override
  State<PathProgressionScreen> createState() => _PathProgressionScreenState();
}

class _PathProgressionScreenState extends State<PathProgressionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ConfettiController _completionConfettiController;
  late ConfettiController _levelUpConfettiController;
  late PathController _pathController;
  late LivesService _livesService;
  late ScrollController _scrollController;
  OptimizedLayoutResult? _cachedLayout;
  double _lastCanvasWidth = 0;
  bool _scrolledToCurrentLevel = false;
  int _currentLives = 3;
  int _maxLives = 3;
  DateTime? _nextRefillAt;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _pathController = PathController(
      repository: PathRepository(widget.pathId),
      pageSize: 40,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _completionConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );

    _levelUpConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );

    _fadeController.forward();
    _pathController.loadInitial();
    _loadLivesStatus();
  }

  @override
  void didUpdateWidget(covariant PathProgressionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathId != widget.pathId) {
      _cachedLayout = null;
      _scrolledToCurrentLevel = false;
      _pathController = PathController(
        repository: PathRepository(widget.pathId),
        pageSize: 40,
      );
      _fadeController.reset();
      _fadeController.forward();
      _pathController.loadInitial();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _completionConfettiController.dispose();
    _levelUpConfettiController.dispose();
    _scrollController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _startLesson(PathNode node) async {
    if (!mounted) return;

    final previousAuthLevel = context.read<AuthProvider>().level;

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

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final nodeData = await ApiService.getLearningNode(node.id);

      if (!mounted) return;
      Navigator.of(context).pop();

      final learningNode = LearningNode.fromJson(nodeData);

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonGameScreen(node: learningNode),
        ),
      );

      widget.onLessonExit?.call();

      if (result == true && mounted) {
        _cachedLayout = null;
        _scrolledToCurrentLevel = false;
        _fadeController.reset();
        _fadeController.forward();
        await _pathController.refresh();
        await _loadLivesStatus();
        if (!mounted) return;
        _showCompletionReward(node.xpReward);

        final nextAuthLevel = context.read<AuthProvider>().level;
        if (nextAuthLevel > previousAuthLevel) {
          _showLevelUpDialog(nextAuthLevel);
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

  @override
  Widget build(BuildContext context) {
    Widget content;

    content = AnimatedBuilder(
      animation: _pathController,
      builder: (context, child) {
        if (_pathController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (_pathController.errorMessage != null) {
          return _buildErrorState();
        }

        if (_pathController.nodes.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(opacity: _fadeAnimation, child: _buildContent());
      },
    );

    final layeredContent = Stack(
      children: [
        Positioned.fill(child: content),
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _completionConfettiController,
              blastDirectionality: BlastDirectionality.directional,
              blastDirection: 1.57,
              emissionFrequency: 0.09,
              numberOfParticles: 18,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                Color(0xFFFACC15),
                Color(0xFFEF4444),
                Colors.white,
              ],
              minimumSize: Size(5, 5),
              maximumSize: Size(10, 10),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _levelUpConfettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.075,
              numberOfParticles: 38,
              gravity: 0.14,
              blastDirection: 1.57,
              minBlastForce: 8,
              maxBlastForce: 22,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                Color(0xFFF59E0B),
                Color(0xFFFACC15),
                Color(0xFFEF4444),
                Colors.white,
              ],
              minimumSize: Size(6, 6),
              maximumSize: Size(14, 14),
            ),
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return layeredContent;
    }

    return AppScaffold(appBar: _buildAppBar(), body: layeredContent);
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: LivesWidget(
              lives: _currentLives,
              maxLives: _maxLives,
              nextRefillAt: _nextRefillAt,
              onLiveAnimationComplete: () => _loadLivesStatus(),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: UserXPBadge()),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final auth = context.watch<AuthProvider>();
    final profileLevel = auth.level < 1 ? 1 : auth.level;
    final xpForCurrentLevel = (profileLevel - 1) * 100;
    final xpForNextLevel = profileLevel * 100;
    final currentLevelXp = (auth.totalXP - xpForCurrentLevel).clamp(
      0,
      xpForNextLevel - xpForCurrentLevel,
    );

    return Column(
      children: [
        PathProgressHeader(
          currentLevel: profileLevel,
          completedCount: _pathController.completedCount,
          totalCount: _pathController.totalCount,
          streakDays: auth.streak,
          currentXp: currentLevelXp,
          nextLevelXp: xpForNextLevel - xpForCurrentLevel,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              Text(
                'Continúa aprendiendo',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasWidth = constraints.maxWidth;

                // Verificar si necesitamos recalcular el layout
                final needsRecalculation =
                    _cachedLayout == null ||
                    _lastCanvasWidth != canvasWidth ||
                    _cachedLayout!.levelGroups.fold<int>(
                          0,
                          (sum, group) => sum + group.nodes.length,
                        ) !=
                        _pathController.nodes.length;

                if (needsRecalculation) {
                  _cachedLayout =
                      OptimizedLayoutEngine.calculateOptimizedLayout(
                        nodes: _pathController.nodes,
                        groupTitles: _pathController.groupTitles,
                        canvasWidth: canvasWidth,
                      );
                  _lastCanvasWidth = canvasWidth;

                  // Scroll automático al nivel actual después de calcular
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentLevel();
                  });
                }

                return OptimizedPathCanvas(
                  layout: _cachedLayout!,
                  onNodeTap: _startLesson,
                  scrollController: _scrollController,
                  onLoadMore: _loadMore,
                  hasMore: _pathController.hasMore,
                  isLoadingMore: _pathController.isLoadingMore,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadLivesStatus() async {
    try {
      final token = ApiService.getToken();
      if (token == null || token.isEmpty) return;
      final status = await _livesService.getLivesStatus(token);
      if (!mounted) return;
      setState(() {
        _currentLives = status['lives'] ?? _currentLives;
        _maxLives = status['maxLives'] ?? 3;
        if (status['nextRefillAt'] != null) {
          _nextRefillAt = DateTime.parse(status['nextRefillAt']);
        }
      });
    } catch (_) {}
  }

  void _showCompletionReward(int xpReward) {
    if (!mounted) return;
    _completionConfettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Lección completada • +$xpReward XP'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textStrong,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLevelUpDialog(int newLevel) {
    if (!mounted) return;
    _levelUpConfettiController.play();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎆', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  Text(
                    '¡Subiste de nivel!',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ahora estás en Nivel $newLevel',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Continuar',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollToCurrentLevel() {
    if (_cachedLayout == null ||
        _scrolledToCurrentLevel ||
        !_scrollController.hasClients) {
      return;
    }

    final currentLevel = _pathController.currentLevel;
    if (currentLevel <= 1) return;

    double targetY = 0;
    for (int i = 0; i < _cachedLayout!.levelGroups.length; i++) {
      final group = _cachedLayout!.levelGroups[i];
      if (group.level >= currentLevel) {
        targetY = group.startY;
        break;
      }
    }

    if (targetY > 0) {
      _scrolledToCurrentLevel = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetY.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_pathController.isLoadingMore || !_pathController.hasMore) {
      return;
    }
    await _pathController.loadMore();
    if (mounted) {
      setState(() {
        _cachedLayout = null;
      });
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
                _cachedLayout = null;
                _scrolledToCurrentLevel = false;
                _fadeController.reset();
                _fadeController.forward();
                _pathController.loadInitial();
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
