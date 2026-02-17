import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import 'step_builder.dart';

// ==========================================
// CREATE NODE DIALOG V2: Dialog mejorado con tabs
// ==========================================
class CreateNodeDialogV2 extends StatefulWidget {
  final String pathId;
  final VoidCallback onSaved;

  const CreateNodeDialogV2({
    super.key,
    required this.pathId,
    required this.onSaved,
  });

  @override
  State<CreateNodeDialogV2> createState() => _CreateNodeDialogV2State();
}

class _CreateNodeDialogV2State extends State<CreateNodeDialogV2>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');
  final _xpCtrl = TextEditingController(text: '50');
  final _prepTimeCtrl = TextEditingController(text: '0');
  final _cookTimeCtrl = TextEditingController(text: '0');
  final _servingsCtrl = TextEditingController(text: '1');

  String _nodeType = 'recipe';
  int _difficulty = 2;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _steps = [];
  final List<Map<String, dynamic>> _ingredients = [];
  final List<Map<String, dynamic>> _tools = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      await ApiService.adminCreateLearningNode({
        'pathId': widget.pathId,
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
        'nutrition': {},
        'tips': [],
        'tags': [],
        'media': null,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nodo creado exitosamente')),
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
              color: Colors.orange.shade700,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Nodo Completo',
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
                  // TAB 0: BÁSICO
                  _buildBasicTab(),
                  // TAB 1: PASOS
                  _buildStepsTab(),
                  // TAB 2: INGREDIENTES
                  _buildIngredientsTab(),
                  // TAB 3: HERRAMIENTAS
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
                    label: Text(_isLoading ? 'Guardando...' : 'Crear Nodo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
              hintText: 'ej. Cómo picar una cebolla',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Describe qué aprenderá el usuario',
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
                child: Text('📝 Sin pasos aún. Comienza agregando uno.'),
              ),
            )
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
                    title: Text(
                      step['title'] ?? 'Sin título',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
              child: Center(
                child: Text('🥘 Sin ingredientes aún. Agrega uno.'),
              ),
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
              child: Center(
                child: Text('🔧 Sin herramientas aún. Agrega una.'),
              ),
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
// ADD INGREDIENT DIALOG
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
