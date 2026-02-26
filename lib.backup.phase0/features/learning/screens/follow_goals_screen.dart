import 'package:flutter/material.dart';
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
  final bool isModal;
  final Function(String pathId, String pathTitle)? onPathSelected;

  const FollowGoalsScreen({
    super.key,
    this.isModal = false,
    this.onPathSelected,
  });

  @override
  State<FollowGoalsScreen> createState() => _FollowGoalsScreenState();
}

class _FollowGoalsScreenState extends State<FollowGoalsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> futureGoalPaths;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isChangingPath = false;

  @override
  void initState() {
    super.initState();
    futureGoalPaths = ApiService.getGoalPaths();

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectPath(String pathId, String pathTitle) async {
    setState(() => _isChangingPath = true);
    try {
      await ApiService.changeCurrentPath(pathId);
      if (!mounted) return;

      if (widget.isModal) {
        // Si se abrió como ruta modal, hacer pop(true)
        Navigator.of(context).pop(true);
      } else {
        // Si se abrió como body, llamar callback con los datos
        widget.onPathSelected?.call(pathId, pathTitle);
      }
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
      body: FutureBuilder<List<dynamic>>(
        future: futureGoalPaths,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF27AE60)),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final goalPaths = snapshot.data!;

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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: goalPaths.length,
                    itemBuilder: (context, index) {
                      final goalPath = goalPaths[index];
                      final pathId = goalPath['_id'] ?? goalPath['id'] ?? '';
                      final title = goalPath['title'] ?? 'Objetivo';
                      final description = goalPath['description'] ?? '';
                      final icon = goalPath['icon'] ?? '🎯';
                      final goalType = goalPath['goalType'] ?? '';
                      final nodes = goalPath['nodes'] as List<dynamic>? ?? [];
                      final accentColor = _getGoalColor(goalType);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _GoalCard(
                          pathId: pathId,
                          title: title,
                          description: description,
                          icon: icon,
                          goalType: goalType,
                          nodesCount: nodes.length,
                          accentColor: accentColor,
                          onSelected: _selectPath,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
                setState(() {
                  futureGoalPaths = ApiService.getGoalPaths();
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
              color: widget.accentColor.withOpacity(0.08),
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
