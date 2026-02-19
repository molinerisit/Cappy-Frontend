import 'package:flutter/material.dart';
import 'culinary_experience_screen.dart';
import 'follow_goals_screen.dart';
import '../../widgets/user_xp_badge.dart';

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
          '🍳 Cappy',
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
