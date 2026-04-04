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
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: const Color(0xFFCBD5E1),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home_rounded, size: 22, color: AppColors.primary),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_library_outlined, size: 22),
                activeIcon: Icon(Icons.local_library_rounded, size: 22, color: AppColors.primary),
                label: 'Cultura',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined, size: 22),
                activeIcon: Icon(Icons.emoji_events_rounded, size: 22, color: AppColors.primary),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 22, color: AppColors.primary),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
