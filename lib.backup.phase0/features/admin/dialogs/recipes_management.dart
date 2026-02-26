import 'package:flutter/material.dart';

// ==========================================
// RECIPES MANAGEMENT TAB
// ==========================================
class RecipesManagementTab extends StatefulWidget {
  const RecipesManagementTab({super.key});

  @override
  State<RecipesManagementTab> createState() => _RecipesManagementTabState();
}

class _RecipesManagementTabState extends State<RecipesManagementTab> {
  List<dynamic> recipes = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _difficultyFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => isLoading = true);
    try {
      // TODO: Reemplazar con llamada real al API
      // final response = await ApiService.adminGetAllRecipes();
      setState(() {
        recipes = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<dynamic> get _filteredRecipes {
    return recipes.where((recipe) {
      final matchesSearch =
          recipe['title']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
          false;
      final matchesDifficulty =
          _difficultyFilter == 'all' ||
          (recipe['difficulty'] ?? 2).toString() == _difficultyFilter;
      return matchesSearch && matchesDifficulty;
    }).toList();
  }

  void _showCreateRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRecipeDialog(onSaved: _loadRecipes),
    );
  }

  void _showEditRecipeDialog(dynamic recipe) {
    showDialog(
      context: context,
      builder: (context) =>
          EditRecipeDialog(recipe: recipe, onSaved: _loadRecipes),
    );
  }

  Future<void> _deleteRecipe(String recipeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Eliminación'),
        content: const Text(
          '¿Quieres eliminar esta receta? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // TODO: Reemplazar con llamada real al API
        // await ApiService.adminDeleteRecipe(recipeId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Receta eliminada')));
        _loadRecipes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🍳 Gestión de Recetas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateRecipeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Receta'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtros
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar recetas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _difficultyFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todas')),
                  DropdownMenuItem(value: '1', child: Text('🟢 Fácil')),
                  DropdownMenuItem(value: '2', child: Text('🟡 Medio')),
                  DropdownMenuItem(value: '3', child: Text('🔴 Difícil')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _difficultyFilter = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lista de recetas
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredRecipes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _searchQuery.isEmpty
                    ? '📭 No hay recetas. ¡Crea una nueva!'
                    : 'No se encontraron recetas que coincidan con tu búsqueda.',
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _filteredRecipes[index];
                return _RecipeCard(
                  recipe: recipe,
                  onEdit: () => _showEditRecipeDialog(recipe),
                  onDelete: () => _deleteRecipe(recipe['_id'] ?? recipe['id']),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==========================================
// RECIPE CARD WIDGET
// ==========================================
class _RecipeCard extends StatelessWidget {
  final dynamic recipe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecipeCard({
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
  });

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return '🟢 Fácil';
      case 2:
        return '🟡 Medio';
      case 3:
        return '🔴 Difícil';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.restaurant, color: Colors.orange),
        ),
        title: Text(
          recipe['title'] ?? 'Sin título',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe['description'] ?? 'Sin descripción',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _getDifficultyLabel(recipe['difficulty'] ?? 2),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                if (recipe['prepTime'] != null)
                  Text(
                    '⏱️ ${recipe['prepTime']} min prep',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (recipe['cookTime'] != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '🔥 ${recipe['cookTime']} min cook',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CREATE RECIPE DIALOG
// ==========================================
class CreateRecipeDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const CreateRecipeDialog({super.key, required this.onSaved});

  @override
  State<CreateRecipeDialog> createState() => _CreateRecipeDialogState();
}

class _CreateRecipeDialogState extends State<CreateRecipeDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController(text: '0');
  final _cookTimeCtrl = TextEditingController(text: '0');
  final _servingsCtrl = TextEditingController(text: '1');

  int _difficulty = 2;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _ingredients = [];
  final List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _servingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es requerido')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Reemplazar con llamada real al API
      // await ApiService.adminCreateRecipe({
      //   'title': _titleCtrl.text,
      //   'description': _descCtrl.text,
      //   'difficulty': _difficulty,
      //   'prepTime': int.tryParse(_prepTimeCtrl.text) ?? 0,
      //   'cookTime': int.tryParse(_cookTimeCtrl.text) ?? 0,
      //   'servings': int.tryParse(_servingsCtrl.text) ?? 1,
      //   'ingredients': _ingredients,
      //   'steps': _steps,
      // });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Receta creada exitosamente')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => AddIngredientDialog(
        onSave: (ingredient) {
          setState(() => _ingredients.add(ingredient));
        },
      ),
    );
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => AddStepDialog(
        onSave: (step) {
          setState(() => _steps.add(step));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.orange.shade700,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Receta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // TabBar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Básico'),
                Tab(icon: Icon(Icons.shopping_cart), text: 'Ingredientes'),
                Tab(icon: Icon(Icons.list), text: 'Pasos'),
              ],
            ),
            // TabView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicTab(),
                  _buildIngredientsTab(),
                  _buildStepsTab(),
                ],
              ),
            ),
            // Acciones
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Guardando...' : 'Crear Receta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Receta',
              hintText: 'ej. Arroz con Pollo',
              prefixIcon: Icon(Icons.restaurant),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Cuenta la historia de esta receta',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _difficulty,
            items: const [
              DropdownMenuItem(value: 1, child: Text('🟢 Fácil')),
              DropdownMenuItem(value: 2, child: Text('🟡 Medio')),
              DropdownMenuItem(value: 3, child: Text('🔴 Difícil')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _difficulty = value);
            },
            decoration: const InputDecoration(
              labelText: 'Dificultad',
              prefixIcon: Icon(Icons.trending_up),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prepTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prep Time',
                    suffixText: 'min',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cookTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cook Time',
                    suffixText: 'min',
                    prefixIcon: Icon(Icons.local_fire_department),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _servingsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingredientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ingredients.isEmpty)
            const Center(child: Text('🥘 Sin ingredientes aún.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ing = _ingredients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_grocery_store,
                      color: Colors.orange,
                    ),
                    title: Text(ing['name'] ?? '?'),
                    subtitle: Text('${ing['quantity']} ${ing['unit']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _ingredients.removeAt(index));
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStepsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pasos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_steps.isEmpty)
            const Center(child: Text('📝 Sin pasos aún.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(step['title'] ?? 'Sin título'),
                    subtitle: Text(
                      step['instruction'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _steps.removeAt(index));
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==========================================
// EDIT RECIPE DIALOG
// ==========================================
class EditRecipeDialog extends StatefulWidget {
  final dynamic recipe;
  final VoidCallback onSaved;

  const EditRecipeDialog({
    super.key,
    required this.recipe,
    required this.onSaved,
  });

  @override
  State<EditRecipeDialog> createState() => _EditRecipeDialogState();
}

class _EditRecipeDialogState extends State<EditRecipeDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _prepTimeCtrl;
  late final TextEditingController _cookTimeCtrl;
  late final TextEditingController _servingsCtrl;

  late int _difficulty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.recipe['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.recipe['description'] ?? '');
    _prepTimeCtrl = TextEditingController(
      text: (widget.recipe['prepTime'] ?? 0).toString(),
    );
    _cookTimeCtrl = TextEditingController(
      text: (widget.recipe['cookTime'] ?? 0).toString(),
    );
    _servingsCtrl = TextEditingController(
      text: (widget.recipe['servings'] ?? 1).toString(),
    );
    _difficulty = widget.recipe['difficulty'] ?? 2;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _servingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Reemplazar con llamada real al API
      // await ApiService.adminUpdateRecipe(widget.recipe['_id'], {
      //   'title': _titleCtrl.text,
      //   'description': _descCtrl.text,
      //   'difficulty': _difficulty,
      //   'prepTime': int.tryParse(_prepTimeCtrl.text) ?? 0,
      //   'cookTime': int.tryParse(_cookTimeCtrl.text) ?? 0,
      //   'servings': int.tryParse(_servingsCtrl.text) ?? 1,
      // });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Receta actualizada')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('✏️ Editar Receta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _difficulty,
              items: const [
                DropdownMenuItem(value: 1, child: Text('🟢 Fácil')),
                DropdownMenuItem(value: 2, child: Text('🟡 Medio')),
                DropdownMenuItem(value: 3, child: Text('🔴 Difícil')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _difficulty = value);
              },
              decoration: const InputDecoration(labelText: 'Dificultad'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prepTimeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prep',
                      suffixText: 'min',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cookTimeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cook',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ==========================================
// HELPER DIALOGS
// ==========================================
class AddStepDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddStepDialog({super.key, required this.onSave});

  @override
  State<AddStepDialog> createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<AddStepDialog> {
  final _titleCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📝 Agregar Paso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionCtrl,
            decoration: const InputDecoration(labelText: 'Instrucción'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isNotEmpty &&
                _instructionCtrl.text.isNotEmpty) {
              widget.onSave({
                'title': _titleCtrl.text,
                'instruction': _instructionCtrl.text,
                'type': 'text',
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class AddIngredientDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddIngredientDialog({super.key, required this.onSave});

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  String _unit = 'g';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🥘 Agregar Ingrediente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Ingrediente'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: 'g', child: Text('g')),
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'ml', child: Text('ml')),
                    DropdownMenuItem(value: 'l', child: Text('l')),
                    DropdownMenuItem(value: 'cup', child: Text('cup')),
                    DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                    DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _unit = value);
                  },
                  decoration: const InputDecoration(labelText: 'Unidad'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isNotEmpty && _quantityCtrl.text.isNotEmpty) {
              widget.onSave({
                'name': _nameCtrl.text,
                'quantity': double.tryParse(_quantityCtrl.text) ?? 1,
                'unit': _unit,
                'optional': false,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
