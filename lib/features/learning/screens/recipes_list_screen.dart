import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../widgets/learning_empty_view.dart';
import '../widgets/learning_error_view.dart';
import 'recipe_detail_screen.dart';

class RecipesListScreen extends StatefulWidget {
  final String countryId;
  final String pathId;
  final String pathTitle;
  final String countryName;

  const RecipesListScreen({
    super.key,
    required this.countryId,
    required this.pathId,
    required this.pathTitle,
    required this.countryName,
  });

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  late Future<List<dynamic>> futureRecipes;

  @override
  void initState() {
    super.initState();
    futureRecipes = _loadRecipes();
  }

  Future<List<dynamic>> _loadRecipes() async {
    final response = await ApiService.getRecipesByCountry(widget.countryId);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: const Color(0xFF475569),
        ),
        title: Text(
          widget.pathTitle,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureRecipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF27AE60)),
            );
          } else if (snapshot.hasError) {
            return LearningErrorView(
              error: snapshot.error!,
              onBack: () => Navigator.pop(context),
              onRetry: () {
                setState(() {
                  futureRecipes = _loadRecipes();
                });
              },
            );
          }

          final recipes = snapshot.data ?? [];

          if (recipes.isEmpty) {
            return LearningEmptyView(
              emoji: '🍳',
              title: 'Aún no hay recetas',
              description:
                  'Pronto habrán nuevas experiencias culinarias disponibles',
              onBack: () => Navigator.pop(context),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final recipeId = recipe['_id'] ?? recipe['id'] ?? '';
              final recipeTitle = recipe['title'] ?? 'Receta';
              return _RecipeCard(
                recipe: recipe,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(
                        recipeId: recipeId,
                        recipeTitle: recipeTitle,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final dynamic recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  String _getDifficultyLabel(int? difficulty) {
    switch (difficulty) {
      case 1:
        return 'Muy Fácil';
      case 2:
        return 'Fácil';
      case 3:
        return 'Medio';
      default:
        return 'Fácil';
    }
  }

  Color _getDifficultyColor(int? difficulty) {
    switch (difficulty) {
      case 1:
        return const Color(0xFF22C55E);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = recipe['title'] ?? 'Sin título';
    final description = recipe['description'] ?? '';
    final prepTime = recipe['prepTime'] ?? 0;
    final difficulty = recipe['difficulty'] ?? 2;
    final xpReward = recipe['xpReward'] ?? 50;

    return Card(
      elevation: 0,
      color: const Color(0xFFFAFAFA),
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDifficultyLabel(difficulty),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getDifficultyColor(difficulty),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          '$xpReward XP',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('🍽️', style: TextStyle(fontSize: 40)),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              if (prepTime > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$prepTime min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
