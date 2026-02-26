import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';

class LivesWidget extends StatefulWidget {
  final int lives;
  final int maxLives;
  final DateTime? nextRefillAt;
  final VoidCallback? onLiveAnimationComplete;

  const LivesWidget({
    super.key,
    required this.lives,
    this.maxLives = 3,
    this.nextRefillAt,
    this.onLiveAnimationComplete,
  });

  @override
  State<LivesWidget> createState() => _LivesWidgetState();
}

class _LivesWidgetState extends State<LivesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _refillTimer;
  Duration? _timeUntilRefill;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    _startRefillTimer();
  }

  @override
  void didUpdateWidget(LivesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If lives changed, trigger animation
    if (oldWidget.lives != widget.lives && widget.lives < oldWidget.lives) {
      _triggerLossAnimation();
    }

    // Update refill timer if nextRefillAt changed
    if (oldWidget.nextRefillAt != widget.nextRefillAt) {
      _startRefillTimer();
    }
  }

  void _triggerLossAnimation() {
    _animationController.forward();
    widget.onLiveAnimationComplete?.call();
  }

  void _startRefillTimer() {
    _refillTimer?.cancel();

    if (widget.nextRefillAt == null || widget.lives >= widget.maxLives) {
      setState(() => _timeUntilRefill = null);
      return;
    }

    _refillTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = widget.nextRefillAt!.difference(now);

      if (difference.isNegative) {
        timer.cancel();
        setState(() => _timeUntilRefill = null);
      } else {
        setState(() => _timeUntilRefill = difference);
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refillTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            widget.maxLives,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ScaleTransition(
                scale: index == widget.lives - 1
                    ? _scaleAnimation
                    : AlwaysStoppedAnimation(1.0),
                child: OpacityTransition(
                  opacity: index == widget.lives - 1
                      ? _opacityAnimation
                      : AlwaysStoppedAnimation(1.0),
                  child: Icon(
                    index < widget.lives
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: index < widget.lives
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          if (_timeUntilRefill != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _formatDuration(_timeUntilRefill!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Helper widget for opacity animation
class OpacityTransition extends StatelessWidget {
  final Animation<double> opacity;
  final Widget child;

  const OpacityTransition({
    super.key,
    required this.opacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacity,
      builder: (context, child) =>
          Opacity(opacity: opacity.value, child: child),
      child: child,
    );
  }
}
