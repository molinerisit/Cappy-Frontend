import 'package:flutter/material.dart';
import 'dart:async';
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
import '../../../widgets/lives_widget.dart';
import '../../../widgets/app_button.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../providers/auth_provider.dart';

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
  int _maxLives = 3;
  DateTime? _nextRefillAt;

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
            _maxLives = 3;
            _nextRefillAt = null;
          });
        }
        return;
      }

      final status = await _livesService.getLivesStatus(token);

      if (mounted) {
        setState(() {
          _currentLives = status['lives'] ?? 3;
          _maxLives = status['maxLives'] ?? 3;
          _nextRefillAt = status['nextRefillAt'] != null
              ? DateTime.parse(status['nextRefillAt'])
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading lives: $e');
      if (mounted) {
        setState(() {
          _currentLives = 3;
          _nextRefillAt = null;
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
          GestureDetector(
            onTap: _showLivesInfoDialog,
            child: Padding(
              padding: EdgeInsets.only(right: isCompact ? 2 : 4),
              child: LivesWidget(lives: _currentLives, maxLives: _maxLives),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showLivesInfoDialog() {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    bool showAdminActions = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isAtMaxLives = _currentLives >= _maxLives;

          Future<void> handleAdminRefill() async {
            try {
              await ApiService.refillLives();
              await _loadLives();
              if (!mounted) return;
              setDialogState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vidas recargadas (admin)'),
                  backgroundColor: Color(0xFF27AE60),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No se pudo recargar vidas: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          return Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tus Vidas',
                    style: AppTypography.title.copyWith(
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: isAdmin
                        ? () => setDialogState(() {
                            showAdminActions = !showAdminActions;
                          })
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_currentLives',
                                style: AppTypography.title.copyWith(
                                  color: Colors.red,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 32,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '/ $_maxLives',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (!isAtMaxLives && _nextRefillAt != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _NextLifeRefillCountdown(
                              nextRefillAt: _nextRefillAt!,
                            ),
                          ],
                          if (isAtMaxLives) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tus vidas están completas',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (isAdmin && showAdminActions) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: 'Recargar vidas (Admin)',
                              onPressed: handleAdminRefill,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Cerrar',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NextLifeRefillCountdown extends StatefulWidget {
  final DateTime nextRefillAt;

  const _NextLifeRefillCountdown({required this.nextRefillAt});

  @override
  State<_NextLifeRefillCountdown> createState() =>
      _NextLifeRefillCountdownState();
}

class _NextLifeRefillCountdownState extends State<_NextLifeRefillCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _NextLifeRefillCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextRefillAt != widget.nextRefillAt) {
      _tick();
    }
  }

  void _tick() {
    final diff = widget.nextRefillAt.difference(DateTime.now());
    final next = diff.isNegative ? Duration.zero : diff;
    if (next == Duration.zero) {
      _timer?.cancel();
    }
    if (mounted) {
      setState(() => _remaining = next);
    }
  }

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _remaining == Duration.zero
          ? 'Próxima vida disponible en breve'
          : 'Próxima vida en ${_format(_remaining)}',
      style: AppTypography.badge.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}
