import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card de pregunta tipo Duolingo
/// Muestra la pregunta de forma clara y atractiva
/// Optimizado para lectura rápida
class QuestionCard extends StatefulWidget {
  final String question;
  final String? subtitle;
  final String? imageUrl;

  const QuestionCard({
    super.key,
    required this.question,
    this.subtitle,
    this.imageUrl,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen si existe
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFF3F4F6),
                child: Image.network(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Color(0xFFD1D5DB),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Subtítulo si existe (ej: "¿Cuál es la respuesta correcta?")
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Pregunta principal
          Text(
            widget.question,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
