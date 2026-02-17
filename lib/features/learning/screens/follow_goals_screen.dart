import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'path_progression_screen.dart';

class FollowGoalsScreen extends StatefulWidget {
  const FollowGoalsScreen({super.key});

  @override
  State<FollowGoalsScreen> createState() => _FollowGoalsScreenState();
}

class _FollowGoalsScreenState extends State<FollowGoalsScreen> {
  late Future<List<dynamic>> futureGoalPaths;

  @override
  void initState() {
    super.initState();
    futureGoalPaths = ApiService.getGoalPaths();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: futureGoalPaths,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futureGoalPaths = ApiService.getGoalPaths();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay objetivos disponibles'));
          }

          final goalPaths = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goalPaths.length,
            itemBuilder: (context, index) {
              final goalPath = goalPaths[index];
              final pathId = goalPath['_id'] ?? goalPath['id'] ?? '';
              final title = goalPath['title'] ?? 'Objetivo';
              final description = goalPath['description'] ?? '';
              final icon = goalPath['icon'] ?? '🎯';
              final goalType = goalPath['goalType'] ?? '';
              final nodes = goalPath['nodes'] as List<dynamic>? ?? [];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PathProgressionScreen(
                        pathId: pathId,
                        pathTitle: title,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _getGradientForGoal(goalType),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 56)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${nodes.length} pasos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _GoalTypeBadge(goalType: goalType),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  LinearGradient _getGradientForGoal(String goalType) {
    switch (goalType) {
      case 'cooking_school':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.9),
            const Color(0xFFFFA500).withOpacity(0.9),
          ],
        );
      case 'lose_weight':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2196F3).withOpacity(0.9),
            const Color(0xFF1976D2).withOpacity(0.9),
          ],
        );
      case 'become_vegan':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.9),
            const Color(0xFF45a049).withOpacity(0.9),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.9),
            Colors.indigo.withOpacity(0.9),
          ],
        );
    }
  }
}

class _GoalTypeBadge extends StatelessWidget {
  final String goalType;

  const _GoalTypeBadge({required this.goalType});

  String _getLabel() {
    switch (goalType) {
      case 'cooking_school':
        return '🍳 Escuela de Cocina';
      case 'lose_weight':
        return '⚖️ Perder Peso';
      case 'become_vegan':
        return '🌱 Volverse Vegano';
      default:
        return goalType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
