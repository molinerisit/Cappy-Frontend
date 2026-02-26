import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'dialogs/create_path_dialog.dart';
import 'dialogs/create_node_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> paths = [];
  List<dynamic> nodes = [];
  bool isLoading = true;
  dynamic selectedPath;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPaths();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        ).showSnackBar(SnackBar(content: Text('Error cargando caminos: $e')));
      }
    }
  }

  Future<void> _loadNodes(String pathId) async {
    try {
      final fetchedNodes = await ApiService.adminGetNodesByPath(pathId);
      setState(() => nodes = fetchedNodes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando nodos: $e')));
      }
    }
  }

  void _selectPath(dynamic path) {
    setState(() => selectedPath = path);
    _loadNodes(path['_id'] ?? path['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Caminos de Aprendizaje"),
            Tab(text: "Nodos"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ================== TAB 1: LEARNING PATHS ==================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Caminos Disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    CreatePathDialog(onPathCreated: _loadPaths),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo Camino'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: paths.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay caminos. ¡Crea el primero!',
                                ),
                              )
                            : ListView.builder(
                                itemCount: paths.length,
                                itemBuilder: (context, index) {
                                  final path = paths[index];
                                  final isSelected =
                                      selectedPath?['_id'] ??
                                      selectedPath?['id'] == path['_id'] ??
                                      path['id'];
                                  final pathType = path['type'] ?? 'unknown';
                                  final typeEmoji = pathType == 'country_recipe'
                                      ? '📖'
                                      : pathType == 'country_culture'
                                      ? '🎭'
                                      : '🎯';

                                  return Card(
                                    color: isSelected
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Text(
                                        typeEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      title: Text(
                                        path['title'] ?? 'Sin título',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${pathType.replaceAll('_', ' ')} • ${path['nodes']?.length ?? 0} nodos',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_note),
                                            onPressed: () => _selectPath(path),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deletePath(
                                              path['_id'] ?? path['id'],
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _selectPath(path),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // ================== TAB 2: LEARNING NODES ==================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: selectedPath == null
                      ? const Center(
                          child: Text(
                            'Selecciona un camino en la pestaña anterior para ver sus nodos',
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Nodos de ${selectedPath['title'] ?? 'Sin título'}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => CreateNodeDialog(
                                        preSelectedPathId:
                                            selectedPath['_id'] ??
                                            selectedPath['id'],
                                        onNodeCreated: () {
                                          _selectPath(selectedPath);
                                        },
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nuevo Nodo'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: nodes.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay nodos. ¡Crea el primero!',
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: nodes.length,
                                      itemBuilder: (context, index) {
                                        final node = nodes[index];
                                        final nodeType =
                                            node['type'] ?? 'unknown';
                                        final typeEmoji = nodeType == 'recipe'
                                            ? '🍳'
                                            : nodeType == 'skill'
                                            ? '💪'
                                            : '❓';

                                        return Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                typeEmoji,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  node['title'] ??
                                                                      'Sin título',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            node['description'] ??
                                                                'Sin descripción',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                          ),
                                                          onPressed: () {
                                                            // TODO: Edit node
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed: () {
                                                            _deleteNode(
                                                              node['_id'] ??
                                                                  node['id'],
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [
                                                    Chip(
                                                      label: Text(
                                                        'Orden: ${node['order'] ?? '?'}',
                                                      ),
                                                      backgroundColor:
                                                          Colors.grey.shade200,
                                                    ),
                                                    Chip(
                                                      label: Text(
                                                        node['difficulty'] ??
                                                            'normal',
                                                      ),
                                                      backgroundColor: Colors
                                                          .orange
                                                          .shade100,
                                                    ),
                                                    Chip(
                                                      label: Text(
                                                        '${node['xpReward'] ?? 0} XP',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green.shade100,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _deletePath(String pathId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Camino'),
        content: const Text(
          '¿Estás seguro? Esta acción eliminará el camino y todos sus nodos.',
        ),
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

    if (confirmed == true) {
      try {
        await ApiService.adminDeleteLearningPath(pathId);
        setState(() {
          selectedPath = null;
          nodes = [];
        });
        _loadPaths();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Camino eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteNode(String nodeId) async {
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

    if (confirmed == true && selectedPath != null) {
      try {
        await ApiService.adminDeleteLearningNode(nodeId);
        _loadNodes(selectedPath['_id'] ?? selectedPath['id']);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nodo eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
