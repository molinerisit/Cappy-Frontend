import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import 'onboarding_mode_selection_screen.dart';

class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotionDurations.pageEntrance,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: AppMotionValues.introScaleStart,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingModeSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header — back + progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.textStrong,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OnboardingProgressBar(
                      totalSteps: 3,
                      currentStep: 1,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mascota animada
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/logo_cappy.png',
                            width: 110,
                            height: 110,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Texto
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _textSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              '¡Hola! Yo soy Cho',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textStrong,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Tu compañero en esta increíble aventura culinaria. Vamos a aprender juntos y convertirte en un chef extraordinario.',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                height: 1.65,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botón continuar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: _OnboardingContinueButton(onPressed: _handleNext),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de progreso visual para el onboarding
class _OnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const _OnboardingProgressBar({
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        totalSteps,
        (i) => Expanded(
          child: AnimatedContainer(
            duration: AppMotionDurations.medium,
            curve: Curves.easeOut,
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < currentStep ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de continuar del onboarding con micro-animación
class _OnboardingContinueButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _OnboardingContinueButton({required this.onPressed});

  @override
  State<_OnboardingContinueButton> createState() =>
      _OnboardingContinueButtonState();
}

class _OnboardingContinueButtonState extends State<_OnboardingContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: AppMotionDurations.micro,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _c, curve: AppMotionCurves.tap),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Continuar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
