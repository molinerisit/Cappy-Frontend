import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

enum NodeStatus { completed, active, locked }

class LessonNode extends StatefulWidget {
  final String nodeId;
  final String title;
  final int xpReward;
  final NodeStatus status;
  final String nodeType;
  final VoidCallback? onTap;
  final int index;
  final double titleMaxWidth;
  final double nodeWidth;

  const LessonNode({
    super.key,
    required this.nodeId,
    required this.title,
    required this.xpReward,
    required this.status,
    required this.nodeType,
    this.onTap,
    required this.index,
    this.titleMaxWidth = 110,
    this.nodeWidth = 110,
  });

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.status != NodeStatus.locked && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.status != NodeStatus.locked) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.status != NodeStatus.locked) {
      _controller.reverse();
    }
  }

  IconData _getCulinaryIcon() {
    // Iconos culinarios únicos según el tipo
    switch (widget.nodeType) {
      case 'recipe':
        return Icons.restaurant_rounded; // Sartén/cocina
      case 'skill':
        return Icons.local_fire_department_rounded; // Fuego
      case 'quiz':
        return Icons.spa_rounded; // Especias
      case 'technique':
        return Icons.cut_rounded; // Cuchillo
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Color _getNodeColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return AppColors.success;
      case NodeStatus.active:
        return AppColors.primary;
      case NodeStatus.locked:
        return AppColors.textSecondary;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return AppColors.successSoft;
      case NodeStatus.active:
        return AppColors.surface;
      case NodeStatus.locked:
        return AppColors.lockedSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: SizedBox(
        width: widget.nodeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nodo circular principal con efecto glow
            ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Nodo principal
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBackgroundColor(),
                      border: Border.all(color: _getNodeColor(), width: 3.4),
                      boxShadow: widget.status == NodeStatus.active
                          ? const [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : widget.status == NodeStatus.completed
                          ? const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.status != NodeStatus.locked
                            ? widget.onTap
                            : null,
                        borderRadius: BorderRadius.circular(38),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: widget.status == NodeStatus.locked
                                  ? 0.45
                                  : 1,
                              child: Icon(
                                _getCulinaryIcon(),
                                size: 30,
                                color: _getNodeColor(),
                              ),
                            ),
                            if (widget.status == NodeStatus.completed)
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.surface,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Título del nodo
            SizedBox(
              width: widget.titleMaxWidth,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(
                  fontSize: 12,
                  color: widget.status == NodeStatus.locked
                      ? AppColors.textSecondary
                      : AppColors.textStrong,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Badge de XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Text(
                '+${widget.xpReward} XP',
                style: AppTypography.badge.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef SkillNode = LessonNode;
