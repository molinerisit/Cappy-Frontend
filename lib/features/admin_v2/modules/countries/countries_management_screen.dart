import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/api_service.dart';
import '../../layout/components/admin_header.dart';
import '../../widgets/admin_buttons.dart';

class CountriesManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CountriesManagementScreen({super.key, this.onBack});

  @override
  State<CountriesManagementScreen> createState() =>
      _CountriesManagementScreenState();
}

class _CountriesManagementScreenState extends State<CountriesManagementScreen> {
  List<dynamic> _countries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _premiumFilter = 'all';
  String _statusFilter = 'all';
  String _sortBy = 'order';
  String _sortDir = 'asc';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _pageSize = 20;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCountries({int? page}) async {
    final nextPage = page ?? _currentPage;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.adminGetCountriesPaginated(
        page: nextPage,
        limit: _pageSize,
        search: _searchQuery,
        premium: _premiumFilter,
        status: _statusFilter,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );
      final countries = response['data'] as List<dynamic>? ?? <dynamic>[];
      final pagination =
          response['pagination'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _currentPage = (pagination['page'] as num?)?.toInt() ?? nextPage;
        _totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
        _totalItems =
            (pagination['total'] as num?)?.toInt() ?? countries.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando paises: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredCountries {
    return _countries;
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    await _loadCountries(page: page);
  }

  Future<void> _createCountry() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CountryEditDialog(),
    );

    if (payload == null) return;

    try {
      final createdCountry = await ApiService.adminCreateCountry(payload);

      if (!mounted) return;

      final configureUnlockNow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('País creado'),
          content: const Text(
            '¿Quieres configurar ahora los grupos de desbloqueo de este país?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Después'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Configurar ahora'),
            ),
          ],
        ),
      );

      if (configureUnlockNow == true) {
        await _editCountry(
          createdCountry,
          autoOpenGroupSelector: true,
          showSuccessSnackbar: false,
        );
      }

      await _loadCountries();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pais creado exitosamente')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creando pais: $e')));
    }
  }

  Future<void> _editCountry(
    dynamic country, {
    bool autoOpenGroupSelector = false,
    bool showSuccessSnackbar = true,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CountryEditDialog(
        country: country,
        autoOpenGroupSelector: autoOpenGroupSelector,
      ),
    );

    if (payload == null) return;

    final countryId = (country['_id'] ?? country['id']).toString();

    try {
      await ApiService.adminUpdateCountry(countryId, payload);
      await _loadCountries();
      if (!mounted) return;
      if (showSuccessSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pais actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error actualizando pais: $e')));
    }
  }

  Future<void> _archiveCountry(dynamic country) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar Pais'),
        content: Text(
          'Se archivara ${country['name'] ?? 'este pais'}. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final countryId = (country['_id'] ?? country['id']).toString();

    try {
      await ApiService.adminDeleteCountry(countryId);
      await _loadCountries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pais archivado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error archivando pais: $e')));
    }
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 900;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          AdminHeader(
            title: 'Paises',
            subtitle: 'Gestion de presentacion y contenido por pais',
            onSearch: (query) {
              setState(() => _searchQuery = query);
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                _loadCountries(page: 1);
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(_isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.onBack != null)
                        SizedBox(
                          height: 40,
                          child: SecondaryButton(
                            label: 'Volver',
                            onPressed: widget.onBack!,
                          ),
                        ),
                      if (widget.onBack != null) const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: PrimaryButton(
                          label: 'Nuevo Pais',
                          onPressed: _createCountry,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_filteredCountries.length} en pagina · ${_totalItems} total',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _premiumFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filtro premium',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'premium',
                              child: Text('Solo premium'),
                            ),
                            DropdownMenuItem(
                              value: 'free',
                              child: Text('Solo free'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _premiumFilter = value ?? 'all');
                            _loadCountries(page: 1);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filtro estado',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Activos'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('Inactivos'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _statusFilter = value ?? 'all');
                            _loadCountries(page: 1);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Ordenar por',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'order',
                              child: Text('Orden'),
                            ),
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Nombre'),
                            ),
                            DropdownMenuItem(
                              value: 'code',
                              child: Text('Código'),
                            ),
                            DropdownMenuItem(
                              value: 'isPremium',
                              child: Text('Premium'),
                            ),
                            DropdownMenuItem(
                              value: 'isActive',
                              child: Text('Estado'),
                            ),
                            DropdownMenuItem(
                              value: 'updatedAt',
                              child: Text('Última actualización'),
                            ),
                            DropdownMenuItem(
                              value: 'createdAt',
                              child: Text('Fecha creación'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _sortBy = value ?? 'order');
                            _loadCountries(page: 1);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _sortDir,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'asc',
                              child: Text('Ascendente'),
                            ),
                            DropdownMenuItem(
                              value: 'desc',
                              child: Text('Descendente'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _sortDir = value ?? 'asc');
                            _loadCountries(page: 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCountries.isEmpty
                        ? _buildEmptyState()
                        : _isMobile
                        ? _buildCardList()
                        : _buildTable(),
                  ),
                  const SizedBox(height: 12),
                  _buildPaginationBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay paises disponibles para mostrar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.separated(
      itemCount: _filteredCountries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final country = _filteredCountries[index];
        final dishes = (country['iconicDishes'] is List)
            ? (country['iconicDishes'] as List)
            : const [];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text((country['icon'] ?? '🌍').toString()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (country['name'] ?? 'Sin nombre').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text((country['code'] ?? '').toString()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (country['presentationHeadline'] ??
                          country['description'] ??
                          '')
                      .toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (dishes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Platos: ${dishes.take(3).join(', ')}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _editCountry(country),
                      child: const Text('Editar'),
                    ),
                    TextButton(
                      onPressed: () => _archiveCountry(country),
                      child: const Text(
                        'Archivar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Pais')),
            DataColumn(label: Text('Codigo')),
            DataColumn(label: Text('Headline')),
            DataColumn(label: Text('Platos')),
            DataColumn(label: Text('Premium')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: _filteredCountries.map<DataRow>((country) {
            final dishes = (country['iconicDishes'] is List)
                ? (country['iconicDishes'] as List)
                : const [];
            return DataRow(
              cells: [
                DataCell(
                  Text('${country['icon'] ?? '🌍'} ${country['name'] ?? ''}'),
                ),
                DataCell(Text((country['code'] ?? '').toString())),
                DataCell(
                  SizedBox(
                    width: 260,
                    child: Text(
                      (country['presentationHeadline'] ??
                              country['description'] ??
                              '')
                          .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      dishes.take(3).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text((country['isPremium'] == true) ? 'Si' : 'No')),
                DataCell(
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _editCountry(country),
                        child: const Text('Editar'),
                      ),
                      TextButton(
                        onPressed: () => _archiveCountry(country),
                        child: const Text(
                          'Archivar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Pagina $_currentPage de $_totalPages',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            child: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            child: const Text('Siguiente'),
          ),
        ),
      ],
    );
  }
}

class _CountryEditDialog extends StatefulWidget {
  final dynamic country;
  final bool autoOpenGroupSelector;

  const _CountryEditDialog({this.country, this.autoOpenGroupSelector = false});

  @override
  State<_CountryEditDialog> createState() => _CountryEditDialogState();
}

class _CountryEditDialogState extends State<_CountryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _iconController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _headlineController;
  late final TextEditingController _summaryController;
  late final TextEditingController _heroImageController;
  late final TextEditingController _iconicDishesController;
  late final TextEditingController _unlockLevelController;
  final Set<String> _selectedRequiredGroupIds = <String>{};
  List<dynamic> _availableUnlockGroups = [];
  bool _isPremium = false;
  bool _unlockRequiresAnyGroup = false;
  bool _isLoadingUnlockGroups = false;
  bool _didAutoOpenGroupSelector = false;

  @override
  void initState() {
    super.initState();
    final country = widget.country;
    _nameController = TextEditingController(
      text: country?['name']?.toString() ?? '',
    );
    _codeController = TextEditingController(
      text: country?['code']?.toString() ?? '',
    );
    _iconController = TextEditingController(
      text: country?['icon']?.toString() ?? '🌍',
    );
    _descriptionController = TextEditingController(
      text: country?['description']?.toString() ?? '',
    );
    _headlineController = TextEditingController(
      text: country?['presentationHeadline']?.toString() ?? '',
    );
    _summaryController = TextEditingController(
      text: country?['presentationSummary']?.toString() ?? '',
    );
    _heroImageController = TextEditingController(
      text: country?['heroImageUrl']?.toString() ?? '',
    );
    final dishesRaw = country?['iconicDishes'];
    final dishes = dishesRaw is List
        ? dishesRaw
              .map((dish) => dish.toString())
              .where((dish) => dish.isNotEmpty)
              .toList()
        : <String>[];
    _iconicDishesController = TextEditingController(text: dishes.join(', '));
    _unlockLevelController = TextEditingController(
      text: (country?['unlockLevel'] ?? 1).toString(),
    );
    final requiredGroupIdsRaw = country?['requiredGroupIds'];
    final requiredGroupIds = requiredGroupIdsRaw is List
        ? requiredGroupIdsRaw
              .map((groupId) => groupId.toString())
              .where((groupId) => groupId.isNotEmpty)
              .toList()
        : <String>[];
    _selectedRequiredGroupIds.addAll(requiredGroupIds);
    _unlockRequiresAnyGroup = country?['unlockRequiresAnyGroup'] == true;
    _isPremium = country?['isPremium'] == true;
    _loadUnlockGroups();
  }

  Future<void> _loadUnlockGroups() async {
    setState(() => _isLoadingUnlockGroups = true);
    try {
      final countryId = (widget.country?['_id'] ?? widget.country?['id'])
          ?.toString();
      final groups = await ApiService.adminGetCountryUnlockGroups(
        countryId: countryId,
        pathType: 'country_recipe',
      );
      if (!mounted) return;
      setState(() => _availableUnlockGroups = groups);

      if (widget.autoOpenGroupSelector &&
          !_didAutoOpenGroupSelector &&
          widget.country != null) {
        _didAutoOpenGroupSelector = true;
        Future.microtask(() async {
          if (mounted) {
            await _openGroupSelector();
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _availableUnlockGroups = const []);
    } finally {
      if (mounted) setState(() => _isLoadingUnlockGroups = false);
    }
  }

  Future<void> _openGroupSelector() async {
    final tempSelected = Set<String>.from(_selectedRequiredGroupIds);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Seleccionar grupos requeridos'),
            content: SizedBox(
              width: 560,
              height: 380,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      widget.country == null
                          ? 'Mostrando grupos de todos los caminos de receta'
                          : 'Mostrando grupos del país seleccionado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoadingUnlockGroups
                        ? const Center(child: CircularProgressIndicator())
                        : _availableUnlockGroups.isEmpty
                        ? const Center(child: Text('No hay grupos disponibles'))
                        : ListView.separated(
                            itemCount: _availableUnlockGroups.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final group =
                                  _availableUnlockGroups[index] as Map;
                              final groupId = (group['id'] ?? '').toString();
                              final isSelected = tempSelected.contains(groupId);
                              final title = (group['title'] ?? 'Grupo')
                                  .toString();
                              final pathTitle =
                                  (group['pathTitle'] ?? 'Sin camino')
                                      .toString();

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      tempSelected.add(groupId);
                                    } else {
                                      tempSelected.remove(groupId);
                                    }
                                  });
                                },
                                title: Text(title),
                                subtitle: Text(pathTitle),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
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
                onPressed: () {
                  setState(() {
                    _selectedRequiredGroupIds
                      ..clear()
                      ..addAll(tempSelected);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _groupLabelById(String groupId) {
    for (final item in _availableUnlockGroups) {
      final group = item as Map;
      if ((group['id'] ?? '').toString() == groupId) {
        final title = (group['title'] ?? 'Grupo').toString();
        final pathTitle = (group['pathTitle'] ?? '').toString();
        return pathTitle.isEmpty ? title : '$title · $pathTitle';
      }
    }
    return groupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _headlineController.dispose();
    _summaryController.dispose();
    _heroImageController.dispose();
    _iconicDishesController.dispose();
    _unlockLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.country == null ? 'Nuevo Pais' : 'Editar Pais'),
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
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Codigo'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(labelText: 'Icono (emoji)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion corta',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _headlineController,
                  decoration: const InputDecoration(
                    labelText: 'Headline de presentacion',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Resumen de presentacion',
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
                    labelText: 'Platos iconicos (coma separada)',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _unlockLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nivel mínimo de desbloqueo',
                    hintText: 'Ej: 15',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedRequiredGroupIds.isEmpty
                            ? 'Sin grupos requeridos'
                            : '${_selectedRequiredGroupIds.length} grupo(s) seleccionados',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openGroupSelector,
                      icon: const Icon(Icons.rule_folder_outlined, size: 18),
                      label: const Text('Seleccionar grupos'),
                    ),
                  ],
                ),
                if (_selectedRequiredGroupIds.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedRequiredGroupIds
                        .map(
                          (groupId) => Chip(
                            label: Text(_groupLabelById(groupId)),
                            onDeleted: () {
                              setState(() {
                                _selectedRequiredGroupIds.remove(groupId);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _unlockRequiresAnyGroup,
                  onChanged: (value) =>
                      setState(() => _unlockRequiresAnyGroup = value ?? false),
                  title: const Text(
                    'Desbloquear con cualquier grupo requerido',
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPremium,
                  onChanged: (value) =>
                      setState(() => _isPremium = value ?? false),
                  title: const Text('Pais premium'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final payload = {
              'name': _nameController.text.trim(),
              'code': _codeController.text.trim().toLowerCase(),
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
              'unlockLevel':
                  int.tryParse(_unlockLevelController.text.trim()) ?? 1,
              'requiredGroupIds': _selectedRequiredGroupIds.toList(),
              'unlockRequiresAnyGroup': _unlockRequiresAnyGroup,
              'isPremium': _isPremium,
            };
            Navigator.pop(context, payload);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
