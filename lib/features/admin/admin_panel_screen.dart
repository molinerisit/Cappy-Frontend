import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'dialogs/create_node_dialog_v2.dart';
import 'dialogs/edit_node_dialog.dart';
import 'dialogs/recipes_management.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔑 Panel Administrativo Cappy'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📚 Caminos', icon: Icon(Icons.school)),
            Tab(text: '🍳 Recetas', icon: Icon(Icons.restaurant)),
            Tab(text: '🌍 Cultura', icon: Icon(Icons.language)),
            Tab(text: '📊 Análisis', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LearningPathsTab(),
          _RecipesTab(),
          _CultureTab(),
          _AnalyticsTab(),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: LEARNING PATHS (CON SUB-PESTAÑAS)
// ==========================================
class _LearningPathsTab extends StatefulWidget {
  const _LearningPathsTab();

  @override
  State<_LearningPathsTab> createState() => _LearningPathsTabState();
}

class _LearningPathsTabState extends State<_LearningPathsTab>
    with TickerProviderStateMixin {
  late TabController _subTabController;
  List<dynamic> paths = [];
  bool isLoading = true;
  String? selectedPathId; // Para gestionar nodos

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadPaths();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaths() async {
    try {
      final fetchedPaths = await ApiService.adminGetAllLearningPaths();
      setState(() {
        paths = fetchedPaths;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sub-TabBar
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: '📚 Caminos', icon: Icon(Icons.school)),
            Tab(text: '🔗 Nodos de Contenido', icon: Icon(Icons.link)),
          ],
        ),
        // Sub-TabView
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Tab 1: Gestión de Caminos
              _PathsListView(paths: paths, onRefresh: _loadPaths),
              // Tab 2: Gestión de Nodos
              _NodesManagementView(
                paths: paths,
                selectedPathId: selectedPathId,
                onPathSelected: (pathId) {
                  setState(() => selectedPathId = pathId);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUB-VIEW 1: Listado de Caminos
// ==========================================
class _PathsListView extends StatelessWidget {
  final List<dynamic> paths;
  final VoidCallback onRefresh;

  const _PathsListView({required this.paths, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Caminos de Aprendizaje',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreatePathDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (paths.isEmpty)
            const Center(child: Text('No hay caminos. ¡Crea uno!'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                return _PathCard(path: path, onRefresh: onRefresh);
              },
            ),
        ],
      ),
    );
  }

  void _showCreatePathDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreatePathDialog(onSaved: onRefresh),
    );
  }
}

// ==========================================
// SUB-VIEW 2: Gestión de Nodos (Contenido)
// ==========================================
class _NodesManagementView extends StatefulWidget {
  final List<dynamic> paths;
  final String? selectedPathId;
  final Function(String) onPathSelected;

  const _NodesManagementView({
    required this.paths,
    this.selectedPathId,
    required this.onPathSelected,
  });

  @override
  State<_NodesManagementView> createState() => _NodesManagementViewState();
}

class _NodesManagementViewState extends State<_NodesManagementView> {
  List<dynamic> nodes = [];
  bool isLoadingNodes = false;
  String? selectedPathId;

  @override
  void initState() {
    super.initState();
    selectedPathId = widget.selectedPathId;
  }

  Future<void> _loadNodes(String pathId) async {
    setState(() => isLoadingNodes = true);
    try {
      final fetchedNodes = await ApiService.adminGetNodesByPath(pathId);
      setState(() {
        nodes = fetchedNodes;
        isLoadingNodes = false;
      });
    } catch (e) {
      setState(() => isLoadingNodes = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          const Text(
            '🔗 Gestión de Nodos de Contenido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cada camino tiene un árbol de lecciones que se desbloquean progresivamente.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Selector de Camino
          if (widget.paths.isEmpty)
            const Text('❌ Crea un camino primero')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona un camino:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedPathId,
                  hint: const Text('Elige un camino...'),
                  isExpanded: true,
                  items: widget.paths.map((path) {
                    return DropdownMenuItem<String>(
                      value: path['_id'] ?? path['id'],
                      child: Text(path['title'] ?? 'Sin título'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPathId = value);
                      widget.onPathSelected(value);
                      _loadNodes(value);
                    }
                  },
                ),
              ],
            ),

          const SizedBox(height: 30),

          // Contenido de Nodos
          if (selectedPathId == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '👉 Selecciona un camino arriba para ver y gestionar sus nodos de contenido',
              ),
            )
          else if (isLoadingNodes)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nodos de este camino',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddNodeDialog(selectedPathId!),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Nodo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (nodes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📭 Este camino no tiene nodos. ¡Agrega contenido!',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return _NodeCard(
                        node: node,
                        onRefresh: () => _loadNodes(selectedPathId!),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddNodeDialog(String pathId) {
    showDialog(
      context: context,
      builder: (context) =>
          CreateNodeDialogV2(pathId: pathId, onSaved: () => _loadNodes(pathId)),
    );
  }
}

// ==========================================
// TAB 2: RECIPES
// ==========================================
class _RecipesTab extends StatelessWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context) {
    return const RecipesManagementTab();
  }
}

// ==========================================
// TAB 3: CULTURE
// ==========================================
class _CultureTab extends StatefulWidget {
  const _CultureTab();

  @override
  State<_CultureTab> createState() => _CultureTabState();
}

class _CultureTabState extends State<_CultureTab> {
  List<dynamic> cultures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCultures();
  }

  Future<void> _loadCultures() async {
    try {
      final fetchedCultures = await ApiService.adminGetAllCulture();
      setState(() {
        cultures = fetchedCultures;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contenido Cultural',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateCultureDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Contenido'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (cultures.isEmpty)
            const Center(child: Text('No hay contenido cultural. ¡Crea uno!'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cultures.length,
              itemBuilder: (context, index) {
                final culture = cultures[index];
                return _CultureCard(culture: culture, onRefresh: _loadCultures);
              },
            ),
        ],
      ),
    );
  }

  void _showCreateCultureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateCultureDialog(onSaved: _loadCultures),
    );
  }
}

// ==========================================
// TAB 4: ANALYTICS
// ==========================================
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis y Estadísticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _AnalyticsCard(
            title: 'Usuarios Activos',
            value: '0',
            icon: Icons.people,
          ),
          _AnalyticsCard(
            title: 'Lecciones Completadas',
            value: '0',
            icon: Icons.check_circle,
          ),
          _AnalyticsCard(
            title: 'XP Total Ganado',
            value: '0',
            icon: Icons.star,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTS
// ==========================================

class _PathCard extends StatelessWidget {
  final dynamic path;
  final VoidCallback onRefresh;

  const _PathCard({required this.path, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final String pathType = path['type'] ?? 'unknown';
    final String title = path['title'] ?? 'Sin título';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(
          path['icon'] ?? '📚',
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(title),
        subtitle: Text(
          pathType == 'goal'
              ? 'Tipo: ${path['goalType'] ?? 'N/A'}'
              : 'Tipo: $pathType',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () => _showEditDialog(context),
            ),
            PopupMenuItem(
              child: const Text('Eliminar'),
              onTap: () => _delete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Editar próximamente')));
  }

  Future<void> _delete(BuildContext context) async {
    final pathId = path['_id'] ?? path['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Camino'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ApiService.adminDeleteLearningPath(pathId);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Camino eliminado')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _CultureCard extends StatelessWidget {
  final dynamic culture;
  final VoidCallback onRefresh;

  const _CultureCard({required this.culture, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final String title = culture['title'] ?? 'Sin título';
    final String countryName = culture['countryId'] != null
        ? culture['countryId']['name'] ?? 'N/A'
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Text('🌍', style: TextStyle(fontSize: 24)),
        title: Text(title),
        subtitle: Text('País: $countryName'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () => _showEditDialog(context),
            ),
            PopupMenuItem(
              child: const Text('Eliminar'),
              onTap: () => _delete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Editar próximamente')));
  }

  Future<void> _delete(BuildContext context) async {
    final cultureId = culture['_id'] ?? culture['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contenido'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ApiService.adminDeleteCulture(cultureId);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Contenido eliminado')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.orange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
}

// ==========================================
// DIALOGS
// ==========================================

class _CreatePathDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _CreatePathDialog({required this.onSaved});

  @override
  State<_CreatePathDialog> createState() => _CreatePathDialogState();
}

class _CreatePathDialogState extends State<_CreatePathDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final String _selectedType = 'goal';
  String _selectedGoalType = 'cooking_school';
  bool _isPremium = false;
  bool _isLoading = false;

  final goalTypes = [
    'cooking_school',
    'lose_weight',
    'gain_muscle',
    'become_vegan',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
      await ApiService.adminCreateLearningPath({
        'type': _selectedType,
        'goalType': _selectedGoalType,
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'isPremium': _isPremium,
      });

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camino creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nuevo Camino'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGoalType,
              items: goalTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGoalType = val);
              },
              decoration: const InputDecoration(labelText: 'Tipo de Meta'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _isPremium,
              onChanged: (val) => setState(() => _isPremium = val ?? false),
              title: const Text('Es Premium'),
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
              : const Text('Crear'),
        ),
      ],
    );
  }
}

// ==========================================
// NOTE: CreateRecipeDialog moved to recipes_management.dart
// ==========================================

class _CreateCultureDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _CreateCultureDialog({required this.onSaved});

  @override
  State<_CreateCultureDialog> createState() => _CreateCultureDialogState();
}

class _CreateCultureDialogState extends State<_CreateCultureDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCountry = '';
  bool _isLoading = false;
  List<dynamic> countries = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final fetchedCountries = await ApiService.getCountries();
      setState(() => countries = fetchedCountries);
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _selectedCountry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son requeridos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.adminCreateCulture({
        'countryId': _selectedCountry,
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'steps': [],
      });

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenido creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Contenido Cultural'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCountry.isEmpty ? null : _selectedCountry,
              items: countries
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: (c['_id'] ?? c['id']).toString(),
                      child: Text(c['name'] ?? 'País'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCountry = val);
              },
              decoration: const InputDecoration(labelText: 'País'),
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
              : const Text('Crear'),
        ),
      ],
    );
  }
}

// ==========================================
// NODE CARD: Muestra detalles de un nodo
// ==========================================
class _NodeCard extends StatelessWidget {
  final dynamic node;
  final VoidCallback onRefresh;

  const _NodeCard({required this.node, required this.onRefresh});

  String _getTypeEmoji(String? type) {
    switch (type) {
      case 'test':
        return '✅';
      case 'practice':
        return '💪';
      case 'explanation':
        return '📖';
      case 'lesson':
      default:
        return '📚';
    }
  }

  String _getTypeName(String? type) {
    switch (type) {
      case 'test':
        return 'Test';
      case 'practice':
        return 'Práctica';
      case 'explanation':
        return 'Explicación';
      case 'lesson':
      default:
        return 'Lección';
    }
  }

  String _getDifficultyStars(int? difficulty) {
    final stars = '⭐' * (difficulty ?? 3);
    return stars;
  }

  Future<void> _delete(BuildContext context) async {
    final nodeId = node['_id'] ?? node['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Nodo'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ApiService.adminDeleteLearningNode(nodeId);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nodo eliminado')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showEditNodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditNodeDialogV2(
        node: node,
        pathId: '', // Será obtenido del contexto
        onSaved: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = node['title'] ?? 'Sin título';
    final String? description = node['description'];
    final int? duration = node['duration'];
    final int? xpReward = node['xpReward'];
    final bool isRequired = node['isRequired'] ?? false;
    final String? type = node['type'];
    final int? difficulty = node['difficulty'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text(
          _getTypeEmoji(type),
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            if (duration != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('⏱️ ${duration}min'),
              ),
            if (xpReward != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('🎁 +$xpReward XP'),
              ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('🔒 Obligatorio'),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  const Text(
                    'Descripción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text('${_getTypeEmoji(type)} ${_getTypeName(type)}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dificultad:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(_getDifficultyStars(difficulty)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEditNodeDialog(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Contenido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _delete(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
