import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_selection_provider.dart';
import '../../../core/lives_service.dart';
import '../../../core/api_service.dart';
import 'culinary_experience_screen.dart';
import 'follow_goals_screen.dart';
import 'country_hub_screen.dart';
import 'path_progression_screen.dart';
import '../../../screens/global_leaderboard_screen.dart';
import '../../../features/profile/profile_screen.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_bottom_nav.dart';

class MainExperienceScreen extends StatefulWidget {
  final String? initialPathId;
  final String? initialPathTitle;

  const MainExperienceScreen({
    super.key,
    this.initialPathId,
    this.initialPathTitle,
  });

  @override
  State<MainExperienceScreen> createState() => _MainExperienceScreenState();
}

class _MainExperienceScreenState extends State<MainExperienceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lives system
  late LivesService _livesService;
  int _currentLives = 3;

  // Current path info
  String? _currentPathId;
  String? _currentPathName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLives();

    // Si se pasó un pathId inicial, usarlo directamente
    if (widget.initialPathId != null) {
      _currentPathId = widget.initialPathId;
      _currentPathName = widget.initialPathTitle ?? 'Mi Camino';
      return;
    }

    // Cargar el path actual del servidor
    _loadCurrentPath();
  }

  void _initializeLives() {
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _loadLives();
  }

  Future<void> _loadLives() async {
    try {
      final token = ApiService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _currentLives = 3;
          });
        }
        return;
      }

      final status = await _livesService.getLivesStatus(token);

      if (mounted) {
        setState(() {
          _currentLives = status['lives'] ?? 3;
        });
      }
    } catch (e) {
      print('Error loading lives: $e');
      if (mounted) {
        setState(() {
          _currentLives = 3;
        });
      }
    }
  }

  Future<void> _loadCurrentPath() async {
    try {
      final profile = await ApiService.getProfile();
      final pathId = profile['currentPathId'];

      if (mounted) {
        setState(() {
          _currentPathId = pathId;
        });
      }

      // Cargar el nombre del camino si existe
      if (pathId != null && pathId.isNotEmpty) {
        try {
          final paths = await ApiService.getGoalPaths();
          final currentPath = paths.firstWhere(
            (p) => (p['_id'] ?? p['id']) == pathId,
            orElse: () => null,
          );

          if (currentPath != null && mounted) {
            setState(() {
              _currentPathName = currentPath['title'] ?? 'Mi Camino';
            });
          }
        } catch (e) {
          print('Error loading path name: $e');
        }
      }
    } catch (e) {
      print('Error loading current path: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;

    return AppScaffold(
      appBar: AppHeader(
        height: isCompact ? 54 : 64,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.grid_view_rounded,
            color: AppColors.textStrong,
          ),
          iconSize: isCompact ? 20 : 24,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
          constraints: BoxConstraints(
            minWidth: isCompact ? 36 : 48,
            minHeight: isCompact ? 36 : 48,
          ),
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          tooltip: 'Cambiar camino',
          onPressed: () async {
            final changed = await Navigator.of(context).pushNamed('/goals');
            if (changed == true) {
              await _loadCurrentPath();
            }
          },
        ),
        title: _buildHeaderTitle(isCompact),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isCompact ? 4 : AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_currentLives',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 12 : null,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppColors.textStrong,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.textStrong,
            ),
            iconSize: isCompact ? 20 : 24,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 36 : 48,
              minHeight: isCompact ? 36 : 48,
            ),
            visualDensity: isCompact
                ? VisualDensity.compact
                : VisualDensity.standard,
            tooltip: 'Ranking Mundial',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalLeaderboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: AppColors.textStrong),
            iconSize: isCompact ? 20 : 24,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 36 : 48,
              minHeight: isCompact ? 36 : 48,
            ),
            visualDensity: isCompact
                ? VisualDensity.compact
                : VisualDensity.standard,
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.lg),
        ],
      ),
      body:
          (_currentPathId == null || _currentPathId!.isEmpty) &&
              widget.initialPathId == null
          ? FollowGoalsScreen(
              isModal: false,
              onPathSelected: (pathId, pathTitle) {
                setState(() {
                  _currentPathId = pathId;
                  _currentPathName = pathTitle;
                });
              },
            )
          : PathProgressionScreen(
              pathId: _currentPathId ?? widget.initialPathId ?? '',
              pathTitle:
                  _currentPathName ?? widget.initialPathTitle ?? 'Mi Camino',
              showAppBar: false,
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CulinaryExperienceScreen(),
              ),
            );
            return;
          }
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GlobalLeaderboardScreen(),
              ),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderTitle(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentPathName ?? widget.initialPathTitle ?? 'Mi Camino',
          style: AppTypography.cardTitle.copyWith(
            fontSize: isCompact ? 15 : 17,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Nivel actual',
          style: AppTypography.badge.copyWith(
            fontSize: isCompact ? 11 : 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
