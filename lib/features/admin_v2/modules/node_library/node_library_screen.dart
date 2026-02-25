import 'package:flutter/material.dart';
import '../../../../core/api_service.dart';

class NodeLibraryScreen extends StatefulWidget {
  const NodeLibraryScreen({super.key});

  @override
  State<NodeLibraryScreen> createState() => _NodeLibraryScreenState();
}

class _NodeLibraryScreenState extends State<NodeLibraryScreen> {
  List<dynamic> _nodes = [];
  List<dynamic> _paths = [];
  bool _isLoading = true;
  String _search = '';
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLibrary();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      final paths = await ApiService.adminGetAllLearningPaths();
      setState(() => _paths = paths);
    } catch (_) {}
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.adminGetNodeLibrary(
        search: _search.isEmpty ? null : _search,
        type: _typeFilter == 'all' ? null : _typeFilter,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      setState(() => _nodes = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando biblioteca: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditDialog(dynamic node) async {
    final titleCtrl = TextEditingController(text: node['title'] ?? '');
    String status = node['status'] ?? 'active';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nodo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titulo'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'archived', child: Text('Archived')),
              ],
              onChanged: (value) => status = value ?? 'active',
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await ApiService.adminUpdateContentNode(node['_id'] ?? node['id'], {
        'title': titleCtrl.text.trim(),
        'status': status,
      });
      await _loadLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
      }
    }
  }

  Future<void> _openRelationsDialog(dynamic node) async {
    try {
      final relations = await ApiService.adminGetNodeRelations(
        node['_id'] ?? node['id'],
      );

      // ignore: use_build_context_synchronously
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Relaciones'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RelationList(
                  title: 'Linked instances',
                  items: relations['linkedInstances'] as List? ?? [],
                  onOpen: (relation) {
                    Navigator.of(context).pop();
                    final path = relation['pathId'] as Map?;
                    final pathId = path?['_id']?.toString();
                    Navigator.of(this.context).pushNamed(
                      '/admin-v2',
                      arguments: {
                        'pathId': pathId,
                        'nodeId': relation['_id']?.toString(),
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                _RelationList(
                  title: 'Referenced by',
                  items: relations['referencedBy'] as List? ?? [],
                  onOpen: (relation) {
                    Navigator.of(context).pop();
                    final path = relation['pathId'] as Map?;
                    final pathId = path?['_id']?.toString();
                    Navigator.of(this.context).pushNamed(
                      '/admin-v2',
                      arguments: {
                        'pathId': pathId,
                        'nodeId': relation['_id']?.toString(),
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando relaciones: $e')),
        );
      }
    }
  }

  Future<void> _duplicateNode(dynamic node) async {
    try {
      await ApiService.adminDuplicateNode(node['_id'] ?? node['id']);
      await _loadLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error duplicando: $e')));
      }
    }
  }

  Future<void> _archiveNode(dynamic node) async {
    try {
      await ApiService.adminArchiveNode(node['_id'] ?? node['id']);
      await _loadLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error archivando: $e')));
      }
    }
  }

  Future<void> _openImportDialog(dynamic node) async {
    if (_paths.isEmpty) {
      await _loadPaths();
    }
    String? selectedPathId = _paths.isNotEmpty
        ? _paths.first['_id']?.toString() ?? _paths.first['id']?.toString()
        : null;
    String mode = 'linked';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar en camino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedPathId,
              items: _paths
                  .map(
                    (path) => DropdownMenuItem(
                      value: path['_id']?.toString() ?? path['id']?.toString(),
                      child: Text(path['title'] ?? 'Sin titulo'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => selectedPathId = value,
              decoration: const InputDecoration(labelText: 'Camino'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: mode,
              items: const [
                DropdownMenuItem(value: 'linked', child: Text('Linked')),
                DropdownMenuItem(value: 'copy', child: Text('Copy')),
              ],
              onChanged: (value) => mode = value ?? 'linked',
              decoration: const InputDecoration(labelText: 'Modo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (result != true || selectedPathId == null) return;

    try {
      await ApiService.adminImportNode({
        'targetPathId': selectedPathId,
        'nodeId': node['_id'] ?? node['id'],
        'mode': mode,
        if (node['sourceType'] != null) 'sourceType': node['sourceType'],
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nodo importado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importando: $e')));
      }
    }
  }

  List<DataRow> _buildRows() {
    return _nodes.map((node) {
      final path = node['pathId'] as Map?;
      final group = node['groupId'] as Map?;
      return DataRow(
        cells: [
          DataCell(Text(node['title'] ?? '')),
          DataCell(Text(node['type'] ?? '')),
          DataCell(Text(group?['title'] ?? '-')),
          DataCell(Text(path?['title'] ?? '-')),
          DataCell(Text((node['level'] ?? 1).toString())),
          DataCell(Text((node['xpReward'] ?? 0).toString())),
          const DataCell(Text('-')),
          DataCell(Text(node['updatedAt'] ?? '-')),
          DataCell(Text(node['status'] ?? 'active')),
          DataCell(
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditDialog(node);
                } else if (value == 'relations') {
                  _openRelationsDialog(node);
                } else if (value == 'duplicate') {
                  _duplicateNode(node);
                } else if (value == 'archive') {
                  _archiveNode(node);
                } else if (value == 'import') {
                  _openImportDialog(node);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'relations', child: Text('Relaciones')),
                PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                PopupMenuItem(value: 'import', child: Text('Importar')),
                PopupMenuItem(value: 'archive', child: Text('Archivar')),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Node Library',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search nodes',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _search = value,
                  onSubmitted: (_) => _loadLibrary(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _typeFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All types')),
                  DropdownMenuItem(value: 'recipe', child: Text('Recipe')),
                  DropdownMenuItem(
                    value: 'explanation',
                    child: Text('Explanation'),
                  ),
                  DropdownMenuItem(value: 'tips', child: Text('Tips')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(
                    value: 'technique',
                    child: Text('Technique'),
                  ),
                  DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                  DropdownMenuItem(
                    value: 'challenge',
                    child: Text('Challenge'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _typeFilter = value ?? 'all');
                  _loadLibrary();
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value ?? 'all');
                  _loadLibrary();
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _loadLibrary,
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Grupo')),
                    DataColumn(label: Text('Camino')),
                    DataColumn(label: Text('Nivel')),
                    DataColumn(label: Text('XP')),
                    DataColumn(label: Text('Reutilizaciones')),
                    DataColumn(label: Text('Ultima modificacion')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _buildRows(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelationList extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final void Function(Map<String, dynamic>) onOpen;

  const _RelationList({
    required this.title,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('$title: 0');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${items.length}'),
        const SizedBox(height: 6),
        ...items.map((item) {
          final path = item['pathId'] as Map?;
          final pathTitle = path?['title'] ?? '';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item['title'] ?? ''),
            subtitle: pathTitle.toString().isEmpty
                ? null
                : Text(pathTitle.toString()),
            trailing: TextButton(
              onPressed: () => onOpen(item as Map<String, dynamic>),
              child: const Text('Open'),
            ),
          );
        }),
      ],
    );
  }
}
