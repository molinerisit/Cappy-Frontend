import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_selection_provider.dart';
import 'culinary_experience_screen.dart';
import 'follow_goals_screen.dart';
import '../../../widgets/user_xp_badge.dart';
import 'country_hub_screen.dart';

class MainExperienceScreen extends StatefulWidget {
  const MainExperienceScreen({super.key});

  @override
  State<MainExperienceScreen> createState() => _MainExperienceScreenState();
}

class _MainExperienceScreenState extends State<MainExperienceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Verificar si hay selección del onboarding y navegar automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selectionProvider = context.read<OnboardingSelectionProvider>();
      await selectionProvider.loadSelection();

      if (selectionProvider.hasSelection()) {
        final mode = selectionProvider.mode;
        final selectionId = selectionProvider.selectionId;
        final selectionName = selectionProvider.selectionName;

        // Limpiar la selección después de detectarla
        await selectionProvider.clearSelection();

        if (mode == 'goals' && selectionId != null && mounted) {
          // Cambiar a la tab de Objetivos
          _tabController.animateTo(1);
        } else if (mode == 'countries' && selectionId != null && mounted) {
          // Navegar a CountryHubScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CountryHubScreen(
                countryId: selectionId,
                countryName: selectionName,
                countryIcon: '🌍',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cappy',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16.0), child: UserXPBadge()),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Experiencia Culinaria'),
            Tab(icon: Icon(Icons.flag), text: 'Mis Objetivos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [CulinaryExperienceScreen(), FollowGoalsScreen()],
      ),
    );
  }
}
