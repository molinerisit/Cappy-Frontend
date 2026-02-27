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
  final _countryDescriptionController = TextEditingController();
  final _countryHeadlineController = TextEditingController();
  final _countrySummaryController = TextEditingController();
  final _countryHeroImageController = TextEditingController();
  final _countryIconicDishesController = TextEditingController();
  String _pathType = 'country_recipe'; // country_recipe, goal
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
    _countryDescriptionController.dispose();
    _countryHeadlineController.dispose();
    _countrySummaryController.dispose();
    _countryHeroImageController.dispose();
    _countryIconicDishesController.dispose();
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
          'description': _countryDescriptionController.text.trim().isEmpty
              ? null
              : _countryDescriptionController.text.trim(),
          'presentationHeadline': _countryHeadlineController.text.trim().isEmpty
              ? null
              : _countryHeadlineController.text.trim(),
          'presentationSummary': _countrySummaryController.text.trim().isEmpty
              ? null
              : _countrySummaryController.text.trim(),
          'heroImageUrl': _countryHeroImageController.text.trim().isEmpty
              ? null
              : _countryHeroImageController.text.trim(),
          'iconicDishes': _countryIconicDishesController.text.trim().isEmpty
              ? []
              : _countryIconicDishesController.text
                    .split(',')
                    .map((dish) => dish.trim())
                    .where((dish) => dish.isNotEmpty)
                    .toList(),
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

  Future<void> _openEditCountryDialog() async {
    if (_selectedCountryId == null) return;
    final country = _countries.cast<Map<String, dynamic>?>().firstWhere(
      (countryItem) =>
          (countryItem?['_id'] ?? countryItem?['id']).toString() ==
          _selectedCountryId,
      orElse: () => null,
    );

    if (country == null || !mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _EditCountryPresentationDialog(country: country),
    );

    if (updated == true) {
      await _loadCountries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('País actualizado correctamente')),
        );
      }
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
                  Column(
                    children: [
                      TextFormField(
                        controller: _newCountryController,
                        decoration: const InputDecoration(
                          labelText: "Nombre del Nuevo País",
                          hintText: "Ej: Argentina",
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? "Requerido" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countryDescriptionController,
                        decoration: const InputDecoration(
                          labelText: "Descripción corta",
                          hintText: "Cocina casera con identidad mediterránea",
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countryHeadlineController,
                        decoration: const InputDecoration(
                          labelText: "Headline de presentación",
                          hintText: "Sabores que cuentan historia",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countrySummaryController,
                        decoration: const InputDecoration(
                          labelText: "Resumen de presentación",
                          hintText:
                              "Descubre recetas, técnicas y platos icónicos",
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countryHeroImageController,
                        decoration: const InputDecoration(
                          labelText: "URL imagen principal",
                          hintText: "https://...",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _countryIconicDishesController,
                        decoration: const InputDecoration(
                          labelText: "Platos icónicos (coma separada)",
                          hintText: "Pasta, Risotto, Tiramisú",
                        ),
                      ),
                    ],
                  )
                else
                  _isLoadingCountries
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
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
                            if (_selectedCountryId != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _openEditCountryDialog,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar país seleccionado'),
                                ),
                              ),
                            ],
                          ],
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

class _EditCountryPresentationDialog extends StatefulWidget {
  final Map<String, dynamic> country;

  const _EditCountryPresentationDialog({required this.country});

  @override
  State<_EditCountryPresentationDialog> createState() =>
      _EditCountryPresentationDialogState();
}

class _EditCountryPresentationDialogState
    extends State<_EditCountryPresentationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _headlineController;
  late final TextEditingController _summaryController;
  late final TextEditingController _heroImageController;
  late final TextEditingController _iconicDishesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.country['name']?.toString() ?? '',
    );
    _iconController = TextEditingController(
      text: widget.country['icon']?.toString() ?? '🌍',
    );
    _descriptionController = TextEditingController(
      text: widget.country['description']?.toString() ?? '',
    );
    _headlineController = TextEditingController(
      text: widget.country['presentationHeadline']?.toString() ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.country['presentationSummary']?.toString() ?? '',
    );
    _heroImageController = TextEditingController(
      text: widget.country['heroImageUrl']?.toString() ?? '',
    );

    final dishesRaw = widget.country['iconicDishes'];
    final dishes = dishesRaw is List
        ? dishesRaw
              .map((dish) => dish.toString())
              .where((dish) => dish.isNotEmpty)
              .toList()
        : <String>[];
    _iconicDishesController = TextEditingController(text: dishes.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _headlineController.dispose();
    _summaryController.dispose();
    _heroImageController.dispose();
    _iconicDishesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final countryId = (widget.country['_id'] ?? widget.country['id'])
        .toString();
    setState(() => _isSaving = true);

    try {
      await ApiService.adminUpdateCountry(countryId, {
        'name': _nameController.text.trim(),
        'icon': _iconController.text.trim().isEmpty
            ? '🌍'
            : _iconController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'presentationHeadline': _headlineController.text.trim().isEmpty
            ? null
            : _headlineController.text.trim(),
        'presentationSummary': _summaryController.text.trim().isEmpty
            ? null
            : _summaryController.text.trim(),
        'heroImageUrl': _heroImageController.text.trim().isEmpty
            ? null
            : _heroImageController.text.trim(),
        'iconicDishes': _iconicDishesController.text.trim().isEmpty
            ? []
            : _iconicDishesController.text
                  .split(',')
                  .map((dish) => dish.trim())
                  .where((dish) => dish.isNotEmpty)
                  .toList(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardando país: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar País'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(labelText: 'Ícono (emoji)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción corta',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _headlineController,
                  decoration: const InputDecoration(
                    labelText: 'Headline de presentación',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Resumen de presentación',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _heroImageController,
                  decoration: const InputDecoration(
                    labelText: 'URL imagen principal',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _iconicDishesController,
                  decoration: const InputDecoration(
                    labelText: 'Platos icónicos (coma separada)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
