import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class CreateLessonScreen extends StatefulWidget {
  final String pathId;

  const CreateLessonScreen({super.key, required this.pathId});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController(text: "1");
  final _orderController = TextEditingController();
  final _xpRewardController = TextEditingController();

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final List<TextEditingController> _stepControllers = [];
  final List<TextEditingController> _tipControllers = [];
  final List<_IngredientFields> _ingredients = [];

  bool _isPremium = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _difficultyController.dispose();
    _orderController.dispose();
    _xpRewardController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();

    for (final controller in _stepControllers) {
      controller.dispose();
    }
    for (final controller in _tipControllers) {
      controller.dispose();
    }
    for (final ingredient in _ingredients) {
      ingredient.nameController.dispose();
      ingredient.quantityController.dispose();
    }

    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientFields());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      final removed = _ingredients.removeAt(index);
      removed.nameController.dispose();
      removed.quantityController.dispose();
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      final controller = _stepControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _addTip() {
    setState(() {
      _tipControllers.add(TextEditingController());
    });
  }

  void _removeTip(int index) {
    setState(() {
      final controller = _tipControllers.removeAt(index);
      controller.dispose();
    });
  }

  int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  Map<String, dynamic> _buildPayload() {
    final ingredients = _ingredients
        .map(
          (item) => {
            "name": item.nameController.text.trim(),
            "quantity": item.quantityController.text.trim(),
          },
        )
        .where((item) => item["name"]!.isNotEmpty)
        .toList();

    final steps = _stepControllers
        .map((controller) => controller.text.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    final tips = _tipControllers
        .map((controller) => controller.text.trim())
        .where((tip) => tip.isNotEmpty)
        .toList();

    final nutrition = <String, dynamic>{};
    final calories = _parseInt(_caloriesController.text);
    final protein = _parseInt(_proteinController.text);
    final carbs = _parseInt(_carbsController.text);
    final fat = _parseInt(_fatController.text);

    if (calories != null) nutrition["calories"] = calories;
    if (protein != null) nutrition["protein"] = protein;
    if (carbs != null) nutrition["carbs"] = carbs;
    if (fat != null) nutrition["fat"] = fat;

    return {
      "pathId": widget.pathId,
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "difficulty": _parseInt(_difficultyController.text) ?? 1,
      "order": _parseInt(_orderController.text) ?? 0,
      "xpReward": _parseInt(_xpRewardController.text) ?? 0,
      "ingredients": ingredients,
      "steps": steps,
      "nutrition": nutrition,
      "tips": tips,
      "isPremium": _isPremium,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = _buildPayload();
      await ApiService.createLesson(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Leccion creada con exito")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear leccion")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: "Datos principales",
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Titulo",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "El titulo es obligatorio";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Descripcion",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _difficultyController,
                              decoration: const InputDecoration(
                                labelText: "Dificultad",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _orderController,
                              decoration: const InputDecoration(
                                labelText: "Orden",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Orden obligatorio";
                                }
                                if (_parseInt(value) == null) {
                                  return "Orden invalido";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _xpRewardController,
                        decoration: const InputDecoration(
                          labelText: "XP reward",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "XP reward obligatorio";
                          }
                          final parsed = _parseInt(value);
                          if (parsed == null) {
                            return "XP reward invalido";
                          }
                          if (parsed < 10) {
                            return "XP reward minimo 10";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _isPremium,
                        onChanged: (value) {
                          setState(() {
                            _isPremium = value;
                          });
                        },
                        title: const Text("Premium"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Ingredientes",
                  child: Column(
                    children: [
                      if (_ingredients.isEmpty)
                        const Text(
                          "Agrega ingredientes para esta leccion",
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      ..._ingredients.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: item.nameController,
                                  decoration: const InputDecoration(
                                    labelText: "Ingrediente",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: item.quantityController,
                                  decoration: const InputDecoration(
                                    labelText: "Cantidad",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeIngredient(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Agregar ingrediente"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Pasos",
                  child: Column(
                    children: [
                      if (_stepControllers.isEmpty)
                        const Text(
                          "Agrega pasos para esta leccion",
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      ..._stepControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.green.shade600,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: "Paso",
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeStep(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Agregar paso"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Tips",
                  child: Column(
                    children: [
                      if (_tipControllers.isEmpty)
                        const Text(
                          "Agrega tips para esta leccion",
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      ..._tipControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: "Tip",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeTip(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addTip,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Agregar tip"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Nutricion",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _caloriesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Calorias",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _proteinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Proteina",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _carbsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Carbs",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _fatController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Fat",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? "Guardando..." : "Guardar leccion",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientFields {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
