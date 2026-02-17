import 'package:flutter/material.dart';
import '../../../core/api_service.dart';

class CreateNodeDialog extends StatefulWidget {
  final String? preSelectedPathId;
  final Function() onNodeCreated;

  const CreateNodeDialog({
    super.key,
    this.preSelectedPathId,
    required this.onNodeCreated,
  });

  @override
  State<CreateNodeDialog> createState() => _CreateNodeDialogState();
}

class _CreateNodeDialogState extends State<CreateNodeDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPathId;
  String _nodeTitle = '';
  String _nodeDescription = '';
  String _nodeType = 'recipe'; // recipe, skill, quiz
  String _difficulty = 'easy'; // easy, medium, hard
  int _xpReward = 50;
  int _order = 1;
  List<dynamic> _availablePaths = [];
  bool _isLoading = false;
  bool _isLoadingPaths = false;

  @override
  void initState() {
    super.initState();
    _selectedPathId = widget.preSelectedPathId;
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoadingPaths = true);
    try {
      _availablePaths = await ApiService.adminGetAllLearningPaths();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cargando caminos: $e")));
      }
    }
    setState(() => _isLoadingPaths = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPathId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecciona un camino")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'pathId': _selectedPathId,
        'title': _nodeTitle,
        'description': _nodeDescription,
        'type': _nodeType,
        'difficulty': _difficulty,
        'xpReward': _xpReward,
        'order': _order,
        'steps': [],
        'ingredients': [],
        'tools': [],
        'nutrition': {},
        'tips': [],
        'tags': [],
        'media': [],
      };

      await ApiService.adminCreateLearningNode(data);

      if (mounted) {
        Navigator.pop(context);
        widget.onNodeCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nodo creado exitosamente")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Crear Nuevo Nodo"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seleccionar Camino
              if (!_isLoadingPaths)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Camino"),
                  value: _selectedPathId,
                  items: _availablePaths
                      .map(
                        (p) => DropdownMenuItem(
                          value: (p['_id'] ?? p['id']).toString(),
                          child: Text(p['title'] ?? 'Sin título'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPathId = v),
                  validator: (v) => v == null ? "Requerido" : null,
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v?.isEmpty ?? true ? "Requerido" : null,
                onChanged: (v) => _nodeTitle = v,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                decoration: const InputDecoration(labelText: "Descripción"),
                maxLines: 2,
                onChanged: (v) => _nodeDescription = v,
              ),
              const SizedBox(height: 16),

              // Tipo de Nodo
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Tipo"),
                value: _nodeType,
                items: const [
                  DropdownMenuItem(value: 'recipe', child: Text("Receta")),
                  DropdownMenuItem(value: 'skill', child: Text("Habilidad")),
                  DropdownMenuItem(value: 'quiz', child: Text("Quiz")),
                ],
                onChanged: (v) => setState(() => _nodeType = v ?? 'recipe'),
              ),
              const SizedBox(height: 16),

              // Dificultad
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Dificultad"),
                value: _difficulty,
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text("Fácil")),
                  DropdownMenuItem(value: 'medium', child: Text("Medio")),
                  DropdownMenuItem(value: 'hard', child: Text("Difícil")),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'easy'),
              ),
              const SizedBox(height: 16),

              // XP Reward
              TextFormField(
                initialValue: _xpReward.toString(),
                decoration: const InputDecoration(labelText: "Recompensa XP"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return "Requerido";
                  if (int.tryParse(v!) == null) return "Número inválido";
                  return null;
                },
                onChanged: (v) => _xpReward = int.tryParse(v) ?? 50,
              ),
              const SizedBox(height: 16),

              // Orden
              TextFormField(
                initialValue: _order.toString(),
                decoration: const InputDecoration(labelText: "Orden"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return "Requerido";
                  if (int.tryParse(v!) == null) return "Número inválido";
                  return null;
                },
                onChanged: (v) => _order = int.tryParse(v) ?? 1,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Crear"),
        ),
      ],
    );
  }
}
