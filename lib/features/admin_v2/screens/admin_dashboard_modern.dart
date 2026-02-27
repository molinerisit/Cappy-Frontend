import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../widgets/admin_buttons.dart';
import '../layout/components/admin_header.dart';
import '../../admin/admin_panel_screen.dart';
import '../../admin/dialogs/create_path_dialog.dart';

class AdminDashboardScreenModern extends StatefulWidget {
  final VoidCallback? onLibraryTap;
  final VoidCallback? onCountriesTap;

  const AdminDashboardScreenModern({
    super.key,
    this.onLibraryTap,
    this.onCountriesTap,
  });

  @override
  State<AdminDashboardScreenModern> createState() =>
      _AdminDashboardScreenModernState();
}

class _AdminDashboardScreenModernState
    extends State<AdminDashboardScreenModern> {
  List<dynamic> paths = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'all'; // all, goal, country_recipe

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      setState(() => isLoading = true);
      final fetchedPaths = await ApiService.adminGetAllLearningPaths();
      setState(() {
        paths = fetchedPaths;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando caminos: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  List<dynamic> get filteredPaths {
    var result = paths
        .where((path) => (path['type'] ?? '') != 'country_culture')
        .toList();

    // Filter by type
    if (selectedFilter != 'all') {
      result = result.where((path) => path['type'] == selectedFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (path) =>
                (path['title'] as String?)?.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    return result;
  }

  void _handleCreatePath() {
    showDialog(
      context: context,
      builder: (context) => CreatePathDialog(
        onPathCreated: () {
          _loadPaths();
        },
      ),
    );
  }

  Future<void> _navigateToPathContent(dynamic path) async {
    final pathId = path['_id'] ?? path['id'];
    final title = path['title'] ?? 'Sin título';

    String? countryId;
    final cId = path['countryId'] ?? path['country'];
    if (cId != null) {
      if (cId is String) {
        countryId = cId;
      } else if (cId is Map) {
        countryId = cId['\$oid'] ?? cId['_id']?.toString() ?? cId.toString();
      } else {
        countryId = cId.toString();
      }
    }

    final pathType = path['type'] ?? 'goal';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PathContentScreen(
          pathId: pathId,
          pathTitle: title,
          countryId: countryId,
          pathType: pathType,
        ),
      ),
    );

    // Reload when returning
    _loadPaths();
  }

  Future<void> _editPath(dynamic path) async {
    // TODO: Implementar diálogo de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edición de camino - próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _duplicatePath(dynamic path) async {
    // TODO: Implementar duplicación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicar camino - próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _archivePath(dynamic path) async {
    final pathId = path['_id'] ?? path['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar Camino'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
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

    if (confirmed == true && mounted) {
      try {
        await ApiService.adminDeleteLearningPath(pathId);
        _loadPaths();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camino archivado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al archivar: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  bool get _isMobile {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          AdminHeader(
            title: 'Caminos de Aprendizaje',
            subtitle: 'Gestiona y publica contenido educativo',
            onSearch: (query) {
              setState(() => searchQuery = query);
            },
            onLibraryTap: widget.onLibraryTap,
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(_isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Filters, Search, Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Filter tabs (compact)
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildFilterTabs(),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Search bar
                        Expanded(flex: 2, child: _buildSearchBar()),

                        const SizedBox(width: 12),

                        // Create button
                        Row(
                          children: [
                            if (widget.onCountriesTap != null) ...[
                              SizedBox(
                                width: 120,
                                height: 40,
                                child: SecondaryButton(
                                  label: 'Paises',
                                  onPressed: widget.onCountriesTap!,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            SizedBox(
                              width: 140,
                              height: 40,
                              child: PrimaryButton(
                                label: 'Nuevo Camino',
                                onPressed: _handleCreatePath,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Paths section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getFilterTitle(),
                                    style: TextStyle(
                                      fontSize: _isMobile ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${filteredPaths.length} camino${filteredPaths.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Loading state
                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange.shade600,
                                  ),
                                ),
                              ),
                            ),
                          )
                        // Empty state
                        else if (filteredPaths.isEmpty)
                          _buildEmptyState()
                        // Paths table or cards list
                        else if (_isMobile)
                          _buildPathsCardsList(filteredPaths)
                        else
                          _buildPathsTable(filteredPaths),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.symmetric(
        vertical: _isMobile ? 40 : 60,
        horizontal: _isMobile ? 20 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay caminos aún',
            style: TextStyle(
              fontSize: _isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer camino de aprendizaje para empezar',
            style: TextStyle(
              fontSize: _isMobile ? 13 : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            width: _isMobile ? double.infinity : 180,
            child: PrimaryButton(
              label: 'Crear Primer Camino',
              onPressed: _handleCreatePath,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterTitle() {
    switch (selectedFilter) {
      case 'goal':
        return 'Caminos de Objetivos';
      case 'country_recipe':
        return 'Recetas por País';
      default:
        return 'Todos los Caminos';
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (query) {
        setState(() => searchQuery = query);
      },
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.search_outlined, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 35),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade900,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filterButtons = [
      ('Todos', 'all'),
      ('Objetivos', 'goal'),
      ('Recetas', 'country_recipe'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < filterButtons.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _buildFilterButton(filterButtons[i].$1, filterButtons[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String filterValue) {
    final isSelected = selectedFilter == filterValue;
    return InkWell(
      onTap: () {
        setState(() {
          selectedFilter = filterValue;
        });
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPathsTable(List<dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 44,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Titulo')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Descripcion')),
            DataColumn(label: Text('Pais')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Modulos')),
            DataColumn(label: Text('Lecciones')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: data.map<DataRow>((path) {
            final title = path['title'] ?? 'Sin titulo';
            final description = path['description'] ?? 'Sin descripcion';
            final pathType = path['type'] ?? '';
            final country = path['country'] ?? 'Global';
            final goalType = path['goalType'] ?? '';
            final status = path['status'] ?? 'draft';
            final moduleCount = (path['modules']?.length ?? 0).toString();
            final lessonCount = (path['lessonCount'] ?? 0).toString();

            String typeLabel = '';
            switch (pathType) {
              case 'country_recipe':
                typeLabel = 'Receta';
                break;
              case 'goal':
                typeLabel = 'Objetivo';
                break;
              default:
                typeLabel = pathType;
            }

            String contextInfo = '';
            if (pathType == 'goal') {
              contextInfo = goalType;
            } else if (pathType.startsWith('country_')) {
              contextInfo = country.toString();
            } else {
              contextInfo = 'Global';
            }

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(pathType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 240,
                    child: Text(description, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(contextInfo)),
                DataCell(Text(status.toString())),
                DataCell(Text(moduleCount)),
                DataCell(Text(lessonCount)),
                DataCell(
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _navigateToPathContent(path),
                        child: const Text('Administrar'),
                      ),
                      TextButton(
                        onPressed: () => _editPath(path),
                        child: const Text('Editar'),
                      ),
                      TextButton(
                        onPressed: () => _archivePath(path),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                        ),
                        child: const Text('Archivar'),
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

  Widget _buildPathsCardsList(List<dynamic> data) {
    return Column(
      children: data.map<Widget>((path) {
        final title = path['title'] ?? 'Sin titulo';
        final description = path['description'] ?? 'Sin descripcion';
        final pathType = path['type'] ?? '';
        final country = path['country'] ?? 'Global';
        final goalType = path['goalType'] ?? '';
        final status = path['status'] ?? 'draft';

        String typeLabel = '';
        switch (pathType) {
          case 'country_recipe':
            typeLabel = 'Receta';
            break;
          case 'goal':
            typeLabel = 'Objetivo';
            break;
          default:
            typeLabel = pathType;
        }

        String contextInfo = '';
        if (pathType == 'goal') {
          contextInfo = goalType;
        } else if (pathType.startsWith('country_')) {
          contextInfo = country.toString();
        } else {
          contextInfo = 'Global';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(pathType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Meta info
                Row(
                  children: [
                    Text(
                      contextInfo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 32,
                          child: TextButton(
                            onPressed: () => _navigateToPathContent(path),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Administrar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 32,
                          child: TextButton(
                            onPressed: () => _editPath(path),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Editar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 32,
                          child: TextButton(
                            onPressed: () => _archivePath(path),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Archivar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'country_recipe':
        return Colors.green.shade600;
      case 'goal':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
