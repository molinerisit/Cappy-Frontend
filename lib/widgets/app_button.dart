import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonVariant { primary, secondary, danger }

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool value) {
    if (!mounted || _isDisabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow) = switch (widget.variant) {
      AppButtonVariant.primary   => (AppColors.primary, Colors.white, AppColors.primaryGlow),
      AppButtonVariant.secondary => (AppColors.surface, AppColors.textStrong, AppColors.shadow),
      AppButtonVariant.danger    => (AppColors.critical, Colors.white, AppColors.criticalSoft),
    };

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? AppMotionValues.buttonPressedScale : 1.0,
        duration: AppMotionDurations.quick,
        curve: AppMotionCurves.tap,
        child: AnimatedOpacity(
          opacity: _isDisabled ? 0.45 : 1.0,
          duration: AppMotionDurations.short,
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: widget.variant == AppButtonVariant.secondary
                  ? Border.all(color: AppColors.border, width: 1.5)
                  : null,
              boxShadow: _isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: shadow,
                        blurRadius: _pressed ? 4 : 12,
                        offset: Offset(0, _pressed ? 1 : 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
