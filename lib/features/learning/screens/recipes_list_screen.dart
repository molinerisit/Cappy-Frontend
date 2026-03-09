import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../widgets/learning_empty_view.dart';
import '../widgets/learning_error_view.dart';

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
                  final prewarmUrls = <String>[];
                  final imageUrl = (recipe['imageUrl'] ?? recipe['image'] ?? '')
                      .toString()
                      .trim();
                  if (imageUrl.isNotEmpty) {
                    prewarmUrls.add(imageUrl);
                  }

                  Navigator.pushNamed(
                    context,
                    '/experience/recipe/$recipeId',
                    arguments: {
                      'recipeTitle': recipeTitle,
                      'prewarmUrls': prewarmUrls,
                    },
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

class _RecipeCard extends StatefulWidget {
  final dynamic recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  bool _isHovered = false;

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
    final title = widget.recipe['title'] ?? 'Sin título';
    final prepTime = widget.recipe['prepTime'] ?? 0;
    final difficulty = widget.recipe['difficulty'] ?? 2;
    final xpReward = widget.recipe['xpReward'] ?? 50;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Transform.scale(
        scale: _isHovered ? 1.02 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: _isHovered ? 8 : 2,
            color: Colors.white,
            shadowColor: _getDifficultyColor(difficulty).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _getDifficultyColor(difficulty).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getDifficultyColor(
                                  difficulty,
                                ).withValues(alpha: 0.15),
                                _getDifficultyColor(
                                  difficulty,
                                ).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getDifficultyColor(
                                difficulty,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getDifficultyLabel(difficulty),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getDifficultyColor(difficulty),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFCD34D).withValues(alpha: 0.2),
                                const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFFFCD34D,
                              ).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                '$xpReward XP',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Large emoji icon
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          difficulty,
                        ).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🍽️', style: TextStyle(fontSize: 40)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Time footer
                    if (prepTime > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$prepTime min',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
