import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estados del feedback
enum FeedbackType { correct, incorrect, neutral }

/// Barra flotante de feedback tipo Duolingo
/// Aparece desde abajo con animación suave
/// Muestra feedback positivo/negativo y permite continuar
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    if (widget.show) {
      _slideController.forward();
    }
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

  Color _getBackgroundColor() {
    switch (widget.type) {
      case FeedbackType.correct:
        return const Color(0xFF27AE60);
      case FeedbackType.incorrect:
        return const Color(0xFFDC3545);
      case FeedbackType.neutral:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FeedbackType.correct:
        return Icons.check_circle;
      case FeedbackType.incorrect:
        return Icons.info;
      case FeedbackType.neutral:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getBackgroundColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono + Mensaje
            Row(
              children: [
                Icon(_getIcon(), color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onCTA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _getBackgroundColor(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.ctaText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
