import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? textColor;

  const AppBadge({
    super.key,
    required this.text,
    this.background,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.badge.copyWith(
          color: textColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
