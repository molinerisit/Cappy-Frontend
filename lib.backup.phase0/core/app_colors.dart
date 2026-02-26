import 'package:flutter/material.dart';

/// Colores centralizados de la aplicación
/// Estilo gamificado moderno tipo Duolingo
class AppColors {
  AppColors._();

  // ========== Colores Principales ==========

  /// Naranja primario - Energía y acción
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C5A);
  static const Color primaryDark = Color(0xFFE65A2B);

  /// Verde - Éxito y progreso
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFF58D68D);

  /// Azul - Exploración y conocimiento
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  /// Amarillo - Recompensas y logros
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFDE68A);

  // ========== Fondos ==========

  /// Fondo principal - Blanco cálido
  static const Color background = Color(0xFFFFFFFFF);

  /// Fondo secundario - Crema suave
  static const Color backgroundSecondary = Color(0xFFFAF7F2);

  /// Fondo terciario - Gris muy claro
  static const Color backgroundTertiary = Color(0xFFF8FAFC);

  // ========== Textos ==========

  /// Texto principal - Casi negro
  static const Color textPrimary = Color(0xFF1F2937);

  /// Texto secundario - Gris oscuro
  static const Color textSecondary = Color(0xFF6B7280);

  /// Texto terciario - Gris medio
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Texto disabled
  static const Color textDisabled = Color(0xFFD1D5DB);

  // ========== Bordes y Divisores ==========

  /// Borde suave
  static const Color border = Color(0xFFE5E7EB);

  /// Borde activo
  static const Color borderActive = Color(0xFFFF6B35);

  // ========== Superficies ==========

  /// Superficie elevada (cards)
  static const Color surfaceElevated = Colors.white;

  /// Overlay oscuro
  static Color overlayDark = Colors.black.withOpacity(0.5);

  // ========== Sombras ==========

  /// Sombra suave para cards
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Sombra para elementos destacados
  static List<BoxShadow> get highlightShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ========== Espaciado Consistente ==========

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ========== Border Radius ==========

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusPill = 100.0;
}
