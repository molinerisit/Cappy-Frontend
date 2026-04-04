import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../screens/cooking_mode_screen.dart';
import '../widgets/learning_empty_view.dart';
import '../widgets/learning_error_view.dart';
import '../../cho/cho_assistant.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Map<String, dynamic>> futureRecipe;
  int currentStep = 0;
  List<bool> _ingredientChecked = [];

  void _initChecklist(int count) {
    if (_ingredientChecked.length != count) {
      _ingredientChecked = List.filled(count, false);
    }
  }

  bool get _allIngredientsChecked =>
      _ingredientChecked.isNotEmpty && _ingredientChecked.every((c) => c);

  List<Map<String, dynamic>> _normalizeSteps(Map<String, dynamic> recipe) {
    final rawSteps = recipe['steps'] ?? recipe['pasos'];

    if (rawSteps is List) {
      return rawSteps
          .map((step) {
            if (step is Map) {
              return Map<String, dynamic>.from(step);
            }
            if (step is String) {
              return {'instruction': step};
            }
            return <String, dynamic>{};
          })
          .where((step) => step.isNotEmpty)
          .toList();
    }

    if (rawSteps is Map) {
      return rawSteps.values
          .map((step) {
            if (step is Map) {
              return Map<String, dynamic>.from(step);
            }
            if (step is String) {
              return {'instruction': step};
            }
            return <String, dynamic>{};
          })
          .where((step) => step.isNotEmpty)
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _normalizeNodeSteps(dynamic node) {
    if (node is! Map) return [];
    final rawSteps = node['steps'];
    if (rawSteps is! List) return [];

    return rawSteps
        .map((step) {
          if (step is Map) {
            return Map<String, dynamic>.from(step);
          }
          return <String, dynamic>{};
        })
        .where((step) => step.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    futureRecipe = _loadRecipe();
  }

  Future<Map<String, dynamic>> _loadRecipe() async {
    final response = await ApiService.getRecipe(widget.recipeId);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: ChoAssistantButton(
        recipeId:        widget.recipeId,
        recipeName:      widget.recipeTitle,
        stepIndex:       currentStep,
        stepDescription: '',   // updated below once recipe loads
        elapsedSeconds:  0,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: const Color(0xFF475569),
        ),
        title: Text(
          widget.recipeTitle,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureRecipe,
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
                  futureRecipe = _loadRecipe();
                });
              },
            );
          }

          final response = snapshot.data!;
          final recipe = response['recipe'] ?? response;
          final node = response['node'];
          final nodeSteps = _normalizeNodeSteps(node);
          final steps = nodeSteps.isNotEmpty
              ? nodeSteps
              : _normalizeSteps(recipe);
          final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
          final tools = recipe['tools'] as List<dynamic>? ?? [];
          final description = recipe['description'] ?? '';
          final prepTime = recipe['prepTime'] ?? 0;
          final cookTime = recipe['cookTime'] ?? 0;
          final xpReward = recipe['xpReward'] ?? 50;

          _initChecklist(ingredients.length);

          if (steps.isEmpty) {
            return LearningEmptyView(
              emoji: '📝',
              title: 'Esta receta aún no tiene pasos',
              description:
                  'El contenido de esta receta se está preparando para publicarse.',
              onBack: () => Navigator.pop(context),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con info básica
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF22C55E).withValues(alpha: 0.1),
                        const Color(0xFF4ADE80).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (prepTime > 0) ...[
                            _InfoChip(
                              icon: Icons.schedule,
                              label: '$prepTime min',
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (cookTime > 0) ...[
                            _InfoChip(
                              icon: Icons.local_fire_department,
                              label: '$cookTime min',
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _InfoChip(
                            icon: Icons.star,
                            label: '$xpReward XP',
                            color: const Color(0xFF27AE60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ingredientes — checklist interactivo
                if (ingredients.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🥘 Ingredientes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_ingredientChecked.where((c) => c).length}/${ingredients.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Marcá los ingredientes que ya tenés listos',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        ...ingredients.asMap().entries.map((entry) {
                          final i = entry.key;
                          final ingredient = entry.value;
                          final name = ingredient['name'] ?? '';
                          final quantity = ingredient['quantity'] ?? '';
                          final unit = ingredient['unit'] ?? '';
                          final checked = i < _ingredientChecked.length && _ingredientChecked[i];
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (i < _ingredientChecked.length) {
                                _ingredientChecked[i] = !_ingredientChecked[i];
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: checked ? const Color(0xFFDCFCE7) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: checked ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                                  width: checked ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      key: ValueKey(checked),
                                      size: 22,
                                      color: checked ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$name${quantity.isNotEmpty ? " · $quantity" : ""}${unit.isNotEmpty ? " $unit" : ""}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: checked ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                        decoration: checked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (!_allIngredientsChecked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              'Marcá todos los ingredientes para poder comenzar',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Herramientas
                if (tools.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔪 Herramientas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tools.map<Widget>((tool) {
                            final name = tool['name'] ?? tool.toString();
                            return Chip(
                              label: Text(name),
                              backgroundColor: const Color(0xFFEFF6FF),
                              labelStyle: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Pasos - OCULTO (se usan en Modo Cocina)
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         '👨‍🍳 Pasos',
                //         style: TextStyle(
                //           fontSize: 20,
                //           fontWeight: FontWeight.bold,
                //           color: Color(0xFF000000),
                //         ),
                //       ),
                //       const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👨‍🍳 Pasos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final title = step['title'] ?? 'Paso ${index + 1}';
                        final instruction =
                            step['instruction'] ?? step['description'] ?? '';
                        final cardsRaw = step['cards'];
                        final cards = cardsRaw is List
                            ? cardsRaw
                                  .whereType<Map>()
                                  .map(
                                    (card) => Map<String, dynamic>.from(card),
                                  )
                                  .toList()
                            : <Map<String, dynamic>>[];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: const Color(0xFFFAFAFA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF27AE60),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (instruction.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    instruction,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                                if (cards.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ...cards.map((card) {
                                    final content = (card['content'] is Map)
                                        ? Map<String, dynamic>.from(
                                            card['content'],
                                          )
                                        : <String, dynamic>{};
                                    final cardTitle =
                                        content['title']?.toString() ?? '';
                                    final cardText =
                                        content['text']?.toString() ??
                                        content['description']?.toString() ??
                                        '';

                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (cardTitle.isNotEmpty)
                                            Text(
                                              cardTitle,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          if (cardText.isNotEmpty) ...[
                                            if (cardTitle.isNotEmpty)
                                              const SizedBox(height: 6),
                                            Text(
                                              cardText,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // FIN SECTION PASOS OCULTA

                // Botón Comenzar Modo Cocina
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (ingredients.isEmpty || _allIngredientsChecked) ? () {
                        final recipeData = snapshot.data!;
                        final countryData = recipeData['country'] ?? {};
                        final countryId = countryData['_id'] ?? '';
                        final countryName = countryData['name'] ?? '';
                        final countryFlag = countryData['flag'] ?? '';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CookingModeScreen(
                              steps: steps,
                              onStepComplete: (index) {
                                debugPrint('Paso $index completado');
                              },
                              recipeName: widget.recipeTitle,
                              countryId: countryId,
                              countryName: countryName,
                              countryFlag: countryFlag,
                              xpReward: xpReward,
                            ),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        ingredients.isEmpty || _allIngredientsChecked
                            ? '¡Listo! Comenzar a cocinar 🍳'
                            : 'Marcá los ingredientes primero',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

