import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import '../../../theme/typography.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotionDurations.micro,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppMotionValues.buttonPressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotionCurves.tap));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (!_isDisabled) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppMotionDurations.short,
          height: widget.height ?? 52,
          decoration: BoxDecoration(
            gradient: _isDisabled
                ? const LinearGradient(
                    colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)],
                  )
                : LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isDisabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.text,
                        style: AppTypography.button.copyWith(
                          color: _isDisabled
                              ? const Color(0xFF9CA3AF)
                              : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
