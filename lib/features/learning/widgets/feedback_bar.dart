import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import '../../../theme/typography.dart';

enum FeedbackType { correct, incorrect, neutral }

/// Barra flotante de feedback tipo Duolingo.
/// Aparece desde abajo con animación suave.
class FeedbackBar extends StatefulWidget {
  final FeedbackType type;
  final String message;
  final String ctaText;
  final VoidCallback onCTA;
  final bool show;

  const FeedbackBar({
    super.key,
    required this.type,
    required this.message,
    required this.ctaText,
    required this.onCTA,
    required this.show,
  });

  @override
  State<FeedbackBar> createState() => _FeedbackBarState();
}

class _FeedbackBarState extends State<FeedbackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AppMotionDurations.emphasis,
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AppMotionCurves.feedback,
          ),
        );

    if (widget.show) _slideController.forward();
  }

  @override
  void didUpdateWidget(FeedbackBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _slideController.forward();
    } else if (!widget.show && oldWidget.show) {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  _FeedbackTheme get _theme {
    switch (widget.type) {
      case FeedbackType.correct:
        return _FeedbackTheme(
          background: AppColors.successDark,
          surface: const Color(0xFF166534),
          ctaBackground: Colors.white,
          ctaForeground: AppColors.successDark,
          icon: Icons.check_circle_rounded,
        );
      case FeedbackType.incorrect:
        return _FeedbackTheme(
          background: const Color(0xFFDC2626),
          surface: const Color(0xFF991B1B),
          ctaBackground: Colors.white,
          ctaForeground: const Color(0xFFDC2626),
          icon: Icons.cancel_rounded,
        );
      case FeedbackType.neutral:
        return _FeedbackTheme(
          background: const Color(0xFF2563EB),
          surface: const Color(0xFF1D4ED8),
          ctaBackground: Colors.white,
          ctaForeground: const Color(0xFF2563EB),
          icon: Icons.lightbulb_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.background.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + Message
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.icon, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCTA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.ctaBackground,
                    foregroundColor: t.ctaForeground,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.ctaText,
                    style: AppTypography.button.copyWith(
                      color: t.ctaForeground,
                      fontSize: 15,
                    ),
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

class _FeedbackTheme {
  final Color background;
  final Color surface;
  final Color ctaBackground;
  final Color ctaForeground;
  final IconData icon;

  const _FeedbackTheme({
    required this.background,
    required this.surface,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.icon,
  });
}
