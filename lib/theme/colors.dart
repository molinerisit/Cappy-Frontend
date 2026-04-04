import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary       = Color(0xFF22C55E); // Verde Cappy — CTAs, éxito
  static const primaryDark   = Color(0xFF16A34A); // Verde oscuro — hover, contraste
  static const primarySoft   = Color(0xFFDCFCE7); // Verde suave — fondos success
  static const primaryGlow   = Color(0x2A22C55E); // Verde glow — sombras

  // ── Gamificación ────────────────────────────────────────────────────────
  static const secondaryAccent = Color(0xFFFF6B35); // Naranja Cappy — recompensas, logros
  static const warningOrange   = Color(0xFFFB923C); // Naranja intermedio — acciones
  static const xpGold          = Color(0xFFF59E0B); // Dorado — XP, nivel, estrella
  static const xpGoldSoft      = Color(0xFFFEF3C7); // Dorado suave — fondos XP

  // ── Estados ─────────────────────────────────────────────────────────────
  static const success     = Color(0xFF22C55E);
  static const successDark = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const critical    = Color(0xFFEF4444); // Vidas, errores
  static const criticalSoft = Color(0xFFFEE2E2);

  // ── Neutros ─────────────────────────────────────────────────────────────
  static const background    = Color(0xFFF8FAFC);
  static const surface       = Color(0xFFFFFFFF);
  static const lockedSurface = Color(0xFFF1F5F9);
  static const border        = Color(0xFFE2E8F0);
  static const shadow        = Color(0x14000000);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const textStrong    = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled  = Color(0xFF94A3B8);
}
