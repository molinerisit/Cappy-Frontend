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
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.92,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.status != NodeStatus.locked && widget.onTap != null) {
      _controller.forward(from: 0);
    }
  }

  void _handleTapUp(TapUpDetails details) {}

  void _handleTapCancel() {}

  IconData _getCulinaryIcon() {
    switch (widget.nodeType) {
      case 'recipe':
        return Icons.restaurant_menu_rounded;
      case 'explanation':
        return Icons.menu_book_rounded;
      case 'tips':
        return Icons.lightbulb_rounded;
      case 'skill':
      case 'challenge':
        return Icons.emoji_events_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'technique':
        return Icons.cut_rounded;
      case 'cultural':
        return Icons.public_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  String _getNodeSubtitle() {
    switch (widget.nodeType) {
      case 'recipe':
        return 'Aprende paso a paso';
      case 'explanation':
        return 'Conceptos clave';
      case 'tips':
        return 'Mejora tu práctica';
      case 'quiz':
        return 'Evalúa tu avance';
      case 'technique':
        return 'Domina la técnica';
      case 'cultural':
        return 'Contexto gastronómico';
      case 'challenge':
        return 'Ponete a prueba';
      default:
        return 'Contenido de aprendizaje';
    }
  }

  Color _getNodeColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return const Color(0xFFF59E0B);
      case NodeStatus.active:
        return AppColors.primary;
      case NodeStatus.locked:
        return AppColors.textSecondary;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return const Color(0xFFFFF7DD);
      case NodeStatus.active:
        return const Color(0xFFECFDF3);
      case NodeStatus.locked:
        return AppColors.lockedSurface;
    }
  }

  Color _getBorderColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return const Color(0xFFF59E0B).withValues(alpha: 0.45);
      case NodeStatus.active:
        return AppColors.primary.withValues(alpha: 0.8);
      case NodeStatus.locked:
        return AppColors.border;
    }
  }

  double _getNodeSize() {
    switch (widget.status) {
      case NodeStatus.active:
        return 94;
      case NodeStatus.completed:
        return 84;
      case NodeStatus.locked:
        return 76;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.status != NodeStatus.locked && widget.onTap != null;
    final nodeSize = _getNodeSize();
    final subtitle = widget.status == NodeStatus.locked
        ? 'Próximamente'
        : _getNodeSubtitle();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.nodeWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getBackgroundColor(),
                  border: Border.all(color: _getBorderColor(), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.status == NodeStatus.active
                          ? AppColors.primaryGlow.withValues(alpha: 0.55)
                          : AppColors.shadow,
                      blurRadius: widget.status == NodeStatus.active ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? widget.onTap : null,
                    borderRadius: BorderRadius.circular(nodeSize),
                    child: Center(
                      child: widget.status == NodeStatus.completed
                          ? const Icon(
                              Icons.star_rounded,
                              size: 36,
                              color: Color(0xFFF59E0B),
                            )
                          : widget.status == NodeStatus.locked
                          ? Icon(
                              Icons.lock_rounded,
                              size: 30,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.85,
                              ),
                            )
                          : Icon(
                              _getCulinaryIcon(),
                              size: 34,
                              color: _getNodeColor(),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.status == NodeStatus.locked
                      ? AppColors.textSecondary
                      : AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef SkillNode = LessonNode;
