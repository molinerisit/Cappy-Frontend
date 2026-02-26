import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estados posibles para una opción de respuesta
enum OptionState { idle, selected, correct, incorrect, disabled }

/// Card de opción de respuesta tipo Duolingo
/// - Completamente clickeable
/// - Animaciones inmediatas
/// - Estados visuales claros
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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
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
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case OptionState.idle:
        return widget.isSelected
            ? const Color(0xFFE8F5E9) // Verde muy claro
            : const Color(0xFFF8FAFC); // Gris muy claro
      case OptionState.selected:
        return const Color(0xFFE8F5E9);
      case OptionState.correct:
        return const Color(0xFFD4EDDA); // Verde más intenso
      case OptionState.incorrect:
        return const Color(0xFFF8D7DA); // Rojo muy claro
      case OptionState.disabled:
        return const Color(0xFFF3F4F6); // Gris
    }
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case OptionState.idle:
        return widget.isSelected
            ? const Color(0xFF27AE60) // Verde
            : const Color(0xFFD1D5DB); // Gris
      case OptionState.selected:
        return const Color(0xFF27AE60);
      case OptionState.correct:
        return const Color(0xFF20C997); // Verde brillante
      case OptionState.incorrect:
        return const Color(0xFFDC3545); // Rojo
      case OptionState.disabled:
        return const Color(0xFFD1D5DB);
    }
  }

  Color _getTextColor() {
    switch (widget.state) {
      case OptionState.disabled:
        return const Color(0xFF9CA3AF); // Gris
      default:
        return const Color(0xFF1F2937); // Negro
    }
  }

  IconData? _getIcon() {
    switch (widget.state) {
      case OptionState.correct:
        return Icons.check_circle;
      case OptionState.incorrect:
        return Icons.cancel;
      case OptionState.selected:
        return Icons.radio_button_checked;
      default:
        return null;
    }
  }

  Color? _getIconColor() {
    switch (widget.state) {
      case OptionState.correct:
        return const Color(0xFF27AE60);
      case OptionState.incorrect:
        return const Color(0xFFDC3545);
      case OptionState.selected:
        return const Color(0xFF27AE60);
      default:
        return null;
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border.all(
              color: _getBorderColor(),
              width: widget.isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de estado en la parte superior
              if (_getIcon() != null)
                AnimatedScale(
                  scale: widget.state != OptionState.idle ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 28),
                )
              else
              // Radio button para estado idle
              if (widget.state == OptionState.idle)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Texto de opción centrado
              Flexible(
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(),
                    height: 1.3,
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
