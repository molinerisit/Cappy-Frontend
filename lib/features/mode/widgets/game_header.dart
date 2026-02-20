import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/auth_provider.dart';

/// Header compacto estilo gamificado con avatar, nivel, XP y barra de progreso
class GameHeader extends StatefulWidget {
  const GameHeader({super.key});

  @override
  State<GameHeader> createState() => _GameHeaderState();
}

class _GameHeaderState extends State<GameHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final totalXP = authProvider.totalXP;
    final level = authProvider.level;

    // Calcular progreso en el nivel actual
    // Formula: XP necesario para siguiente nivel = nivel * 100
    final xpForCurrentLevel = (level - 1) * 100;
    final xpForNextLevel = level * 100;
    final xpInCurrentLevel = totalXP - xpForCurrentLevel;
    final xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel;
    final progressPercentage = (xpInCurrentLevel / xpNeededForNextLevel).clamp(
      0.0,
      1.0,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing20,
            vertical: AppColors.spacing16,
          ),
          child: Column(
            children: [
              // Primera fila: Avatar, Info, Botón perfil
              Row(
                children: [
                  // Avatar con nivel
                  _buildAvatar(level),

                  const SizedBox(width: AppColors.spacing12),

                  // Columna: Nombre y XP
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nivel $level',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$xpInCurrentLevel / $xpNeededForNextLevel XP',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón perfil
                  IconButton(
                    onPressed: () {
                      // TODO: Navegar a perfil
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppColors.spacing16),

              // Barra de progreso animada
              _buildProgressBar(progressPercentage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(int level) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: Text('🧑‍🍳', style: const TextStyle(fontSize: 28))),
    );
  }

  Widget _buildProgressBar(double progressPercentage) {
    return Column(
      children: [
        // Container de la barra
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value * progressPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
