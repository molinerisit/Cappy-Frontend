import 'package:flutter/material.dart';
import '../../../core/api_service.dart';

class CreatePathDialog extends StatefulWidget {
  final Function() onPathCreated;

  const CreatePathDialog({super.key, required this.onPathCreated});

  @override
  State<CreatePathDialog> createState() => _CreatePathDialogState();
}

class _CreatePathDialogState extends State<CreatePathDialog> {
  final _formKey = GlobalKey<FormState>();
  String _pathType = 'country_recipe'; // country_recipe, country_culture, goal
  String? _selectedCountryId;
  String _goalType =
      'cooking_school'; // cooking_school, lose_weight, become_vegan
  String _title = '';
  String _description = '';
  bool _isPremium = false;
  String _icon = '🍳';
  List<dynamic> _countries = [];
  bool _isLoading = false;
  bool _isLoadingCountries = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      _countries = await ApiService.getAllCountries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cargando países: $e")));
      }
    }
    setState(() => _isLoadingCountries = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'type': _pathType,
        'title': _title,
        'description': _description,
        'icon': _icon,
        'isPremium': _isPremium,
      };

      if (_pathType.startsWith('country_')) {
        if (_selectedCountryId == null) {
          throw Exception("Selecciona un país");
        }
        data['countryId'] = _selectedCountryId!;
      } else if (_pathType == 'goal') {
        data['goalType'] = _goalType;
      }

      await ApiService.adminCreateLearningPath(data);

      if (mounted) {
        Navigator.pop(context);
        widget.onPathCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camino creado exitosamente")),
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
      title: const Text("Crear Nuevo Camino"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de Camino
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Tipo de Camino"),
                value: _pathType,
                items: const [
                  DropdownMenuItem(
                    value: 'country_recipe',
                    child: Text("Recetas de País"),
                  ),
                  DropdownMenuItem(
                    value: 'country_culture',
                    child: Text("Cultura de País"),
                  ),
                  DropdownMenuItem(value: 'goal', child: Text("Objetivo")),
                ],
                onChanged: (value) {
                  setState(() {
                    _pathType = value ?? 'country_recipe';
                    _selectedCountryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // País (si es country_*)
              if (_pathType.startsWith('country_'))
                _isLoadingCountries
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Selecciona País",
                        ),
                        value: _selectedCountryId,
                        items: _countries
                            .map(
                              (c) => DropdownMenuItem(
                                value: (c['_id'] ?? c['id']).toString(),
                                child: Text(c['name'] ?? 'Sin nombre'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCountryId = value);
                        },
                        validator: (_pathType.startsWith('country_'))
                            ? (value) => value == null ? "Requerido" : null
                            : null,
                      ),
              const SizedBox(height: 16),

              // Tipo de Objetivo (si es goal)
              if (_pathType == 'goal')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Tipo de Objetivo",
                  ),
                  value: _goalType,
                  items: const [
                    DropdownMenuItem(
                      value: 'cooking_school',
                      child: Text("Escuela de Cocina"),
                    ),
                    DropdownMenuItem(
                      value: 'lose_weight',
                      child: Text("Perder Peso"),
                    ),
                    DropdownMenuItem(
                      value: 'become_vegan',
                      child: Text("Hacerse Vegano"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _goalType = value ?? 'cooking_school');
                  },
                ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v?.isEmpty ?? true ? "Requerido" : null,
                onChanged: (v) => _title = v,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                decoration: const InputDecoration(labelText: "Descripción"),
                maxLines: 3,
                onChanged: (v) => _description = v,
              ),
              const SizedBox(height: 16),

              // Ícono
              TextFormField(
                initialValue: _icon,
                decoration: const InputDecoration(labelText: "Ícono (emoji)"),
                maxLength: 2,
                onChanged: (v) => _icon = v,
              ),
              const SizedBox(height: 16),

              // Premium
              CheckboxListTile(
                title: const Text("¿Es Premium?"),
                value: _isPremium,
                onChanged: (v) => setState(() => _isPremium = v ?? false),
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
