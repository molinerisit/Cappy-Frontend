import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary       = Color(0xFF22C55E); // Verde Cappy
  static const primaryDark   = Color(0xFF16A34A);
  static const primaryLight  = Color(0xFF4ADE80);
  static const primarySoft   = Color(0xFFDCFCE7);
  static const primaryGlow   = Color(0x2A22C55E);

  // ── Gamificación ────────────────────────────────────────────────────────
  static const secondaryAccent = Color(0xFFFF6B35);
  static const warningOrange   = Color(0xFFFB923C);
  static const warning         = Color(0xFFFBBF24); // alias legacy
  static const warningLight    = Color(0xFFFDE68A);
  static const xpGold          = Color(0xFFF59E0B);
  static const xpGoldSoft      = Color(0xFFFEF3C7);

  // ── Estados ─────────────────────────────────────────────────────────────
  static const success      = Color(0xFF22C55E);
  static const successDark  = Color(0xFF16A34A);
  static const successSoft  = Color(0xFFDCFCE7);
  static const critical     = Color(0xFFEF4444);
  static const criticalSoft = Color(0xFFFEE2E2);
  static const criticalDark = Color(0xFFB91C1C);
  static const info         = Color(0xFF3B82F6);
  static const infoSoft     = Color(0xFFEFF6FF);

  // ── Fondos ──────────────────────────────────────────────────────────────
  static const background          = Color(0xFFF8FAFC);
  static const backgroundSecondary = Color(0xFFFFFFFF);
  static const surface             = Color(0xFFFFFFFF);
  static const lockedSurface       = Color(0xFFF1F5F9);
  static const surfaceElevated     = Color(0xFFFFFFFF);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const textStrong    = Color(0xFF0F172A);
  static const textPrimary   = Color(0xFF0F172A); // alias para compatibilidad
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary  = Color(0xFF94A3B8);
  static const textDisabled  = Color(0xFFCBD5E1);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ── Bordes ──────────────────────────────────────────────────────────────
  static const border       = Color(0xFFE2E8F0);
  static const borderActive = Color(0xFF22C55E);
  static const shadow       = Color(0x0F000000);

  // ── Sombras ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Alias de highlightShadow (compatibilidad con legacy app_colors)
  static List<BoxShadow> get highlightShadow => primaryShadow;

  // ── Spacing aliases (para compatibilidad con legacy app_colors) ──────────
  static const double spacing4  = 4.0;
  static const double spacing8  = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ── Radius aliases (para compatibilidad con legacy app_colors) ───────────
  static const double radiusSmall   = 8.0;
  static const double radiusMedium  = 12.0;
  static const double radiusLarge   = 16.0;
  static const double radiusXLarge  = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusPill    = 100.0;
}
