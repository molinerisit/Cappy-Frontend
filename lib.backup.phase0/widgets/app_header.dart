import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Widget? leading;
  final List<Widget> actions;
  final double height;
  final bool centerTitle;

  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.height = 64,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: centerTitle,
      leading: leading,
      title: title,
      actions: actions,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadow,
    );
  }
}
