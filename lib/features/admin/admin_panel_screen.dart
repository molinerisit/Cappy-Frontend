import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'dialogs/create_node_dialog_v2.dart';
import 'dialogs/edit_node_dialog.dart';
import '../admin_v2/modules/node_tree/node_tree_editor_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cappy Admin',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Search bar
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar caminos...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Auto-save indicator
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Guardado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // User menu
              PopupMenuButton<void>(
                itemBuilder: (context) => <PopupMenuEntry<void>>[
                  const PopupMenuItem(child: Text('Mi Perfil')),
                  const PopupMenuItem(child: Text('Configuración')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onTap: () => context.read<AuthProvider>().logout(),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          // SIDEBAR
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.grey.shade50,
            indicatorColor: Colors.orange.shade100,
            selectedIconTheme: IconThemeData(color: Colors.orange.shade600),
            selectedLabelTextStyle: TextStyle(
              color: Colors.orange.shade600,
              fontWeight: FontWeight.bold,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text('Caminos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant),
                label: Text('Recetas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.language),
                label: Text('Cultura'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books),
                label: Text('Biblioteca'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Configuración'),
              ),
            ],
          ),
          // MAIN CONTENT
          Expanded(child: _buildContentPage(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildContentPage(int index) {
    switch (index) {
      case 0:
        return const _LearningPathsTab();
      case 1:
        return const _RecipesContentPage();
      case 2:
        return const _CultureContentPage();
      case 3:
        return const _LibraryContentPage();
      case 4:
        return const _SettingsContentPage();
      default:
        return const _LearningPathsTab();
    }
  }
}

// ==========================================
// TAB 1: LEARNING PATHS
// ==========================================
class _LearningPathsTab extends StatefulWidget {
  const _LearningPathsTab();

  @override
  State<_LearningPathsTab> createState() => _LearningPathsTabState();
}

class _LearningPathsTabState extends State<_LearningPathsTab> {
  List<dynamic> paths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaths();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caminos de Aprendizaje',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona los caminos de aprendizaje para tus usuarios',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreatePathDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Camino'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Paths grid
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (paths.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No hay caminos creados',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.3,
              ),
              itemCount: paths.length,
              itemBuilder: (context, index) {
                return _PathCardV2(path: paths[index], onRefresh: _loadPaths);
              },
            ),
        ],
      ),
    );
  }

  void _showCreatePathDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreatePathDialog(onSaved: _loadPaths),
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
// RECIPES CONTENT PAGE (Sidebar)
// ==========================================
class _RecipesContentPage extends StatelessWidget {
  const _RecipesContentPage();

  @override
  Widget build(BuildContext context) {
    return _LegacyRedirectNotice(
      icon: Icons.restaurant,
      title: 'Recetas',
      message:
          'Las recetas se gestionan dentro de los caminos. Abre un camino en "Caminos" para editar sus recetas.',
    );
  }
}

// ==========================================
// CULTURE CONTENT PAGE (Sidebar)
// ==========================================
class _CultureContentPage extends StatelessWidget {
  const _CultureContentPage();

  @override
  Widget build(BuildContext context) {
    return _LegacyRedirectNotice(
      icon: Icons.language,
      title: 'Cultura',
      message:
          'El contenido cultural se gestiona dentro de los caminos. Abre un camino en "Caminos" para editar cultura.',
    );
  }
}

// ==========================================
// LIBRARY CONTENT PAGE (Sidebar)
// ==========================================
class _LibraryContentPage extends StatelessWidget {
  const _LibraryContentPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biblioteca Global',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gesitona nodos reutilizables disponibles en todos los caminos',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.library_books,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Biblioteca en construcción',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SETTINGS CONTENT PAGE (Sidebar)
// ==========================================
class _SettingsContentPage extends StatelessWidget {
  const _SettingsContentPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Administra la configuración del panel',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Modo Claro'),
                  trailing: Radio(
                    value: true,
                    groupValue: true,
                    onChanged: (val) {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyRedirectNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _LegacyRedirectNotice({
    required this.title,
    required this.message,
    this.icon = Icons.info,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.orange.shade600, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: RECIPES (legacy - untuk backward compat)
// ==========================================
class _RecipesTab extends StatelessWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context) {
    return const _RecipesContentPage();
  }
}

// ==========================================
// TAB 3: CULTURE (legacy - untuk backward compat)
// ==========================================
class _CultureTab extends StatefulWidget {
  const _CultureTab();

  @override
  State<_CultureTab> createState() => _CultureTabState();
}

class _CultureTabState extends State<_CultureTab> {
  @override
  Widget build(BuildContext context) {
    return const _CultureContentPage();
  }
}

class PathContentScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;
  final String? countryId;
  final String pathType; // 'country_recipe', 'country_culture', 'goal'

  const PathContentScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
    this.countryId,
    this.pathType = 'goal',
  });

  @override
  State<PathContentScreen> createState() => _PathContentScreenState();
}

class _PathContentScreenState extends State<PathContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Calcular número de tabs según el tipo de camino
    int tabCount = 1; // Siempre tiene 'Nodos'
    if (widget.pathType == 'country_recipe') {
      tabCount = 2; // Nodos + Recetas
    } else if (widget.pathType == 'country_culture') {
      tabCount = 2; // Nodos + Cultura
    } else if (widget.pathType.isEmpty || widget.pathType == 'goal') {
      tabCount = 1; // Solo Nodos para objetivos
    }
    _tabController = TabController(length: tabCount, vsync: this);
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
        title: Text('Camino: ${widget.pathTitle}'),
        backgroundColor: Colors.orange.shade700,
        bottom: TabBar(controller: _tabController, tabs: _buildTabs()),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabChildren(),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = [const Tab(text: 'Nodos')];

    if (widget.pathType == 'country_recipe') {
      tabs.add(const Tab(text: 'Recetas'));
    }

    if (widget.pathType == 'country_culture') {
      tabs.add(const Tab(text: 'Cultura'));
    }

    return tabs;
  }

  List<Widget> _buildTabChildren() {
    final children = <Widget>[
      NodeTreeEditorScreen(initialPathId: widget.pathId),
    ];

    if (widget.pathType == 'country_recipe') {
      children.add(
        _RecipesTabContent(countryId: widget.countryId, pathId: widget.pathId),
      );
    }

    if (widget.pathType == 'country_culture') {
      children.add(
        _CultureTabContent(countryId: widget.countryId, pathId: widget.pathId),
      );
    }

    return children;
  }
}

// ==========================================
// RECIPES TAB CONTENT
// ==========================================
class _RecipesTabContent extends StatefulWidget {
  final String? countryId;
  final String pathId;

  const _RecipesTabContent({required this.countryId, required this.pathId});

  @override
  State<_RecipesTabContent> createState() => _RecipesTabContentState();
}

class _RecipesTabContentState extends State<_RecipesTabContent> {
  bool isLoading = false;
  List<dynamic> recipes = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (widget.countryId == null) {
      setState(() {
        errorMessage = 'No country associated with this path';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.adminGetRecipesByCountry(widget.countryId!);
      setState(() {
        recipes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading recipes: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (recipes.isEmpty) {
      return const Center(child: Text('No recipes found for this country'));
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(recipe['title'] ?? 'Sin título'),
            subtitle: Text(
              'Dificultad: ${recipe['difficulty'] ?? 'N/A'} | XP: ${recipe['xpReward'] ?? 0}',
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // TODO: Open recipe editor
            },
          ),
        );
      },
    );
  }
}

// ==========================================
// CULTURE TAB CONTENT
// ==========================================
class _CultureTabContent extends StatefulWidget {
  final String? countryId;
  final String pathId;

  const _CultureTabContent({required this.countryId, required this.pathId});

  @override
  State<_CultureTabContent> createState() => _CultureTabContentState();
}

class _CultureTabContentState extends State<_CultureTabContent> {
  bool isLoading = false;
  List<dynamic> cultureNodes = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCultureNodes();
  }

  Future<void> _loadCultureNodes() async {
    if (widget.countryId == null) {
      setState(() {
        errorMessage = 'No country associated with this path';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.adminGetCultureByCountry(widget.countryId!);
      setState(() {
        cultureNodes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading culture: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (cultureNodes.isEmpty) {
      return const Center(
        child: Text('No culture nodes found for this country'),
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(16),
      itemCount: cultureNodes.length,
      itemBuilder: (context, index) {
        final node = cultureNodes[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(node['title'] ?? 'Sin título'),
            subtitle: Text(node['description'] ?? 'Sin descripción'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // TODO: Open culture node editor
            },
          ),
        );
      },
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
// PATH CARD V2: Grid-based design
// ==========================================
class _PathCardV2 extends StatelessWidget {
  final dynamic path;
  final VoidCallback onRefresh;

  const _PathCardV2({required this.path, required this.onRefresh});

  String _getPathIcon() {
    final pathType = path['type'] ?? 'unknown';
    if (pathType == 'goal') {
      final goalType = path['goalType'] ?? '';
      switch (goalType) {
        case 'cooking_school':
          return '🍳';
        case 'lose_weight':
          return '⚖️';
        case 'gain_muscle':
          return '💪';
        case 'become_vegan':
          return '🌱';
        default:
          return '📚';
      }
    }
    return path['icon'] ?? '📚';
  }

  void _openPath(BuildContext context) {
    final pathId = path['_id'] ?? path['id'];
    final title = path['title'] ?? 'Sin título';

    // Safely convert countryId to string (could be object or string from API)
    String? countryId;
    if (path['countryId'] != null) {
      final cId = path['countryId'];
      if (cId is String) {
        countryId = cId;
      } else if (cId is Map) {
        countryId = cId['\$oid'] ?? cId['_id']?.toString() ?? cId.toString();
      } else {
        countryId = cId.toString();
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PathContentScreen(
          pathId: pathId,
          pathTitle: title,
          countryId: countryId,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final String title = path['title'] ?? 'Sin título';
    final String? description = path['description'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPath(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with icon and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getPathIcon(), style: const TextStyle(fontSize: 32)),
                  PopupMenuButton<void>(
                    itemBuilder: (context) => <PopupMenuEntry<void>>[
                      PopupMenuItem(
                        child: const Text('Editar'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Editar próximamente'),
                            ),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Duplicar'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Duplicar próximamente'),
                            ),
                          );
                        },
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _delete(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              if (description != null)
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Sin descripción',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 12),
              // Footer badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Abrir →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  final VoidCallback onOpenPath;

  const _PathCard({
    required this.path,
    required this.onRefresh,
    required this.onOpenPath,
  });

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
        onTap: onOpenPath,
        trailing: PopupMenuButton<void>(
          itemBuilder: (context) => <PopupMenuEntry<void>>[
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () => _showEditDialog(context),
            ),
            PopupMenuItem(
              child: const Text('Abrir contenido'),
              onTap: onOpenPath,
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
