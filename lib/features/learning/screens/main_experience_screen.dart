import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_selection_provider.dart';
import '../../../core/lives_service.dart';
import '../../../core/api_service.dart';
import 'country_selection_screen.dart';
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
  const MainExperienceScreen({super.key});

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
    _bootstrapMainExperience();

    final selectionProvider = context.read<OnboardingSelectionProvider>();
    selectionProvider.loadSelection().then((_) {
      if (!mounted || !selectionProvider.hasSelection()) return;

      final mode = selectionProvider.mode;
      final selectionId = selectionProvider.selectionId;
      final selectionName = selectionProvider.selectionName;

      selectionProvider.clearSelection();

      if (mode == 'goals' && selectionId != null) {
        _tabController.animateTo(1);
      } else if (mode == 'countries' && selectionId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CountryHubScreen(
              countryId: selectionId,
              countryName: selectionName,
              countryIcon: '🌍',
            ),
          ),
        );
      }
    });
  }

  Future<void> _bootstrapMainExperience() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;

      final currentPathId = profile['currentPathId']?.toString();
      final currentPathTitle = profile['currentPathTitle']?.toString();

      if (currentPathId == null || currentPathId.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FollowGoalsScreen()),
        );
        return;
      }

      setState(() {
        _currentPathId = currentPathId;
        _currentPathName =
            (currentPathTitle != null && currentPathTitle.trim().isNotEmpty)
            ? currentPathTitle
            : 'Mi Camino';
      });
    } catch (e) {
      debugPrint('Error bootstrapping main experience: $e');
    }
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
      debugPrint('Error loading lives: $e');
      if (mounted) {
        setState(() {
          _currentLives = 3;
        });
      }
    }
  }

  Future<void> _loadCurrentPath() async {
    await _bootstrapMainExperience();
  }

  Future<void> _openPathSelector() async {
    final changed = await Navigator.of(context).pushNamed('/goals');
    if (changed == true) {
      await _loadCurrentPath();
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
        leading: const SizedBox.shrink(),
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
                const Icon(Icons.favorite_rounded, size: 16, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
      body: _currentPathId == null || _currentPathId!.isEmpty
          ? const FollowGoalsScreen()
          : PathProgressionScreen(
              pathId: _currentPathId!,
              pathTitle: _currentPathName ?? 'Mi Camino',
              showAppBar: false,
              onLessonExit: _loadLives,
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CountrySelectionScreen(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _openPathSelector,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 6 : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _currentPathName ?? 'Mi Camino',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: isCompact ? 15 : 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
