import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Sistema tipográfico unificado — Cappy
/// Familia: Poppins (consistente con el 95% del código existente)
/// Escala: display → heading → cardTitle → body → label → caption → badge
class AppTypography {
  // ── Display ─────────────────────────────────────────────────────────────
  /// Pantallas hero / welcome — máximo impacto
  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textStrong,
    height: 1.15,
    letterSpacing: -0.5,
  );

  // ── Headings ────────────────────────────────────────────────────────────
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle get heading3 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    height: 1.35,
  );

  // ── Card / Section titles ────────────────────────────────────────────────
  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle get cardTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    height: 1.4,
  );

  // ── Body ────────────────────────────────────────────────────────────────
  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textStrong,
    height: 1.5,
  );

  static TextStyle get bodyStrong => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    height: 1.5,
  );

  // ── Subtitle ────────────────────────────────────────────────────────────
  static TextStyle get subtitle => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  // ── Label ───────────────────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get labelStrong => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    height: 1.4,
  );

  // ── Caption ─────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static TextStyle get captionStrong => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Badge / Pill ─────────────────────────────────────────────────────────
  static TextStyle get badge => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ── Button ───────────────────────────────────────────────────────────────
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.1,
  );
}
