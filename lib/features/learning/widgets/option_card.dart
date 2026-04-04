import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio_feedback_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';

enum OptionState { idle, selected, correct, incorrect, disabled }

/// Card de opción de respuesta tipo Duolingo.
/// Layout horizontal: indicador | texto
/// - Animación de press instantánea
/// - Estados visuales claros con color + ícono
class OptionCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final OptionState state;
  final VoidCallback? onTap;
  final bool isEnabled;

  const OptionCard({
    super.key,
    required this.text,
    this.isSelected = false,
    this.state = OptionState.idle,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppMotionDurations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppMotionValues.pressedScale,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: AppMotionCurves.tap),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (widget.isEnabled && widget.onTap != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp() {
    _scaleController.reverse();
    if (widget.isEnabled && widget.onTap != null) {
      AudioFeedbackService().playAddObject();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() => _scaleController.reverse();

  // ── Temas por estado ─────────────────────────────────────────────────────

  Color get _background {
    if (widget.isSelected && widget.state == OptionState.idle) {
      return AppColors.primarySoft;
    }
    switch (widget.state) {
      case OptionState.idle:
        return AppColors.surface;
      case OptionState.selected:
        return AppColors.primarySoft;
      case OptionState.correct:
        return const Color(0xFFDCFCE7);
      case OptionState.incorrect:
        return const Color(0xFFFEE2E2);
      case OptionState.disabled:
        return const Color(0xFFF8FAFC);
    }
  }

  Color get _borderColor {
    if (widget.isSelected && widget.state == OptionState.idle) {
      return AppColors.primary;
    }
    switch (widget.state) {
      case OptionState.idle:
        return AppColors.border;
      case OptionState.selected:
        return AppColors.primary;
      case OptionState.correct:
        return AppColors.successDark;
      case OptionState.incorrect:
        return AppColors.critical;
      case OptionState.disabled:
        return AppColors.border;
    }
  }

  double get _borderWidth {
    switch (widget.state) {
      case OptionState.correct:
      case OptionState.incorrect:
      case OptionState.selected:
        return 2.0;
      default:
        return widget.isSelected ? 2.0 : 1.5;
    }
  }

  Color get _textColor {
    if (widget.state == OptionState.disabled) return AppColors.textDisabled;
    return AppColors.textStrong;
  }

  Widget _buildLeadingIndicator() {
    switch (widget.state) {
      case OptionState.correct:
        return Icon(
          Icons.check_circle_rounded,
          color: AppColors.successDark,
          size: 22,
        );
      case OptionState.incorrect:
        return Icon(
          Icons.cancel_rounded,
          color: AppColors.critical,
          size: 22,
        );
      case OptionState.selected:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
      default:
        // idle / disabled — circle indicator
        return AnimatedContainer(
          duration: AppMotionDurations.short,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSelected ? AppColors.primarySoft : Colors.transparent,
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 2.0 : 1.5,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: AppMotionDurations.short,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _background,
            border: Border.all(
              color: _borderColor,
              width: _borderWidth,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotionDurations.short,
                switchInCurve: AppMotionCurves.emphasis,
                child: KeyedSubtree(
                  key: ValueKey(widget.state),
                  child: _buildLeadingIndicator(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
