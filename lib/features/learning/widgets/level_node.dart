import 'package:flutter/material.dart';
import '../../../theme/typography.dart';
import '../models/level_model.dart';

class LevelNode extends StatefulWidget {
  final LevelNodeModel node;
  final VoidCallback? onTap;

  const LevelNode({super.key, required this.node, this.onTap});

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode> {
  bool _pressed = false;

  bool get _isLocked => widget.node.status == LevelStatus.locked;

  IconData _iconForType(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'tips':
        return Icons.lightbulb_rounded;
      case 'technique':
        return Icons.cut_rounded;
      case 'cultural':
        return Icons.public_rounded;
      case 'challenge':
        return Icons.emoji_events_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(widget.node.status);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _isLocked ? null : widget.onTap,
      child: SizedBox(
        width: 94,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              scale: _pressed ? 0.90 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLocked
                      ? const Color(0xFFF3F4F6)
                      : color.withValues(alpha: 0.14),
                  border: Border.all(color: color, width: 2.2),
                  boxShadow: widget.node.status == LevelStatus.inProgress
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _iconForType(widget.node.type),
                      size: 25,
                      color: color,
                    ),
                    if (widget.node.status == LevelStatus.completed)
                      Positioned(
                        right: 3,
                        bottom: 3,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    if (_isLocked)
                      const Positioned(
                        right: 2,
                        bottom: 2,
                        child: Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF6B7280),
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.badge.copyWith(
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: _isLocked
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
