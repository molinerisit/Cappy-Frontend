import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/typography.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppButton({super.key, required this.label, this.onPressed});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotionValues.pressedScale : 1.0,
        duration: AppMotionDurations.quick,
        curve: AppMotionCurves.tap,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.label,
            style: AppTypography.cardTitle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
