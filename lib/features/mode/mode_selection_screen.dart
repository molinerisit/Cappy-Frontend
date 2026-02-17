import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/mode_card.dart';

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openMode(BuildContext context, String type, String title) {
    Navigator.pushNamed(
      context,
      "/paths",
      arguments: {"type": type, "title": title},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header personalizado
                _buildHeader(),
                
                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de bienvenida
                        Text(
                          "Tu viaje culinario",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Subtítulo
                        Text(
                          "Selecciona cómo quieres aprender a cocinar",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Card: Modo Objetivos
                        ModeCard(
                          title: "Modo Objetivos",
                          subtitle: "Alcanza tus metas con recetas personalizadas",
                          emoji: "🎯",
                          gradientColors: const [
                            Color(0xFF6FCF97),
                            Color(0xFF27AE60),
                          ],
                          accentColor: const Color(0xFF27AE60),
                          badgeText: "4 caminos",
                          onTap: () => _openMode(context, "goal", "Objetivos"),
                        ),
                        const SizedBox(height: 24),

                        // Card: Experiencia Culinaria
                        ModeCard(
                          title: "Experiencia Culinaria",
                          subtitle: "Descubre la cocina de diferentes países",
                          emoji: "🌍",
                          gradientColors: const [
                            Color(0xFF93C5FD),
                            Color(0xFF3B82F6),
                          ],
                          accentColor: const Color(0xFF3B82F6),
                          badgeText: "Explora",
                          onTap: () => _openMode(
                            context,
                            "country",
                            "Experiencia Culinaria",
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mensaje motivacional
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "💡",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Aprende a tu ritmo",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Cada camino está diseñado para progresar paso a paso",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF6B7280),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Emoji
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "🍳",
              style: TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 12),
          
          // Título Cappy
          Text(
            "Cappy",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          
          // Botón de perfil/menú
          Material(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                // TODO: Implementar navegación a perfil
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF6B7280),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
