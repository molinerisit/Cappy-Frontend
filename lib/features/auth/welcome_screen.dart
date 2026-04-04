import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import 'login_screen.dart';
import 'onboarding_intro_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered animations
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _pill1Fade;
  late Animation<double> _pill2Fade;
  late Animation<double> _pill3Fade;
  late Animation<double> _ctaFade;
  late Animation<Offset> _ctaSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _logoFade = _interval(0.0, 0.3);
    _logoSlide = _slideInterval(0.0, 0.35);
    _headlineFade = _interval(0.15, 0.45);
    _headlineSlide = _slideInterval(0.15, 0.5);
    _pill1Fade = _interval(0.35, 0.6);
    _pill2Fade = _interval(0.45, 0.7);
    _pill3Fade = _interval(0.55, 0.8);
    _ctaFade = _interval(0.65, 0.95);
    _ctaSlide = _slideInterval(0.65, 1.0);

    _controller.forward();
  }

  Animation<double> _interval(double start, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: AppMotionCurves.entranceSoft),
        ),
      );

  Animation<Offset> _slideInterval(double start, double end) =>
      Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: AppMotionCurves.entrance),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Brand mark
              FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('🍳', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cappy',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Headline
              FadeTransition(
                opacity: _headlineFade,
                child: SlideTransition(
                  position: _headlineSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprende a cocinar\ncomo un pro.',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.12,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Lecciones diarias, recetas del mundo y\nun sistema de progresión que te engancha.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Feature pills — staggered
              FadeTransition(
                opacity: _pill1Fade,
                child: _FeaturePill(
                  icon: '🎮',
                  text: 'Aprende jugando — gana XP y sube de nivel',
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _pill2Fade,
                child: _FeaturePill(
                  icon: '🌍',
                  text: 'Recetas auténticas de todo el mundo',
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _pill3Fade,
                child: _FeaturePill(
                  icon: '⚡',
                  text: 'Lecciones de 5 minutos, a tu ritmo',
                ),
              ),

              const SizedBox(height: 48),

              // CTA buttons
              FadeTransition(
                opacity: _ctaFade,
                child: SlideTransition(
                  position: _ctaSlide,
                  child: Column(
                    children: [
                      _PrimaryWelcomeButton(
                        text: 'Empezar gratis',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnboardingIntroScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Ya tengo una cuenta',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String icon;
  final String text;

  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryWelcomeButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryWelcomeButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_PrimaryWelcomeButton> createState() => _PrimaryWelcomeButtonState();
}

class _PrimaryWelcomeButtonState extends State<_PrimaryWelcomeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppMotionDurations.micro,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: AppMotionCurves.tap),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
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
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
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
