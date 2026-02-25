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
  final _goalTypeController = TextEditingController();
  final _newCountryController = TextEditingController();
  String _pathType = 'country_recipe'; // country_recipe, country_culture, goal
  String? _selectedCountryId;
  String _goalType = '';
  String _title = '';
  String _description = '';
  bool _isPremium = false;
  String _icon = '🍳';
  List<dynamic> _countries = [];
  bool _isLoading = false;
  bool _isLoadingCountries = false;
  bool _showNewCountryField = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _goalTypeController.dispose();
    _newCountryController.dispose();
    super.dispose();
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
      String? countryId = _selectedCountryId;

      // Si se está creando un nuevo país
      if (_pathType.startsWith('country_') && _showNewCountryField) {
        if (_newCountryController.text.isEmpty) {
          throw Exception("Ingresa el nombre del nuevo país");
        }

        // Generar código del país desde el nombre
        final countryName = _newCountryController.text;
        final countryCode = countryName
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');

        // Crear el nuevo país
        final newCountry = await ApiService.adminCreateCountry({
          'name': countryName,
          'code': countryCode,
          'icon': _icon,
        });
        countryId = (newCountry['_id'] ?? newCountry['id']).toString();
      }

      // Crear el map de datos del camino
      final Map<String, dynamic> data = {
        'type': _pathType,
        'title': _title,
        'description': _description,
        'icon': _icon,
        'isPremium': _isPremium,
      };

      if (_pathType.startsWith('country_')) {
        if (countryId == null) {
          throw Exception("Selecciona un país o crea uno nuevo");
        }
        data['countryId'] = countryId;
      } else if (_pathType == 'goal') {
        final goalTypeText = _goalTypeController.text.trim();
        if (goalTypeText.isEmpty) {
          throw Exception("Ingresa el tipo de objetivo");
        }
        data['goalType'] = goalTypeText;
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
              if (_pathType.startsWith('country_')) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showNewCountryField
                            ? "Crear Nuevo País"
                            : "Seleccionar País Existente",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _showNewCountryField,
                      onChanged: (value) {
                        setState(() {
                          _showNewCountryField = value;
                          if (value) {
                            _selectedCountryId = null;
                          } else {
                            _newCountryController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_showNewCountryField)
                  TextFormField(
                    controller: _newCountryController,
                    decoration: const InputDecoration(
                      labelText: "Nombre del Nuevo País",
                      hintText: "Ej: Argentina",
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? "Requerido" : null,
                  )
                else
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
                          validator: (value) =>
                              value == null ? "Requerido" : null,
                        ),
              ],
              const SizedBox(height: 16),

              // Tipo de Objetivo (si es goal)
              if (_pathType == 'goal')
                TextFormField(
                  controller: _goalTypeController,
                  decoration: const InputDecoration(
                    labelText: "Tipo de Objetivo",
                    hintText:
                        "Ej: Hacerse Vegano, Perder Peso, Cocina Saludable",
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? "Requerido" : null,
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
