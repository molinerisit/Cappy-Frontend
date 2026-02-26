import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'step_builder.dart';

// ==========================================
// EDIT NODE DIALOG V2: Editar nodo existente con tabs
// ==========================================
class EditNodeDialogV2 extends StatefulWidget {
  final dynamic node;
  final String pathId;
  final VoidCallback onSaved;

  const EditNodeDialogV2({
    super.key,
    required this.node,
    required this.pathId,
    required this.onSaved,
  });

  @override
  State<EditNodeDialogV2> createState() => _EditNodeDialogV2State();
}

class _EditNodeDialogV2State extends State<EditNodeDialogV2>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _prepTimeCtrl;
  late final TextEditingController _cookTimeCtrl;
  late final TextEditingController _servingsCtrl;

  late String _nodeType;
  late int _difficulty;
  bool _isLoading = false;

  late List<Map<String, dynamic>> _steps;
  late List<Map<String, dynamic>> _ingredients;
  late List<Map<String, dynamic>> _tools;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Pre-cargar datos del nodo
    _titleCtrl = TextEditingController(text: widget.node['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.node['description'] ?? '');
    _orderCtrl = TextEditingController(
      text: (widget.node['order'] ?? 1).toString(),
    );
    _xpCtrl = TextEditingController(
      text: (widget.node['xpReward'] ?? 50).toString(),
    );
    _prepTimeCtrl = TextEditingController(
      text: (widget.node['prepTime'] ?? 0).toString(),
    );
    _cookTimeCtrl = TextEditingController(
      text: (widget.node['cookTime'] ?? 0).toString(),
    );
    _servingsCtrl = TextEditingController(
      text: (widget.node['servings'] ?? 1).toString(),
    );

    _nodeType = widget.node['type'] ?? 'recipe';
    _difficulty = widget.node['difficulty'] ?? 2;

    // Convertir listas en formato seguro
    _steps = List<Map<String, dynamic>>.from(
      (widget.node['steps'] as List?)?.map((s) {
            if (s is Map) {
              return Map<String, dynamic>.from(s);
            }
            return {'title': 'Paso', 'instruction': '', 'type': 'text'};
          }) ??
          [],
    );

    _ingredients = List<Map<String, dynamic>>.from(
      (widget.node['ingredients'] as List?)?.map((i) {
            if (i is Map) {
              return Map<String, dynamic>.from(i);
            }
            return {'name': '', 'quantity': 1, 'unit': 'g', 'optional': false};
          }) ??
          [],
    );

    _tools = List<Map<String, dynamic>>.from(
      (widget.node['tools'] as List?)?.map((t) {
            if (t is Map) {
              return Map<String, dynamic>.from(t);
            }
            return {'name': '', 'optional': false};
          }) ??
          [],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _servingsCtrl.dispose();
    super.dispose();
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => AddStepDialogV2(
        stepType: 'text',
        onSave: (step) {
          setState(() => _steps.add(step));
        },
      ),
    );
  }

  void _editStep(int index) {
    showDialog(
      context: context,
      builder: (context) => AddStepDialogV2(
        stepType: 'text',
        existingStep: _steps[index],
        onSave: (updatedStep) {
          setState(() => _steps[index] = updatedStep);
        },
      ),
    );
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

  void _addTool() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Herramienta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre de herramienta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(
                  () =>
                      _tools.add({'name': controller.text, 'optional': false}),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
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
      final nodeId = widget.node['_id'] ?? widget.node['id'];
      await ApiService.adminUpdateLearningNode(nodeId, {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'type': _nodeType,
        'difficulty': _difficulty,
        'xpReward': int.tryParse(_xpCtrl.text) ?? 50,
        'order': int.tryParse(_orderCtrl.text) ?? 1,
        'prepTime': int.tryParse(_prepTimeCtrl.text) ?? 0,
        'cookTime': int.tryParse(_cookTimeCtrl.text) ?? 0,
        'servings': int.tryParse(_servingsCtrl.text) ?? 1,
        'steps': _steps,
        'ingredients': _ingredients,
        'tools': _tools,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nodo actualizado exitosamente')),
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
              color: Colors.blue.shade700,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Editar Nodo',
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
                Tab(icon: Icon(Icons.list), text: 'Pasos'),
                Tab(icon: Icon(Icons.shopping_cart), text: 'Ingredientes'),
                Tab(icon: Icon(Icons.build), text: 'Herramientas'),
              ],
            ),
            // TabView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicTab(),
                  _buildStepsTab(),
                  _buildIngredientsTab(),
                  _buildToolsTab(),
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
                    label: Text(
                      _isLoading ? 'Guardando...' : 'Guardar Cambios',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Título del Nodo',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _nodeType,
            items: const [
              DropdownMenuItem(value: 'recipe', child: Text('🍳 Receta')),
              DropdownMenuItem(value: 'skill', child: Text('💡 Habilidad')),
              DropdownMenuItem(value: 'quiz', child: Text('❓ Quiz')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _nodeType = value);
            },
            decoration: const InputDecoration(
              labelText: 'Tipo de Nodo',
              prefixIcon: Icon(Icons.category),
            ),
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
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _xpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP',
                    prefixIcon: Icon(Icons.star),
                  ),
                ),
              ),
            ],
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
                  decoration: const InputDecoration(
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
                label: const Text('Agregar Paso'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('📝 Sin pasos. Comienza agregando uno.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final hasCards = step['cards'] != null && step['cards'] is List;
                final cardCount = hasCards ? (step['cards'] as List).length : 0;
                final description = hasCards
                    ? '$cardCount tarjeta${cardCount != 1 ? 's' : ''} interactiva${cardCount != 1 ? 's' : ''}'
                    : (step['instruction'] ?? 'Sin descripción');

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
                    title: Text(
                      step['title'] ?? 'Sin título',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        if (hasCards)
                          const Icon(
                            Icons.style,
                            size: 14,
                            color: Colors.orange,
                          ),
                        if (hasCards) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editStep(index),
                          tooltip: 'Editar paso',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _steps.removeAt(index));
                          },
                          tooltip: 'Eliminar paso',
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('🥘 Sin ingredientes aún.')),
            )
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
                    subtitle: Text(
                      '${ing['quantity']} ${ing['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Herramientas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addTool,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tools.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('🔧 Sin herramientas.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.build, color: Colors.orange),
                    title: Text(tool['name'] ?? '?'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _tools.removeAt(index));
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
// ADD INGREDIENT DIALOG (reutilizable)
// ==========================================
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
            decoration: const InputDecoration(
              labelText: 'Ingrediente',
              hintText: 'ej. Cebolla',
            ),
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
                    DropdownMenuItem(value: 'unit', child: Text('unit')),
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
