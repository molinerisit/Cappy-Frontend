import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Profile stats
  int _completedLessonsCount = 0;
  int _streak = 0;
  Map<String, dynamic>? _analytics;
  bool _isLoadingProfile = true;
  String _nickname = 'Chef en Progreso';
  String _avatarIcon = '👨‍🍳';

  static const List<String> _avatarGallery = [
    '👨‍🍳',
    '👩‍🍳',
    '🧑‍🍳',
    '🍳',
    '🥘',
    '🍜',
    '🍕',
    '🥗',
    '🌮',
    '🧁',
    '🍣',
    '🥐',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    try {
      final profile = await ApiService.getProfile();
      Map<String, dynamic>? analytics;
      try {
        analytics = await ApiService.getProfileAnalytics();
      } catch (_) {
        analytics = null;
      }
      final authProvider = context.read<AuthProvider>();
      final nickname = (profile['username'] ?? _nickname).toString();
      final avatarIcon = (profile['avatarIcon'] ?? _avatarIcon).toString();

      await authProvider.syncProfileIdentity(
        username: nickname,
        avatarIcon: avatarIcon,
      );
      await authProvider.updateStreak((profile['streak'] ?? 0) as int);

      if (mounted) {
        setState(() {
          _completedLessonsCount =
              (profile['completedLessonsCount'] ?? 0) as int;
          _streak = (profile['streak'] ?? 0) as int;
          _analytics = analytics;
          _nickname = nickname;
          _avatarIcon = avatarIcon;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Quieres cerrar tu sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final displayedNickname = authProvider.username;
    final displayedAvatar = authProvider.avatarIcon;

    // Usar datos GLOBALES del usuario desde AuthProvider
    final level = authProvider.level;
    final totalXP = authProvider.totalXP;
    final xpInLevel = totalXP % 100;
    final xpForNextLevel = 100;
    final progressPercent = xpInLevel / xpForNextLevel;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Hero Section
                SliverToBoxAdapter(
                  child: _buildHeroSection(
                    authProvider,
                    level,
                    xpInLevel,
                    xpForNextLevel,
                    progressPercent,
                    totalXP,
                    displayedNickname,
                    displayedAvatar,
                  ),
                ),

                // Main Statistics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: _buildMainStats(authProvider),
                  ),
                ),

                // Learning Metrics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Métricas de aprendizaje',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLearningMetrics(
                          authProvider: authProvider,
                          totalXP: totalXP,
                          level: level,
                          xpInLevel: xpInLevel,
                        ),
                      ],
                    ),
                  ),
                ),

                // Achievements Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        Text(
                          'Logros',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAchievements(level),
                      ],
                    ),
                  ),
                ),

                // Actions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acciones',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActions(context, authProvider),
                      ],
                    ),
                  ),
                ),

                // Logout Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: _buildLogoutButton(context),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 12,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    AuthProvider authProvider,
    int level,
    int xpInLevel,
    int xpForNextLevel,
    double progressPercent,
    int totalXP,
    String displayedNickname,
    String displayedAvatar,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayedAvatar,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name/Role
            Text(
              displayedNickname,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    'Nivel $level',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // XP Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xpInLevel XP',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '$xpForNextLevel XP',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progressPercent * _progressAnimation.value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                          minHeight: 14,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(AuthProvider authProvider) {
    final currentStreak = authProvider.streak;

    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: _StatItem(
                  icon: '✅',
                  value: _isLoadingProfile
                      ? '...'
                      : _completedLessonsCount.toString(),
                  label: 'Lecciones',
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 900),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: _StatItem(
                  icon: '🔥',
                  value: _isLoadingProfile ? '...' : currentStreak.toString(),
                  label: 'Racha',
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: _StatItem(
                  icon: '⭐',
                  value: authProvider.totalXP.toString(),
                  label: 'XP Total',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(int level) {
    final currentStreak = context.watch<AuthProvider>().streak;

    final achievements = [
      _Achievement(
        emoji: '🌟',
        title: 'Primer Paso',
        unlocked: _completedLessonsCount > 0,
      ),
      _Achievement(emoji: '🔥', title: 'Racha', unlocked: currentStreak >= 3),
      _Achievement(
        emoji: '🎓',
        title: 'Aprendiz',
        unlocked: _completedLessonsCount >= 5,
      ),
      _Achievement(
        emoji: '👨‍🍳',
        title: 'Chef',
        unlocked: _completedLessonsCount >= 20,
      ),
      _Achievement(emoji: '💎', title: 'Experto', unlocked: level >= 10),
      _Achievement(emoji: '🌍', title: 'Viajero', unlocked: false),
    ];

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: achievements
            .asMap()
            .entries
            .map(
              (entry) => TweenAnimationBuilder(
                duration: Duration(milliseconds: 200 + (entry.key * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: _AchievementBadge(achievement: entry.value),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLearningMetrics({
    required AuthProvider authProvider,
    required int totalXP,
    required int level,
    required int xpInLevel,
  }) {
    final currentStreak = authProvider.streak;
    final analytics = _analytics;
    final nextLevelXp =
        ((analytics?['xpToNextLevel'] as num?)?.toInt() ?? (100 - xpInLevel))
            .clamp(0, 100);
    final weeklyGoalDays =
        ((analytics?['weeklyGoalDays'] as num?)?.toInt() ?? 7).clamp(1, 30);
    final weeklyGoalProgressDays =
        ((analytics?['weeklyGoalProgressDays'] as num?)?.toInt() ??
                currentStreak)
            .clamp(0, weeklyGoalDays);
    final weeklyConsistency =
        (analytics?['weeklyConsistency'] as num?)?.toDouble() ??
        (currentStreak / 7).clamp(0.0, 1.0);
    final avgXpPerLesson =
        (analytics?['avgXpPerLesson'] as num?)?.toInt() ??
        (_completedLessonsCount > 0
            ? (totalXP / _completedLessonsCount).round()
            : 0);
    final masteryScore =
        ((analytics?['masteryScore'] as num?)?.toInt() ??
                ((level * 8) + (currentStreak * 3)))
            .clamp(0, 100);
    final activityLast7Days =
        (analytics?['activityLast7Days'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        [];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.track_changes_rounded,
                title: 'Meta semanal',
                value: '$weeklyGoalProgressDays/$weeklyGoalDays días',
                subtitle: weeklyGoalProgressDays >= weeklyGoalDays
                    ? 'Meta alcanzada'
                    : 'Faltan ${weeklyGoalDays - weeklyGoalProgressDays} días',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.speed_rounded,
                title: 'Promedio XP',
                value: '$avgXpPerLesson XP',
                subtitle: _completedLessonsCount > 0
                    ? 'Por lección completada'
                    : 'Completá tu primera lección',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricProgressCard(
          icon: Icons.bolt_rounded,
          title: 'Progreso de nivel',
          valueLabel: '$xpInLevel/100 XP',
          helperLabel: nextLevelXp == 0
              ? 'Listo para subir'
              : 'Faltan $nextLevelXp XP para nivel ${level + 1}',
          progress: (xpInLevel / 100).clamp(0.0, 1.0),
          progressColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _MetricProgressCard(
          icon: Icons.insights_rounded,
          title: 'Consistencia semanal',
          valueLabel: '${(weeklyConsistency * 100).round()}%',
          helperLabel: activityLast7Days.isNotEmpty
              ? 'Basado en actividad real (7 días)'
              : 'Basado en tu racha actual',
          progress: weeklyConsistency,
          progressColor: AppColors.success,
        ),
        if (activityLast7Days.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WeeklyActivityCard(days: activityLast7Days),
        ],
        const SizedBox(height: 12),
        _MetricProgressCard(
          icon: Icons.workspace_premium_rounded,
          title: 'Índice de dominio',
          valueLabel: '$masteryScore/100',
          helperLabel: 'Nivel + racha + continuidad',
          progress: (masteryScore / 100).clamp(0.0, 1.0),
          progressColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.edit_rounded,
          label: 'Personalizar perfil',
          onTap: _openProfileCustomization,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.explore_rounded,
          label: 'Explorar Recetas',
          onTap: () => Navigator.pushNamed(context, "/main"),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.kitchen_rounded,
          label: 'Mi Despensa',
          onTap: () => Navigator.pushNamed(context, "/pantry"),
        ),
        if (authProvider.isAdmin) ...[
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Panel Administrativo',
            color: AppColors.warning,
            onTap: () => Navigator.pushNamed(context, "/admin"),
          ),
        ],
      ],
    );
  }

  Future<void> _openProfileCustomization() async {
    final nicknameController = TextEditingController(text: _nickname);
    String selectedAvatar = _avatarIcon;
    bool isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Personalizar perfil'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nicknameController,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Ingresa tu nombre visible',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige tu icono',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _avatarGallery.map((icon) {
                          final isSelected = selectedAvatar == icon;
                          return InkWell(
                            onTap: () => setDialogState(() {
                              selectedAvatar = icon;
                            }),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary.withOpacity(
                                          0.25,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nickname = nicknameController.text.trim();
                          if (nickname.length < 3 || nickname.length > 24) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'El nickname debe tener entre 3 y 24 caracteres',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            final updated = await ApiService.updateProfile(
                              username: nickname,
                              avatarIcon: selectedAvatar,
                            );

                            final updatedNickname =
                                (updated['username'] ?? nickname).toString();
                            final updatedAvatar =
                                (updated['avatarIcon'] ?? selectedAvatar)
                                    .toString();

                            await context
                                .read<AuthProvider>()
                                .syncProfileIdentity(
                                  username: updatedNickname,
                                  avatarIcon: updatedAvatar,
                                );

                            if (mounted) {
                              setState(() {
                                _nickname = updatedNickname;
                                _avatarIcon = updatedAvatar;
                              });
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nicknameController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _logout(context),
      icon: const Icon(Icons.logout_rounded),
      label: Text(
        'Cerrar Sesión',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ===== STAT ITEM COMPONENT =====
class _StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  Text(
                    this.value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricProgressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final String helperLabel;
  final double progress;
  final Color progressColor;

  const _MetricProgressCard({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.helperLabel,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: AppColors.textSecondary.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helperLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> days;

  const _WeeklyActivityCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxCompletions = days
        .map((day) => (day['completions'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (max, value) => value > max ? value : max);

    final scaleBase = maxCompletions > 0 ? maxCompletions : 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Actividad últimos 7 días',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final completions = (day['completions'] as num?)?.toInt() ?? 0;
              final active = day['active'] == true;
              final label = (day['label'] ?? '-').toString();
              final heightFactor = (completions / scaleBase).clamp(0.16, 1.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: 52 * heightFactor,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.success
                              : AppColors.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ===== ACHIEVEMENT DATA CLASS =====
class _Achievement {
  final String emoji;
  final String title;
  final bool unlocked;

  _Achievement({
    required this.emoji,
    required this.title,
    required this.unlocked,
  });
}

// ===== ACHIEVEMENT BADGE COMPONENT =====
class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: achievement.unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.success.withOpacity(0.25),
                  AppColors.success.withOpacity(0.08),
                ],
              )
            : null,
        color: achievement.unlocked
            ? null
            : AppColors.textSecondary.withOpacity(0.06),
        border: Border.all(
          color: achievement.unlocked
              ? AppColors.success.withOpacity(0.6)
              : AppColors.textSecondary.withOpacity(0.15),
          width: 2.5,
        ),
        boxShadow: achievement.unlocked
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.success.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: achievement.unlocked ? 1.0 : 0.25,
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: achievement.unlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withOpacity(0.5),
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== ACTION TILE COMPONENT =====
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tileColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tileColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
