import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

class PathProgressHeader extends StatelessWidget {
  final int currentLevel;
  final int completedCount;
  final int totalCount;
  final int streakDays;
  final int currentXp;
  final int nextLevelXp;

  const PathProgressHeader({
    super.key,
    required this.currentLevel,
    required this.completedCount,
    required this.totalCount,
    required this.streakDays,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = nextLevelXp > 0
        ? (currentXp / nextLevelXp).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.86),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nivel $currentLevel',
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '🔥 $streakDays',
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentXp / $nextLevelXp XP',
                        style: AppTypography.badge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: xpProgress),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFACC15),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$completedCount/$totalCount',
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
