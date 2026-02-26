import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/onboarding_selection_provider.dart';

/// Card destacada principal para continuar con la última experiencia
class ContinueCard extends StatefulWidget {
  const ContinueCard({super.key});

  @override
  State<ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<ContinueCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleContinue(BuildContext context) {
    final selectionProvider = context.read<OnboardingSelectionProvider>();
    final mode = selectionProvider.mode;
    final selectionId = selectionProvider.selectionId;

    if (mode != null && selectionId != null) {
      // Navegar según el modo guardado
      if (mode == 'goals') {
        Navigator.pushNamed(
          context,
          "/paths",
          arguments: {"type": "goal", "title": "Objetivos"},
        );
      } else if (mode == 'countries') {
        Navigator.pushNamed(
          context,
          "/paths",
          arguments: {"type": "country", "title": "Experiencia Culinaria"},
        );
      }
    } else {
      // Si no hay selección previa, mostrar mensaje o seleccionar modo por defecto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un modo para comenzar'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<OnboardingSelectionProvider>();
    final hasSelection = selectionProvider.hasSelection();
    final mode = selectionProvider.mode;

    // Determinar título y emoji según el modo
    String emoji = '🌟';
    String title = 'Comienza tu Aventura';
    String subtitle = 'Elige un modo para empezar a aprender';
    String buttonText = 'Elegir Modo';

    if (hasSelection) {
      if (mode == 'goals') {
        emoji = '🎯';
        title = 'Continúa con tus Objetivos';
        subtitle = 'Sigue progresando hacia tu meta';
        buttonText = 'Continuar';
      } else if (mode == 'countries') {
        emoji = '🌍';
        title = 'Continúa tu Viaje Culinario';
        subtitle = 'Descubre más recetas del mundo';
        buttonText = 'Continuar';
      }
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: hasSelection ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(AppColors.radiusXXLarge),
          boxShadow: AppColors.highlightShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleContinue(context),
            borderRadius: BorderRadius.circular(AppColors.radiusXXLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppColors.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji e indicador
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (hasSelection)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppColors.spacing12,
                            vertical: AppColors.spacing8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusPill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF27AE60),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'En progreso',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppColors.spacing20),

                  // Título
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing8),

                  // Subtítulo
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing24),

                  // Botón principal
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleContinue(context),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusLarge,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                buttonText,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
