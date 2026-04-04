import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? helperText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.helperText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _borderWidth;
  late Animation<Color?> _iconColor;
  bool _isFocused = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );

    _borderWidth = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );

    _iconColor = ColorTween(
      begin: const Color(0xFFAFC6D8),
      end: AppColors.primary,
    ).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _onFocusChange,
      child: AnimatedBuilder(
        animation: _focusController,
        builder: (context, child) {
          return TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText && !_showPassword,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textStrong,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              ),
              helperText: widget.helperText,
              helperStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: _iconColor.value,
                size: 20,
              ),
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () => setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: _isFocused
                  ? AppColors.primarySoft.withValues(alpha: 0.4)
                  : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: _borderWidth.value,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.critical,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.critical,
                  width: 2,
                ),
              ),
              errorStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.critical,
              ),
            ),
          );
        },
      ),
    );
  }
}
