import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../learning/screens/main_experience_screen.dart';
import 'widgets/game_header.dart';
import 'widgets/continue_card.dart';
import 'widgets/explore_card.dart';

/// Pantalla Home rediseñada con estilo moderno tipo Duolingo
/// Muestra progreso, opciones de continuar y explorar modos
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openMode(
    BuildContext context,
    String type,
    String title,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      "/paths",
      arguments: {"type": type, "title": title},
    );

    if (!context.mounted) return;

    if (result is Map && result['changed'] == true) {
      final selectedPathId = (result['pathId'] ?? '').toString();
      final selectedPathTitle = (result['pathTitle'] ?? 'Mi Camino').toString();

      if (selectedPathId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainExperienceScreen(
              initialPathId: selectedPathId,
              initialPathTitle: selectedPathTitle,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header compacto con nivel y XP
          const GameHeader(),

          // Contenido scrollable
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing24,
                    vertical: AppColors.spacing24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección: Continuar
                      const ContinueCard(),

                      const SizedBox(height: AppColors.spacing32),

                      // Título: Explorar
                      Text(
                        'Explorar',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: AppColors.spacing8),

                      Text(
                        'Elige tu camino de aprendizaje',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppColors.spacing20),

                      // Lista horizontal de opciones
                      SizedBox(
                        height: 200,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Card: Experiencia Culinaria
                            ExploreCard(
                              emoji: '🌍',
                              title: 'Experiencia Culinaria',
                              subtitle: 'Explora cocinas del mundo',
                              accentColor: AppColors.info,
                              onTap: () => _openMode(
                                context,
                                "country",
                                "Experiencia Culinaria",
                              ),
                            ),

                            const SizedBox(width: AppColors.spacing16),

                            // Card: Modo Objetivos
                            ExploreCard(
                              emoji: '🎯',
                              title: 'Mis Objetivos',
                              subtitle: 'Alcanza tus metas personales',
                              accentColor: AppColors.success,
                              onTap: () =>
                                  _openMode(context, "goal", "Objetivos"),
                            ),

                            const SizedBox(width: AppColors.spacing16),

                            // Card placeholder: Próximamente
                            ExploreCard(
                              emoji: '🔥',
                              title: 'Desafíos',
                              subtitle: 'Próximamente',
                              accentColor: AppColors.warning,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Próximamente disponible'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppColors.spacing32),

                      // Tips motivacionales
                      _buildMotivationalTip(),

                      const SizedBox(height: AppColors.spacing32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalTip() {
    return Container(
      padding: const EdgeInsets.all(AppColors.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.warningLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppColors.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo del día',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practica al menos 15 minutos diarios para mejores resultados',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
