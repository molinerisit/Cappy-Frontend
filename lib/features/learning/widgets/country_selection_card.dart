import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountrySelectionCard extends StatefulWidget {
  final String countryName;
  final String countryIcon;
  final Color accentColor;
  final String heroTag;
  final VoidCallback onTap;
  final bool isLocked;
  final String? lockLabel;

  const CountrySelectionCard({
    super.key,
    required this.countryName,
    required this.countryIcon,
    required this.accentColor,
    required this.heroTag,
    required this.onTap,
    this.isLocked = false,
    this.lockLabel,
  });

  @override
  State<CountrySelectionCard> createState() => _CountrySelectionCardState();
}

class _CountrySelectionCardState extends State<CountrySelectionCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = widget.isLocked
        ? const Color(0xFF9CA3AF)
        : widget.accentColor;
    final shadowColor = widget.accentColor.withValues(
      alpha: _isPressed ? 0.12 : 0.18,
    );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: _isPressed ? 14 : 20,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
          border: Border.all(
            color: effectiveAccent.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            onTapDown: widget.isLocked ? null : (_) => _setPressed(true),
            onTapCancel: widget.isLocked ? null : () => _setPressed(false),
            onTapUp: widget.isLocked ? null : (_) => _setPressed(false),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight;
                final isCompact = cardHeight < 145;
                final horizontalPadding = isCompact ? 10.0 : 14.0;
                final verticalPadding = isCompact ? 10.0 : 14.0;
                final iconSize = (cardHeight * 0.34).clamp(46.0, 74.0);
                final emojiSize = (iconSize * 0.56).clamp(28.0, 42.0);
                final titleSize = isCompact ? 14.5 : 17.0;
                final ctaSize = isCompact ? 10.5 : 12.0;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: effectiveAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Hero(
                                tag: widget.heroTag,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.countryIcon,
                                    style: TextStyle(fontSize: emojiSize),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 14),
                          Text(
                            widget.countryName,
                            textAlign: TextAlign.center,
                            maxLines: isCompact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: isCompact ? 4 : 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.isLocked
                                        ? (widget.lockLabel ?? 'Bloqueado')
                                        : 'Explorar cocina',
                                    style: GoogleFonts.poppins(
                                      fontSize: ctaSize,
                                      fontWeight: FontWeight.w600,
                                      color: effectiveAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.isLocked
                                        ? Icons.lock_outline_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: isCompact ? 12 : 14,
                                    color: effectiveAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.isLocked)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
