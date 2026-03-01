import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_library_rounded),
                activeIcon: Icon(
                  Icons.local_library_rounded,
                  color: AppColors.primary,
                ),
                label: 'Cultura',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_rounded),
                activeIcon: Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primary,
                ),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                ),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
