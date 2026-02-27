import 'package:flutter/material.dart';
import '../../../../core/api_service.dart';
import 'tree_layout.dart';

class NodeTreeEditorScreen extends StatefulWidget {
  final String? initialPathId;
  final String? initialNodeId;

  const NodeTreeEditorScreen({
    super.key,
    this.initialPathId,
    this.initialNodeId,
  });

  @override
  State<NodeTreeEditorScreen> createState() => _NodeTreeEditorScreenState();
}

class _NodeTreeEditorScreenState extends State<NodeTreeEditorScreen> {
  List<dynamic> _paths = [];
  List<dynamic> _groups = [];
  List<dynamic> _nodes = [];

  String? _selectedPathId;
  dynamic _selectedItem;
  dynamic _selectedNode;
  Map<String, dynamic>? _selectedStep;
  Map<String, dynamic>? _selectedCard;
  String? _selectedType;
  String? _pendingSelectNodeId;
  String? _expandedNodeId;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _relationsLoading = false;
  Map<String, dynamic> _relations = {};
  int? _reorderLevel;

  final _groupTitleCtrl = TextEditingController();
  final _groupOrderCtrl = TextEditingController(text: '1');

  final _nodeTitleCtrl = TextEditingController();
  final _nodeLevelCtrl = TextEditingController(text: '1');
  final _nodePositionCtrl = TextEditingController(text: '1');
  final _nodeXpCtrl = TextEditingController(text: '0');
  String _nodeType = 'recipe';
  String _nodeStatus = 'active';
  bool _nodeLockedByDefault = true;
  final ScrollController _treeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pendingSelectNodeId = widget.initialNodeId;
    _selectedPathId = widget.initialPathId;
    _loadPaths();
  }

  @override
  void dispose() {
    _groupTitleCtrl.dispose();
    _groupOrderCtrl.dispose();
    _nodeTitleCtrl.dispose();
    _nodeLevelCtrl.dispose();
    _nodePositionCtrl.dispose();
    _nodeXpCtrl.dispose();
    _treeScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoading = true);
    try {
      final paths = await ApiService.adminGetAllLearningPaths();
      String? nextPathId = _selectedPathId;
      if (nextPathId == null && paths.isNotEmpty) {
        nextPathId =
            paths.first['_id']?.toString() ?? paths.first['id']?.toString();
      }

      setState(() {
        _paths = paths;
        _selectedPathId = nextPathId;
      });

      if (nextPathId != null) {
        await _loadContent(nextPathId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando caminos: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContent(String pathId) async {
    setState(() => _isLoading = true);
    try {
      final groups = await ApiService.adminGetGroupsByPath(pathId);
      final nodes = await ApiService.adminGetContentNodesByPath(pathId);

      print('🔍 [_loadContent] Loaded data:');
      print('  Groups: ${groups.length} items');
      for (var g in groups) {
        print('    - ${g['title']} (${g['_id']})');
      }
      print('  Nodes: ${nodes.length} items');
      for (var n in nodes) {
        final gid = n['groupId'];
        final groupIdDisplay = gid is Map
            ? '${gid['_id']} (${gid['title']})'
            : gid?.toString() ?? 'null';
        print(
          '    - ${n['title']} (groupId: $groupIdDisplay, level: ${n['level']})',
        );
      }

      setState(() {
        _groups = groups;
        _nodes = nodes;
        _reorderLevel ??= _inferFirstLevel(nodes);
      });
      if (_pendingSelectNodeId != null) {
        _selectNodeById(_pendingSelectNodeId!);
        _pendingSelectNodeId = null;
      }
    } catch (e) {
      print('❌ [_loadContent] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando contenido: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _currentSteps() {
    if (_selectedNode == null || _selectedNode['steps'] is! List) {
      return [];
    }
    return List<Map<String, dynamic>>.from(_selectedNode['steps']);
  }

  List<Map<String, dynamic>> _currentCards() {
    if (_selectedStep == null || _selectedStep!['cards'] is! List) {
      return [];
    }
    return List<Map<String, dynamic>>.from(_selectedStep!['cards']);
  }

  List<Map<String, dynamic>> _getStepCards(Map<String, dynamic> step) {
    if (step['cards'] is! List) {
      return [];
    }
    return List<Map<String, dynamic>>.from(step['cards']);
  }

  void _selectGroup(dynamic group) {
    setState(() {
      _selectedItem = group;
      _selectedType = 'group';
      _selectedNode = null;
      _selectedStep = null;
      _selectedCard = null;
      _expandedNodeId = null;
      _groupTitleCtrl.text = group['title'] ?? '';
      _groupOrderCtrl.text = (group['order'] ?? 1).toString();
    });
  }

  void _selectNode(dynamic node) {
    setState(() {
      _selectedItem = node;
      _selectedType = 'node';
      _selectedNode = node;
      _selectedStep = null;
      _selectedCard = null;
      _nodeTitleCtrl.text = node['title'] ?? '';
      _nodeLevelCtrl.text = (node['level'] ?? 1).toString();
      _nodePositionCtrl.text = (node['positionIndex'] ?? 1).toString();
      _nodeXpCtrl.text = (node['xpReward'] ?? 0).toString();
      _nodeType = node['type'] ?? 'recipe';
      _nodeStatus = node['status'] ?? 'active';
      _nodeLockedByDefault = node['isLockedByDefault'] != false;
    });
    _loadRelations(node['_id'] ?? node['id']);
  }

  void _selectNodeById(String nodeId) {
    final node = _nodes.cast<dynamic>().firstWhere(
      (item) => (item['_id'] ?? item['id']).toString() == nodeId,
      orElse: () => null,
    );
    if (node != null) {
      _selectNode(node);
    }
  }

  Future<void> _openNodeFromRelation(Map<String, dynamic> relation) async {
    final nodeId = relation['_id']?.toString();
    final path = relation['pathId'];
    final pathId = path is Map ? path['_id']?.toString() : path?.toString();
    if (nodeId == null) return;

    if (pathId != null && pathId != _selectedPathId) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar camino'),
          content: const Text('Este nodo esta en otro camino. Cambiar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      setState(() {
        _selectedPathId = pathId;
        _pendingSelectNodeId = nodeId;
      });
      await _loadContent(pathId);
      return;
    }

    _selectNodeById(nodeId);
  }

  Future<void> _loadRelations(String nodeId) async {
    setState(() => _relationsLoading = true);
    try {
      final data = await ApiService.adminGetNodeRelations(nodeId);
      if (mounted) {
        setState(() => _relations = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando relaciones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _relationsLoading = false);
      }
    }
  }

  Future<void> _openImportNodeDialog({String? defaultGroupId}) async {
    if (_selectedPathId == null) return;
    String search = '';
    String mode = 'linked';
    List<dynamic> results = [];

    Future<void> searchNodes() async {
      final data = await ApiService.adminGetNodeLibrary(
        search: search.isEmpty ? null : search,
      );
      results = data;
    }

    await searchNodes();

    // ignore: use_build_context_synchronously
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            defaultGroupId != null ? 'Importar nodo al grupo' : 'Importar nodo',
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => search = value,
                  onSubmitted: (_) async {
                    await searchNodes();
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Modo'),
                  items: const [
                    DropdownMenuItem(value: 'linked', child: Text('Linked')),
                    DropdownMenuItem(value: 'copy', child: Text('Copy')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => mode = value ?? 'linked'),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final node = results[index];
                      return ListTile(
                        title: Text(node['title'] ?? ''),
                        subtitle: Text(node['type'] ?? ''),
                        onTap: () => Navigator.of(context).pop({
                          'nodeId': node['_id'] ?? node['id'],
                          'mode': mode,
                          'sourceType': node['sourceType'],
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;

    try {
      await ApiService.adminImportNode({
        'targetPathId': _selectedPathId,
        'nodeId': selected['nodeId'],
        'mode': selected['mode'],
        if (selected['sourceType'] != null)
          'sourceType': selected['sourceType'],
        if (defaultGroupId != null) 'groupId': defaultGroupId,
      });
      await _loadContent(_selectedPathId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importando nodo: $e')));
      }
    }
  }

  void _selectStep(Map<String, dynamic>? step) {
    setState(() {
      _selectedStep = step;
      _selectedCard = null;
    });
  }

  Future<void> _showCreateNodeDialog(
    String pathId, {
    String? defaultGroupId,
  }) async {
    final titleCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: '1');
    final xpCtrl = TextEditingController(text: '50');
    String typeValue = 'recipe';
    String statusValue = 'active';
    bool lockedByDefaultValue = true;
    String? selectedGroupId = defaultGroupId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo Nodo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título del nodo',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Salsa Roja Clásica',
                  ),
                ),
                const SizedBox(height: 12),
                if (_groups.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Grupo (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Sin grupo'),
                      ),
                      ..._groups.map(
                        (group) => DropdownMenuItem<String>(
                          value: (group['_id'] ?? group['id']).toString(),
                          child: Text(group['title'] ?? 'Sin titulo'),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedGroupId = val),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Crea un grupo primero',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeValue,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'recipe', child: Text('Recipe 🍽')),
                    DropdownMenuItem(
                      value: 'explanation',
                      child: Text('Explanation 📘'),
                    ),
                    DropdownMenuItem(value: 'tips', child: Text('Tips 💡')),
                    DropdownMenuItem(value: 'quiz', child: Text('Quiz ❓')),
                    DropdownMenuItem(
                      value: 'technique',
                      child: Text('Technique 🔧'),
                    ),
                    DropdownMenuItem(
                      value: 'cultural',
                      child: Text('Cultural 🌍'),
                    ),
                    DropdownMenuItem(
                      value: 'challenge',
                      child: Text('Challenge 🏆'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => typeValue = val ?? 'recipe'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nivel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: xpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP Reward',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: statusValue,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active ✓')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft 📝')),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Archived 📦'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => statusValue = val ?? 'active'),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Candado inicial activo'),
                  subtitle: const Text(
                    'Si está activo, el nodo inicia bloqueado para usuario.',
                  ),
                  value: lockedByDefaultValue,
                  onChanged: (value) =>
                      setDialogState(() => lockedByDefaultValue = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text('Crear Nodo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && titleCtrl.text.isNotEmpty) {
      try {
        await ApiService.adminCreateContentNode({
          'pathId': pathId,
          'title': titleCtrl.text,
          'type': typeValue,
          'level': int.tryParse(levelCtrl.text) ?? 1,
          'positionIndex': 1,
          'xpReward': int.tryParse(xpCtrl.text) ?? 50,
          'status': statusValue,
          'isLockedByDefault': lockedByDefaultValue,
          if (selectedGroupId != null) 'groupId': selectedGroupId,
        });
        await _loadContent(pathId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Nodo creado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creando nodo: $e')));
        }
      }
    }
    titleCtrl.dispose();
    levelCtrl.dispose();
    xpCtrl.dispose();
  }

  void _selectCard(Map<String, dynamic> card) {
    setState(() => _selectedCard = card);
  }

  int _inferFirstLevel(List<dynamic> nodes) {
    if (nodes.isEmpty) return 1;
    final levels =
        nodes.map((node) => (node['level'] ?? 1) as int).toSet().toList()
          ..sort();
    return levels.first;
  }

  List<int> _availableLevels() {
    final levels =
        _nodes.map((node) => (node['level'] ?? 1) as int).toSet().toList()
          ..sort();
    return levels;
  }

  Map<String, String> _groupTitleById() {
    final map = <String, String>{};
    for (final group in _groups) {
      final groupMap = group as Map<String, dynamic>;
      final id = groupMap['_id']?.toString() ?? '';
      final title = groupMap['title']?.toString().trim() ?? '';
      if (id.isNotEmpty && title.isNotEmpty) {
        map[id] = title;
      }
    }
    return map;
  }

  String _resolveGroupTitleForNode(
    Map<String, dynamic> node,
    Map<String, String> groupTitleById,
  ) {
    final directTitle = node['groupTitle']?.toString().trim() ?? '';
    if (directTitle.isNotEmpty) return directTitle;
    final groupId = node['groupId']?.toString() ?? '';
    return groupTitleById[groupId]?.trim() ?? '';
  }

  String _levelLabel(int level) {
    final nodes = _nodesForLevel(level);
    if (nodes.isEmpty) return 'Nivel $level';

    final groupTitleById = _groupTitleById();
    final titles = <String>{};
    for (final node in nodes) {
      final title = _resolveGroupTitleForNode(node, groupTitleById);
      if (title.isNotEmpty) {
        titles.add(title);
      }
    }

    if (titles.isEmpty) return 'Nivel $level';
    if (titles.length == 1) return titles.first;
    return titles.join(' / ');
  }

  List<Map<String, dynamic>> _nodesForGroup(dynamic groupId) {
    if (groupId == null) return [];
    final groupIdStr = groupId.toString();
    final result = _nodes
        .where((node) {
          final nodeGroupId = node['groupId'];
          if (nodeGroupId == null) return false;
          // Si groupId es un objeto populado (con _id, title, etc.)
          if (nodeGroupId is Map) {
            final nodeGroupIdStr =
                (nodeGroupId['_id'] ?? nodeGroupId['id'])?.toString() ?? '';
            return nodeGroupIdStr == groupIdStr;
          }
          // Si es un string simple
          return nodeGroupId.toString() == groupIdStr;
        })
        .map<Map<String, dynamic>>((node) => Map<String, dynamic>.from(node))
        .toList();

    print(
      '🔍 [_nodesForGroup] groupId: $groupIdStr -> found ${result.length} nodes',
    );
    return result;
  }

  List<int> _levelsForGroup(dynamic groupId) {
    final nodes = _nodesForGroup(groupId);
    final levels =
        nodes.map((node) => (node['level'] ?? 1) as int).toSet().toList()
          ..sort();
    return levels;
  }

  bool _isUngroupedNode(dynamic node) {
    final groupId = node['groupId'];
    if (groupId == null) return true;
    if (groupId is Map) {
      final id = groupId['_id'] ?? groupId['id'];
      return id == null || id.toString().isEmpty;
    }
    return groupId.toString().isEmpty;
  }

  List<Map<String, dynamic>> _nodesWithoutGroup() {
    return _nodes
        .where((node) => _isUngroupedNode(node))
        .map<Map<String, dynamic>>((node) => Map<String, dynamic>.from(node))
        .toList()
      ..sort((a, b) {
        final levelA = (a['level'] ?? 1) as int;
        final levelB = (b['level'] ?? 1) as int;
        final posA = (a['positionIndex'] ?? 1) as int;
        final posB = (b['positionIndex'] ?? 1) as int;
        final levelCompare = levelA.compareTo(levelB);
        if (levelCompare != 0) return levelCompare;
        return posA.compareTo(posB);
      });
  }

  List<int> _levelsForNodes(List<Map<String, dynamic>> nodes) {
    final levels =
        nodes.map((node) => (node['level'] ?? 1) as int).toSet().toList()
          ..sort();
    return levels;
  }

  List<Map<String, dynamic>> _nodesForLevelInList(
    List<Map<String, dynamic>> nodes,
    int level,
  ) {
    final levelNodes = nodes
        .where((node) => (node['level'] ?? 1) == level)
        .map<Map<String, dynamic>>((node) => Map<String, dynamic>.from(node))
        .toList();
    levelNodes.sort((a, b) {
      final posA = (a['positionIndex'] ?? 1) as int;
      final posB = (b['positionIndex'] ?? 1) as int;
      return posA.compareTo(posB);
    });
    return levelNodes;
  }

  Widget _buildUngroupedSection(List<Map<String, dynamic>> nodes) {
    final levels = _levelsForNodes(nodes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              left: BorderSide(color: Colors.grey.shade400, width: 3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sin grupo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${nodes.length} nodo${nodes.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...levels.expand((level) {
          final levelNodes = _nodesForLevelInList(nodes, level);
          return [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Text(
                'Nivel $level',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ...levelNodes.map((node) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6, left: 8, right: 4),
                decoration: BoxDecoration(
                  color: _selectedItem == node
                      ? Colors.blue.shade50
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedItem == node
                        ? Colors.blue.shade300
                        : Colors.grey.shade200,
                    width: _selectedItem == node ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  title: Text(
                    node['title'] ?? 'Sin titulo',
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    'Pos ${node['positionIndex'] ?? 1}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () => _selectNode(node),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'addStep') {
                        _selectNode(node);
                        _openStepDialog();
                      } else if (value == 'delete') {
                        _deleteNode(node);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'addStep',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'Agregar paso',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 14, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 16),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ];
        }),
      ],
    );
  }

  List<Map<String, dynamic>> _nodesForGroupAndLevel(
    dynamic groupId,
    int level,
  ) {
    final groupIdStr = groupId.toString();
    return _nodes
        .where((node) {
          final nodeGroupId = node['groupId'];
          if (nodeGroupId == null) return false;
          // Si groupId es un objeto populado (con _id, title, etc.)
          final nodeGroupIdStr = nodeGroupId is Map
              ? (nodeGroupId['_id'] ?? nodeGroupId['id'])?.toString() ?? ''
              : nodeGroupId.toString();
          return nodeGroupIdStr == groupIdStr && (node['level'] ?? 1) == level;
        })
        .map<Map<String, dynamic>>((node) => Map<String, dynamic>.from(node))
        .toList()
      ..sort((a, b) {
        final posA = (a['positionIndex'] ?? 1) as int;
        final posB = (b['positionIndex'] ?? 1) as int;
        return posA.compareTo(posB);
      });
  }

  List<Map<String, dynamic>> _nodesForLevel(int level) {
    final levelNodes = _nodes
        .where((node) => (node['level'] ?? 1) == level)
        .map<Map<String, dynamic>>((node) => Map<String, dynamic>.from(node))
        .toList();
    levelNodes.sort((a, b) {
      final posA = (a['positionIndex'] ?? 1) as int;
      final posB = (b['positionIndex'] ?? 1) as int;
      return posA.compareTo(posB);
    });
    return levelNodes;
  }

  Future<void> _reorderLevelNodes(int level, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final levelNodes = _nodesForLevel(level);
    final moved = levelNodes.removeAt(oldIndex);
    levelNodes.insert(newIndex, moved);

    final updates = <Map<String, dynamic>>[];
    for (var i = 0; i < levelNodes.length; i += 1) {
      updates.add({
        'nodeId': levelNodes[i]['_id'] ?? levelNodes[i]['id'],
        'level': level,
        'positionIndex': i + 1,
      });
    }

    try {
      await ApiService.adminReorderContentNodes(_selectedPathId!, updates);
      await _loadContent(_selectedPathId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reordenando: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _buildReorderUpdates(
    List<Map<String, dynamic>> nodes,
    int level,
  ) {
    return List.generate(nodes.length, (index) {
      final node = nodes[index];
      return {
        'nodeId': node['_id'] ?? node['id'],
        'level': level,
        'positionIndex': index + 1,
      };
    });
  }

  Future<void> _applyNodeDrop({
    required Map<String, dynamic> dragged,
    required String targetGroupId,
    required int targetLevel,
    required int targetIndex,
  }) async {
    if (_selectedPathId == null) return;

    final draggedId = (dragged['_id'] ?? dragged['id']).toString();
    final currentGroupId = (dragged['groupId']?.toString() ?? '');
    final currentLevel = (dragged['level'] ?? 1) as int;

    final currentTargetNodes = _nodesForGroupAndLevel(
      targetGroupId,
      targetLevel,
    );
    var adjustedTargetIndex = targetIndex;
    if (currentGroupId == targetGroupId && currentLevel == targetLevel) {
      final draggedIndex = currentTargetNodes.indexWhere(
        (node) => (node['_id'] ?? node['id']).toString() == draggedId,
      );
      if (draggedIndex != -1 && draggedIndex < adjustedTargetIndex) {
        adjustedTargetIndex = adjustedTargetIndex - 1;
      }
    }

    final targetNodes = currentTargetNodes
        .where((node) => (node['_id'] ?? node['id']).toString() != draggedId)
        .toList();
    final insertIndex = adjustedTargetIndex.clamp(0, targetNodes.length);
    targetNodes.insert(insertIndex, Map<String, dynamic>.from(dragged));

    final updates = <Map<String, dynamic>>[];
    updates.addAll(_buildReorderUpdates(targetNodes, targetLevel));

    final movedAcrossGroup = currentGroupId != targetGroupId;
    final movedAcrossLevel = currentLevel != targetLevel;

    if (movedAcrossGroup || movedAcrossLevel) {
      await ApiService.adminUpdateContentNode(draggedId, {
        'groupId': targetGroupId,
        'level': targetLevel,
      });

      final sourceNodes = _nodesForGroupAndLevel(currentGroupId, currentLevel)
          .where((node) => (node['_id'] ?? node['id']).toString() != draggedId)
          .toList();
      updates.addAll(_buildReorderUpdates(sourceNodes, currentLevel));
    }

    await ApiService.adminReorderContentNodes(_selectedPathId!, updates);
    await _loadContent(_selectedPathId!);
  }

  Future<void> _saveGroup() async {
    if (_selectedItem == null) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.adminUpdateGroup(
        _selectedItem['_id'] ?? _selectedItem['id'],
        {
          'title': _groupTitleCtrl.text.trim(),
          'order': int.tryParse(_groupOrderCtrl.text) ?? 1,
        },
      );
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardando grupo: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _reorderGroups(int oldIndex, int newIndex) async {
    if (_selectedPathId == null) return;
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || newIndex < 0) return;
    if (oldIndex >= _groups.length || newIndex >= _groups.length) return;

    setState(() => _isSaving = true);
    try {
      // Obtener los grupos a intercambiar
      final group1 = _groups[oldIndex];
      final group2 = _groups[newIndex];

      final group1Id = group1['_id'] ?? group1['id'];
      final group2Id = group2['_id'] ?? group2['id'];

      final group1Order = group1['order'] ?? (oldIndex + 1);
      final group2Order = group2['order'] ?? (newIndex + 1);

      // Intercambiar los valores de order
      await ApiService.adminUpdateGroup(group1Id, {'order': group2Order});
      await ApiService.adminUpdateGroup(group2Id, {'order': group1Order});

      // Recargar contenido
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ Grupos reordenados')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reordenando grupos: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _openCreateGroupDialog() async {
    if (_selectedPathId == null) return;
    final titleCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titulo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden'),
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final response = await ApiService.adminCreateGroup(_selectedPathId!, {
        'title': titleCtrl.text.trim(),
        'order': int.tryParse(orderCtrl.text) ?? 1,
      });
      final group = response['group'] ?? response;
      await _loadContent(_selectedPathId!);
      if (mounted && group is Map) {
        _selectGroup(group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creando grupo: $e')));
      }
    }
  }

  Future<void> _saveNode() async {
    if (_selectedNode == null) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.adminUpdateContentNode(
        _selectedNode['_id'] ?? _selectedNode['id'],
        {
          'title': _nodeTitleCtrl.text.trim(),
          'type': _nodeType,
          'status': _nodeStatus,
          'level': int.tryParse(_nodeLevelCtrl.text) ?? 1,
          'positionIndex': int.tryParse(_nodePositionCtrl.text) ?? 1,
          'xpReward': int.tryParse(_nodeXpCtrl.text) ?? 0,
          'isLockedByDefault': _nodeLockedByDefault,
        },
      );
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardando nodo: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleNodeDefaultLock(Map<String, dynamic> node) async {
    final nodeId = (node['_id'] ?? node['id'])?.toString();
    if (nodeId == null || nodeId.isEmpty) return;

    final currentValue = node['isLockedByDefault'] != false;

    try {
      await ApiService.adminUpdateContentNode(nodeId, {
        'isLockedByDefault': !currentValue,
      });

      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }

      if (_selectedNode != null) {
        final selectedId = (_selectedNode['_id'] ?? _selectedNode['id'])
            ?.toString();
        if (selectedId == nodeId) {
          _selectNodeById(nodeId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando candado: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup(dynamic group) async {
    final groupId = group['_id'] ?? group['id'];
    final groupTitle = group['title'] ?? 'Sin titulo';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: Text(
          '¿Estas seguro de eliminar el grupo "$groupTitle"?\n\nEsto eliminara todos los nodos dentro del grupo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.adminDeleteGroup(groupId);
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ Grupo eliminado')));
      }
      // Clear selection
      setState(() {
        _selectedItem = null;
        _selectedType = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error eliminando grupo: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNode(dynamic node) async {
    final nodeId = node['_id'] ?? node['id'];
    final nodeTitle = node['title'] ?? 'Sin titulo';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Nodo'),
        content: Text(
          '¿Estas seguro de eliminar el nodo "$nodeTitle"?\n\nEsto eliminara todos los pasos y cards asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.adminDeleteContentNode(nodeId);
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ Nodo eliminado')));
      }
      // Clear selection
      setState(() {
        _selectedItem = null;
        _selectedType = null;
        _selectedNode = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error eliminando nodo: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _openStepDialog({Map<String, dynamic>? step}) async {
    if (_selectedNode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes seleccionar un nodo primero'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StepEditorDialog(
        step: step,
        stepIndex: (_currentSteps().length + 1),
      ),
    );

    if (result == null) return;

    setState(() => _isSaving = true);

    try {
      final nodeId = _selectedNode['_id'] ?? _selectedNode['id'];

      if (step == null) {
        await ApiService.adminAddNodeStep(nodeId, result);
      } else {
        await ApiService.adminUpdateNodeStep(
          nodeId,
          step['_id'] ?? step['id'],
          result,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              step == null
                  ? '✅ Paso creado exitosamente'
                  : '✅ Paso actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (_selectedPathId != null && mounted) {
        await _loadContent(_selectedPathId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error guardando paso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteStep(Map<String, dynamic> step) async {
    if (_selectedNode == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar paso'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.adminDeleteNodeStep(
        _selectedNode['_id'] ?? _selectedNode['id'],
        step['_id'] ?? step['id'],
      );
      _selectStep(null);
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Paso eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error eliminando paso: $e')));
      }
    }
  }

  Future<void> _openCardDialog({Map<String, dynamic>? card}) async {
    if (_selectedNode == null || _selectedStep == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Selecciona un paso primero'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CardEditorDialog(
        card: card,
        cardIndex: (_selectedStep?['cards'] as List? ?? []).length + 1,
      ),
    );

    if (result == null) return;

    setState(() => _isSaving = true);

    try {
      final nodeId = _selectedNode['_id'] ?? _selectedNode['id'];
      final stepId = _selectedStep!['_id'] ?? _selectedStep!['id'];

      if (card == null) {
        await ApiService.adminAddStepCard(nodeId, stepId, result);
      } else {
        await ApiService.adminUpdateStepCard(
          nodeId,
          stepId,
          card['_id'] ?? card['id'],
          result,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              card == null
                  ? '✅ Card creada exitosamente'
                  : '✅ Card actualizada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (_selectedPathId != null && mounted) {
        await _loadContent(_selectedPathId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error guardando card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    if (_selectedNode == null || _selectedStep == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.adminDeleteStepCard(
        _selectedNode['_id'] ?? _selectedNode['id'],
        _selectedStep!['_id'] ?? _selectedStep!['id'],
        card['_id'] ?? card['id'],
      );

      setState(() => _selectedCard = null);
      if (_selectedPathId != null) {
        await _loadContent(_selectedPathId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Tarjeta eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error eliminando tarjeta: $e')));
      }
    }
  }

  int _totalCardCount(List<Map<String, dynamic>> steps) {
    var total = 0;
    for (final step in steps) {
      final cards = step['cards'];
      if (cards is List) {
        total += cards.length;
      }
    }
    return total;
  }

  Widget _buildRelationChips(Map<String, dynamic> item) {
    final chips = <Widget>[];
    final type = item['type']?.toString();
    final status = item['status']?.toString();
    final level = item['level']?.toString();
    final path = item['pathId'] as Map?;
    final pathTitle = path?['title']?.toString();

    if (type != null && type.isNotEmpty) {
      chips.add(Chip(label: Text(type)));
    }
    if (status != null && status.isNotEmpty) {
      chips.add(Chip(label: Text(status)));
    }
    if (level != null && level.isNotEmpty) {
      chips.add(Chip(label: Text('L$level')));
    }
    if (pathTitle != null && pathTitle.isNotEmpty) {
      chips.add(Chip(label: Text(pathTitle)));
    }

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _buildRelationSection(String title, List<dynamic> items) {
    if (items.isEmpty) {
      return Text('$title: 0');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${items.length}'),
        const SizedBox(height: 6),
        ...items.map((item) {
          final relation = item as Map<String, dynamic>;
          return InkWell(
            onTap: () => _openNodeFromRelation(relation),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relation['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _buildRelationChips(relation),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getCardTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return '📝';
      case 'list':
        return '📋';
      case 'image':
        return '🖼️';
      case 'video':
        return '🎥';
      case 'animation':
        return '🎬';
      case 'quiz':
        return '❓';
      case 'timer':
        return '⏱️';
      default:
        return '📌';
    }
  }

  String _getCardPreviewContent(Map<String, dynamic> card) {
    final type = card['type'] ?? 'unknown';
    final data = card['data'] as Map? ?? {};

    switch (type) {
      case 'text':
        final text = (data['text'] ?? '').toString();
        return text.length > 40 ? '${text.substring(0, 40)}...' : text;
      case 'list':
        final items = data['items'] as List? ?? [];
        return '${items.length} items';
      case 'image':
      case 'video':
      case 'animation':
        return (data['url'] ?? 'Sin URL').toString();
      case 'quiz':
        final question = (data['question'] ?? '').toString();
        return question.length > 40
            ? '${question.substring(0, 40)}...'
            : question;
      case 'timer':
        final duration = data['duration'] ?? 0;
        return '$duration segundos';
      default:
        return type;
    }
  }

  Widget _buildCardPreview(
    Map<String, dynamic> card,
    int index,
    bool isSelected,
  ) {
    final type = card['type'] ?? 'unknown';
    final preview = _getCardPreviewContent(card);
    final icon = _getCardTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade100 : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.purple.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCard(card),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Type circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Card $index',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openCardDialog(card: card);
                    } else if (value == 'delete') {
                      _deleteCard(card);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moveNodeToLevel(
    Map<String, dynamic> node,
    int targetLevel,
  ) async {
    final currentLevel = (node['level'] ?? 1) as int;
    if (currentLevel == targetLevel) return;
    if (_selectedPathId == null) return;

    final nodeId = node['_id'] ?? node['id'];
    if (nodeId == null) return;

    final targetNodes = _nodesForLevel(targetLevel);
    final nextPosition = targetNodes.length + 1;

    try {
      await ApiService.adminUpdateContentNode(nodeId, {
        'level': targetLevel,
        'positionIndex': nextPosition,
      });
      await _loadContent(_selectedPathId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error moviendo nodo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildParallelLevelRows(
      _nodes
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
    final steps = _currentSteps();
    final cards = _currentCards();
    final ungroupedNodes = _nodesWithoutGroup();

    return Container(
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPathId,
                      items: _paths
                          .map(
                            (path) => DropdownMenuItem(
                              value:
                                  path['_id']?.toString() ??
                                  path['id']?.toString(),
                              child: Text(path['title'] ?? 'Sin titulo'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedPathId = value;
                          _selectedItem = null;
                          _selectedType = null;
                          _selectedNode = null;
                          _selectedStep = null;
                          _selectedCard = null;
                        });
                        _loadContent(value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Camino',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Scrollbar(
                            controller: _treeScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _treeScrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Grupos y Nodos',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${_groups.length} grupo${_groups.length != 1 ? 's' : ''}, ${_nodes.length} nodo${_nodes.length != 1 ? 's' : ''})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _selectedPathId == null
                                              ? null
                                              : () => _showCreateNodeDialog(
                                                  _selectedPathId!,
                                                ),
                                          icon: const Icon(
                                            Icons.add_circle,
                                            size: 18,
                                          ),
                                          tooltip: 'Crear Nodo',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: _selectedPathId == null
                                              ? null
                                              : _openCreateGroupDialog,
                                          icon: const Icon(
                                            Icons.create_new_folder,
                                            size: 18,
                                          ),
                                          tooltip: 'Crear grupo',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_groups.isEmpty && ungroupedNodes.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 40,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.folder_off,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sin grupos',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextButton(
                                            onPressed: _openCreateGroupDialog,
                                            child: const Text(
                                              'Crear primer grupo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (_groups.isEmpty)
                                  _buildUngroupedSection(ungroupedNodes)
                                else
                                  ..._groups.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final group = entry.value;
                                    final groupId = group['_id'] ?? group['id'];
                                    final groupTitle =
                                        group['title'] ?? 'Sin titulo';
                                    final nodesInGroup = _nodesForGroup(
                                      groupId,
                                    );
                                    final levelsInGroup = _levelsForGroup(
                                      groupId,
                                    );

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            border: Border(
                                              left: BorderSide(
                                                color: Colors.blue.shade400,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      groupTitle,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    if (nodesInGroup.isNotEmpty)
                                                      Text(
                                                        '${nodesInGroup.length} nodo${nodesInGroup.length != 1 ? 's' : ''}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: () =>
                                                        _showCreateNodeDialog(
                                                          _selectedPathId!,
                                                          defaultGroupId:
                                                              groupId
                                                                  ?.toString(),
                                                        ),
                                                    icon: const Icon(
                                                      Icons.add,
                                                      size: 16,
                                                    ),
                                                    tooltip:
                                                        'Agregar nodo a este grupo',
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28,
                                                        ),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.green.shade100,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  PopupMenuButton<String>(
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _selectGroup(group);
                                                      } else if (value ==
                                                          'delete') {
                                                        _deleteGroup(group);
                                                      } else if (value ==
                                                          'import') {
                                                        _openImportNodeDialog(
                                                          defaultGroupId:
                                                              groupId
                                                                  ?.toString(),
                                                        );
                                                      } else if (value ==
                                                          'moveUp') {
                                                        _reorderGroups(
                                                          index,
                                                          index - 1,
                                                        );
                                                      } else if (value ==
                                                          'moveDown') {
                                                        _reorderGroups(
                                                          index,
                                                          index + 1,
                                                        );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'import',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .file_download,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Importar nodo',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuDivider(),
                                                      if (index > 0)
                                                        const PopupMenuItem(
                                                          value: 'moveUp',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .arrow_upward,
                                                                size: 16,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Mover arriba',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (index <
                                                          _groups.length - 1)
                                                        const PopupMenuItem(
                                                          value: 'moveDown',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .arrow_downward,
                                                                size: 16,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Mover abajo',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      const PopupMenuDivider(),
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.edit,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text('Editar'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.delete,
                                                              size: 16,
                                                              color: Colors.red,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Eliminar',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    child: const Icon(
                                                      Icons.more_vert,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (nodesInGroup.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'Sin nodos',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        else
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: levelsInGroup
                                                  .expand((level) {
                                                    final levelNodes =
                                                        _nodesForGroupAndLevel(
                                                          groupId,
                                                          level,
                                                        );
                                                    return [
                                                      DragTarget<
                                                        Map<String, dynamic>
                                                      >(
                                                        onWillAccept: (data) {
                                                          if (data == null)
                                                            return false;
                                                          final current =
                                                              (data['level'] ??
                                                                      1)
                                                                  as int;
                                                          final currentGroupId =
                                                              (data['groupId']
                                                                  ?.toString() ??
                                                              '');
                                                          return currentGroupId !=
                                                                  groupId
                                                                      .toString() ||
                                                              current != level;
                                                        },
                                                        onAccept: (data) async {
                                                          await _applyNodeDrop(
                                                            dragged: data,
                                                            targetGroupId:
                                                                groupId
                                                                    .toString(),
                                                            targetLevel: level,
                                                            targetIndex:
                                                                (levelNodes ??
                                                                        [])
                                                                    .length,
                                                          );
                                                        },
                                                        builder:
                                                            (
                                                              context,
                                                              candidate,
                                                              rejected,
                                                            ) {
                                                              final isActive =
                                                                  candidate
                                                                      .isNotEmpty;
                                                              return Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          6,
                                                                      horizontal:
                                                                          8,
                                                                    ),
                                                                margin:
                                                                    const EdgeInsets.only(
                                                                      bottom: 6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      isActive
                                                                      ? Colors
                                                                            .orange
                                                                            .shade50
                                                                      : Colors
                                                                            .transparent,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                  border: Border.all(
                                                                    color:
                                                                        isActive
                                                                        ? Colors
                                                                              .orange
                                                                              .shade200
                                                                        : Colors
                                                                              .transparent,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'Nivel $level',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        isActive
                                                                        ? Colors
                                                                              .orange
                                                                              .shade700
                                                                        : Colors
                                                                              .black54,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                      const SizedBox(height: 4),
                                                      ...(levelNodes ?? []).asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        final index = entry.key;
                                                        final node =
                                                            entry.value;
                                                        return DragTarget<
                                                          Map<String, dynamic>
                                                        >(
                                                          onWillAccept: (data) {
                                                            if (data == null)
                                                              return false;
                                                            final draggedId =
                                                                (data['_id'] ??
                                                                        data['id'])
                                                                    .toString();
                                                            final targetId =
                                                                (node['_id'] ??
                                                                        node['id'])
                                                                    .toString();
                                                            return draggedId !=
                                                                targetId;
                                                          },
                                                          onAccept: (data) async {
                                                            await _applyNodeDrop(
                                                              dragged: data,
                                                              targetGroupId:
                                                                  groupId
                                                                      .toString(),
                                                              targetLevel:
                                                                  level,
                                                              targetIndex:
                                                                  index,
                                                            );
                                                          },
                                                          builder:
                                                              (
                                                                context,
                                                                candidate,
                                                                rejected,
                                                              ) {
                                                                final isActive =
                                                                    candidate
                                                                        .isNotEmpty;
                                                                return Column(
                                                                  children: [
                                                                    AnimatedContainer(
                                                                      duration: const Duration(
                                                                        milliseconds:
                                                                            120,
                                                                      ),
                                                                      height:
                                                                          isActive
                                                                          ? 6
                                                                          : 0,
                                                                      margin: const EdgeInsets.only(
                                                                        bottom:
                                                                            4,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .orange
                                                                            .shade300,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                        border: Border.all(
                                                                          color:
                                                                              isActive
                                                                              ? Colors.orange.shade300
                                                                              : Colors.transparent,
                                                                          width:
                                                                              isActive
                                                                              ? 2
                                                                              : 0,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Draggable<
                                                                            Map<
                                                                              String,
                                                                              dynamic
                                                                            >
                                                                          >(
                                                                            data:
                                                                                Map<
                                                                                  String,
                                                                                  dynamic
                                                                                >.from(
                                                                                  node,
                                                                                ),
                                                                            feedback: Material(
                                                                              elevation: 8,
                                                                              color: Colors.blue.shade50,
                                                                              borderRadius: BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                              child: Container(
                                                                                padding: const EdgeInsets.symmetric(
                                                                                  horizontal: 16,
                                                                                  vertical: 12,
                                                                                ),
                                                                                constraints: const BoxConstraints(
                                                                                  maxWidth: 250,
                                                                                ),
                                                                                child: Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Icon(
                                                                                      Icons.drag_indicator,
                                                                                      size: 16,
                                                                                      color: Colors.blue.shade700,
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      width: 8,
                                                                                    ),
                                                                                    Flexible(
                                                                                      child: Text(
                                                                                        node['title'] ??
                                                                                            'Sin titulo',
                                                                                        style: TextStyle(
                                                                                          fontSize: 13,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          color: Colors.blue.shade900,
                                                                                        ),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            childWhenDragging: Opacity(
                                                                              opacity: 0.3,
                                                                              child: Container(
                                                                                margin: const EdgeInsets.only(
                                                                                  bottom: 4,
                                                                                ),
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.grey.shade200,
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    8,
                                                                                  ),
                                                                                  border: Border.all(
                                                                                    color: Colors.grey.shade300,
                                                                                    width: 2,
                                                                                    style: BorderStyle.solid,
                                                                                  ),
                                                                                ),
                                                                                child: ListTile(
                                                                                  contentPadding: const EdgeInsets.symmetric(
                                                                                    horizontal: 8,
                                                                                    vertical: 4,
                                                                                  ),
                                                                                  dense: true,
                                                                                  leading: const Icon(
                                                                                    Icons.drag_indicator,
                                                                                    size: 16,
                                                                                    color: Colors.grey,
                                                                                  ),
                                                                                  title: Text(
                                                                                    node['title'] ??
                                                                                        'Sin titulo',
                                                                                    style: const TextStyle(
                                                                                      fontSize: 12,
                                                                                    ),
                                                                                  ),
                                                                                  subtitle: Text(
                                                                                    'Pos ${node['positionIndex'] ?? 1}',
                                                                                    style: const TextStyle(
                                                                                      fontSize: 10,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            child: Container(
                                                                              margin: const EdgeInsets.only(
                                                                                bottom: 4,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color:
                                                                                    _selectedItem ==
                                                                                        node
                                                                                    ? Colors.blue.shade50
                                                                                    : Colors.white,
                                                                                borderRadius: BorderRadius.circular(
                                                                                  8,
                                                                                ),
                                                                                border: Border.all(
                                                                                  color:
                                                                                      _selectedItem ==
                                                                                          node
                                                                                      ? Colors.blue.shade300
                                                                                      : Colors.grey.shade200,
                                                                                  width:
                                                                                      _selectedItem ==
                                                                                          node
                                                                                      ? 2
                                                                                      : 1,
                                                                                ),
                                                                                boxShadow: [
                                                                                  BoxShadow(
                                                                                    color: Colors.black.withOpacity(
                                                                                      0.05,
                                                                                    ),
                                                                                    blurRadius: 2,
                                                                                    offset: const Offset(
                                                                                      0,
                                                                                      1,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              child: Builder(
                                                                                builder:
                                                                                    (
                                                                                      context,
                                                                                    ) {
                                                                                      final nodeId =
                                                                                          (node['_id'] ??
                                                                                                  node['id'])
                                                                                              .toString();
                                                                                      final isExpandedNode =
                                                                                          _expandedNodeId ==
                                                                                          nodeId;
                                                                                      final nodeSteps =
                                                                                          node['steps']
                                                                                              is List
                                                                                          ? List<
                                                                                              Map<
                                                                                                String,
                                                                                                dynamic
                                                                                              >
                                                                                            >.from(
                                                                                              node['steps'],
                                                                                            )
                                                                                          : <
                                                                                              Map<
                                                                                                String,
                                                                                                dynamic
                                                                                              >
                                                                                            >[];
                                                                                      return Column(
                                                                                        children: [
                                                                                          Builder(
                                                                                            builder:
                                                                                                (
                                                                                                  context,
                                                                                                ) {
                                                                                                  final isLockedByDefault =
                                                                                                      node['isLockedByDefault'] !=
                                                                                                      false;
                                                                                                  return ListTile(
                                                                                                    contentPadding: const EdgeInsets.symmetric(
                                                                                                      horizontal: 8,
                                                                                                      vertical: 4,
                                                                                                    ),
                                                                                                    dense: true,
                                                                                                    leading: Icon(
                                                                                                      Icons.drag_indicator,
                                                                                                      size: 16,
                                                                                                      color: Colors.grey.shade400,
                                                                                                    ),
                                                                                                    title: Text(
                                                                                                      node['title'] ??
                                                                                                          'Sin titulo',
                                                                                                      style: const TextStyle(
                                                                                                        fontSize: 12,
                                                                                                      ),
                                                                                                    ),
                                                                                                    subtitle: Row(
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          'Pos ${node['positionIndex'] ?? 1}',
                                                                                                          style: const TextStyle(
                                                                                                            fontSize: 10,
                                                                                                          ),
                                                                                                        ),
                                                                                                        const SizedBox(
                                                                                                          width: 8,
                                                                                                        ),
                                                                                                        Icon(
                                                                                                          isLockedByDefault
                                                                                                              ? Icons.lock
                                                                                                              : Icons.lock_open,
                                                                                                          size: 12,
                                                                                                          color: isLockedByDefault
                                                                                                              ? Colors.red.shade400
                                                                                                              : Colors.green.shade600,
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                    onTap: () {
                                                                                                      if (isExpandedNode) {
                                                                                                        setState(
                                                                                                          () {
                                                                                                            _expandedNodeId = null;
                                                                                                          },
                                                                                                        );
                                                                                                      } else {
                                                                                                        _selectNode(
                                                                                                          node,
                                                                                                        );
                                                                                                        setState(
                                                                                                          () {
                                                                                                            _expandedNodeId = nodeId;
                                                                                                          },
                                                                                                        );
                                                                                                      }
                                                                                                    },
                                                                                                    selected:
                                                                                                        _selectedItem ==
                                                                                                        node,
                                                                                                    trailing: Row(
                                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                                      children: [
                                                                                                        IconButton(
                                                                                                          tooltip: isLockedByDefault
                                                                                                              ? 'Desactivar candado inicial'
                                                                                                              : 'Activar candado inicial',
                                                                                                          icon: Icon(
                                                                                                            isLockedByDefault
                                                                                                                ? Icons.lock
                                                                                                                : Icons.lock_open,
                                                                                                            size: 16,
                                                                                                            color: isLockedByDefault
                                                                                                                ? Colors.red.shade400
                                                                                                                : Colors.green.shade600,
                                                                                                          ),
                                                                                                          onPressed: () => _toggleNodeDefaultLock(
                                                                                                            node,
                                                                                                          ),
                                                                                                        ),
                                                                                                        PopupMenuButton<
                                                                                                          String
                                                                                                        >(
                                                                                                          onSelected:
                                                                                                              (
                                                                                                                value,
                                                                                                              ) {
                                                                                                                if (value ==
                                                                                                                    'addStep') {
                                                                                                                  _selectNode(
                                                                                                                    node,
                                                                                                                  );
                                                                                                                  setState(
                                                                                                                    () {
                                                                                                                      _expandedNodeId = nodeId;
                                                                                                                    },
                                                                                                                  );
                                                                                                                  _openStepDialog();
                                                                                                                } else if (value ==
                                                                                                                    'delete') {
                                                                                                                  _deleteNode(
                                                                                                                    node,
                                                                                                                  );
                                                                                                                }
                                                                                                              },
                                                                                                          itemBuilder:
                                                                                                              (
                                                                                                                context,
                                                                                                              ) => const [
                                                                                                                PopupMenuItem(
                                                                                                                  value: 'addStep',
                                                                                                                  child: Row(
                                                                                                                    children: [
                                                                                                                      Icon(
                                                                                                                        Icons.add,
                                                                                                                        size: 14,
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: 8,
                                                                                                                      ),
                                                                                                                      Text(
                                                                                                                        'Agregar paso',
                                                                                                                        style: TextStyle(
                                                                                                                          fontSize: 11,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                ),
                                                                                                                PopupMenuItem(
                                                                                                                  value: 'delete',
                                                                                                                  child: Row(
                                                                                                                    children: [
                                                                                                                      Icon(
                                                                                                                        Icons.delete,
                                                                                                                        size: 14,
                                                                                                                        color: Colors.red,
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: 8,
                                                                                                                      ),
                                                                                                                      Text(
                                                                                                                        'Eliminar',
                                                                                                                        style: TextStyle(
                                                                                                                          color: Colors.red,
                                                                                                                          fontSize: 11,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                          child: const Icon(
                                                                                                            Icons.more_vert,
                                                                                                            size: 16,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                          ),
                                                                                          if (isExpandedNode)
                                                                                            Padding(
                                                                                              padding: const EdgeInsets.only(
                                                                                                left: 20,
                                                                                                right: 8,
                                                                                                bottom: 8,
                                                                                              ),
                                                                                              child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  Row(
                                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                    children: [
                                                                                                      Text(
                                                                                                        'Pasos',
                                                                                                        style: TextStyle(
                                                                                                          fontSize: 11,
                                                                                                          fontWeight: FontWeight.w600,
                                                                                                          color: Colors.grey.shade700,
                                                                                                        ),
                                                                                                      ),
                                                                                                      TextButton.icon(
                                                                                                        onPressed: () {
                                                                                                          _selectNode(
                                                                                                            node,
                                                                                                          );
                                                                                                          _openStepDialog();
                                                                                                        },
                                                                                                        icon: const Icon(
                                                                                                          Icons.add,
                                                                                                          size: 14,
                                                                                                        ),
                                                                                                        label: const Text(
                                                                                                          'Agregar',
                                                                                                          style: TextStyle(
                                                                                                            fontSize: 11,
                                                                                                          ),
                                                                                                        ),
                                                                                                        style: TextButton.styleFrom(
                                                                                                          padding: EdgeInsets.zero,
                                                                                                          minimumSize: const Size(
                                                                                                            0,
                                                                                                            0,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                  const SizedBox(
                                                                                                    height: 4,
                                                                                                  ),
                                                                                                  if (nodeSteps.isEmpty)
                                                                                                    Text(
                                                                                                      'Sin pasos',
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 11,
                                                                                                        color: Colors.grey.shade500,
                                                                                                      ),
                                                                                                    )
                                                                                                  else
                                                                                                    ...nodeSteps.asMap().entries.map(
                                                                                                      (
                                                                                                        stepEntry,
                                                                                                      ) {
                                                                                                        final stepIdx = stepEntry.key;
                                                                                                        final step = stepEntry.value;
                                                                                                        final stepCards = _getStepCards(
                                                                                                          step,
                                                                                                        );
                                                                                                        final isExpandedStep =
                                                                                                            _selectedStep ==
                                                                                                            step;
                                                                                                        return Container(
                                                                                                          margin: const EdgeInsets.only(
                                                                                                            bottom: 6,
                                                                                                          ),
                                                                                                          decoration: BoxDecoration(
                                                                                                            color: Colors.grey.shade50,
                                                                                                            borderRadius: BorderRadius.circular(
                                                                                                              6,
                                                                                                            ),
                                                                                                            border: Border.all(
                                                                                                              color: Colors.grey.shade200,
                                                                                                            ),
                                                                                                          ),
                                                                                                          child: ExpansionTile(
                                                                                                            tilePadding: const EdgeInsets.symmetric(
                                                                                                              horizontal: 8,
                                                                                                              vertical: 0,
                                                                                                            ),
                                                                                                            childrenPadding: const EdgeInsets.only(
                                                                                                              left: 8,
                                                                                                              right: 8,
                                                                                                              bottom: 8,
                                                                                                            ),
                                                                                                            initiallyExpanded: isExpandedStep,
                                                                                                            onExpansionChanged:
                                                                                                                (
                                                                                                                  _,
                                                                                                                ) {
                                                                                                                  _selectNode(
                                                                                                                    node,
                                                                                                                  );
                                                                                                                  _selectStep(
                                                                                                                    step,
                                                                                                                  );
                                                                                                                },
                                                                                                            title: Text(
                                                                                                              '${stepIdx + 1}. ${step['title'] ?? 'Sin titulo'}',
                                                                                                              style: const TextStyle(
                                                                                                                fontSize: 11,
                                                                                                              ),
                                                                                                            ),
                                                                                                            trailing: IconButton(
                                                                                                              icon: const Icon(
                                                                                                                Icons.add,
                                                                                                                size: 16,
                                                                                                              ),
                                                                                                              tooltip: 'Agregar card',
                                                                                                              onPressed: () {
                                                                                                                _selectNode(
                                                                                                                  node,
                                                                                                                );
                                                                                                                _selectStep(
                                                                                                                  step,
                                                                                                                );
                                                                                                                _openCardDialog();
                                                                                                              },
                                                                                                            ),
                                                                                                            children: [
                                                                                                              if (stepCards.isEmpty)
                                                                                                                Text(
                                                                                                                  'Sin cards',
                                                                                                                  style: TextStyle(
                                                                                                                    fontSize: 11,
                                                                                                                    color: Colors.grey.shade500,
                                                                                                                  ),
                                                                                                                )
                                                                                                              else
                                                                                                                Column(
                                                                                                                  children: stepCards.asMap().entries.map(
                                                                                                                    (
                                                                                                                      cardEntry,
                                                                                                                    ) {
                                                                                                                      final cardIdx = cardEntry.key;
                                                                                                                      final card =
                                                                                                                          cardEntry.value
                                                                                                                              as Map<
                                                                                                                                String,
                                                                                                                                dynamic
                                                                                                                              >;
                                                                                                                      return Padding(
                                                                                                                        padding: const EdgeInsets.only(
                                                                                                                          bottom: 6,
                                                                                                                        ),
                                                                                                                        child: _buildCardPreview(
                                                                                                                          card,
                                                                                                                          cardIdx +
                                                                                                                              1,
                                                                                                                          _selectedCard ==
                                                                                                                              card,
                                                                                                                        ),
                                                                                                                      );
                                                                                                                    },
                                                                                                                  ).toList(),
                                                                                                                ),
                                                                                                            ],
                                                                                                          ),
                                                                                                        );
                                                                                                      },
                                                                                                    ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                              ),
                                                                            ),
                                                                          ),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                        );
                                                      }).toList(),
                                                      DragTarget<
                                                        Map<String, dynamic>
                                                      >(
                                                        onWillAccept: (data) {
                                                          return data != null;
                                                        },
                                                        onAccept: (data) async {
                                                          await _applyNodeDrop(
                                                            dragged: data,
                                                            targetGroupId:
                                                                groupId
                                                                    .toString(),
                                                            targetLevel: level,
                                                            targetIndex:
                                                                (levelNodes ??
                                                                        [])
                                                                    .length,
                                                          );
                                                        },
                                                        builder:
                                                            (
                                                              context,
                                                              candidate,
                                                              rejected,
                                                            ) {
                                                              final isActive =
                                                                  candidate
                                                                      .isNotEmpty;
                                                              return Container(
                                                                height: 8,
                                                                margin:
                                                                    const EdgeInsets.only(
                                                                      bottom: 6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      isActive
                                                                      ? Colors
                                                                            .orange
                                                                            .shade100
                                                                      : Colors
                                                                            .transparent,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                      const SizedBox(height: 8),
                                                    ];
                                                  })
                                                  .toList()
                                                  .cast<Widget>(),
                                            ),
                                          ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }),
                                if (_groups.isNotEmpty &&
                                    ungroupedNodes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _buildUngroupedSection(
                                      ungroupedNodes,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                if (_selectedNode != null) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Pasos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _openStepDialog(),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Agregar paso'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...steps.asMap().entries.map((entry) {
                                    final stepIdx = entry.key;
                                    final step =
                                        entry.value as Map<String, dynamic>;
                                    final stepCards = _getStepCards(step);
                                    final isExpandedStep =
                                        _selectedStep == step;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isExpandedStep
                                              ? Colors.blue.shade400
                                              : Colors.grey.shade200,
                                          width: isExpandedStep ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: isExpandedStep
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                      ),
                                      child: ExpansionTile(
                                        initiallyExpanded: isExpandedStep,
                                        onExpansionChanged: (_) =>
                                            _selectStep(step),
                                        title: Text(
                                          '${stepIdx + 1}. ${step['title'] ?? 'Sin titulo'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${stepCards.length} tarjeta${stepCards.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _openStepDialog(step: step);
                                            } else if (value == 'delete') {
                                              _deleteStep(step);
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Editar'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Cards section
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Tarjetas (Cards)',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        _selectStep(step);
                                                        _openCardDialog();
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 14,
                                                      ),
                                                      label: const Text(
                                                        'Agregar',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .purple
                                                            .shade600,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 5,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                if (stepCards.isEmpty)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Sin tarjetas. Agrega una para empezar.',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black54,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Column(
                                                    children: stepCards
                                                        .asMap()
                                                        .entries
                                                        .map((cardEntry) {
                                                          final cardIdx =
                                                              cardEntry.key;
                                                          final card =
                                                              cardEntry.value
                                                                  as Map<
                                                                    String,
                                                                    dynamic
                                                                  >;
                                                          final isSelectedCard =
                                                              _selectedCard ==
                                                              card;
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            child:
                                                                _buildCardPreview(
                                                                  card,
                                                                  cardIdx + 1,
                                                                  isSelectedCard,
                                                                ),
                                                          );
                                                        })
                                                        .toList(),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Editor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _selectedItem == null
                      ? const Center(
                          child: Text(
                            'Selecciona un elemento para editar',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedType == 'group') ...[
                                TextField(
                                  controller: _groupTitleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Titulo del grupo',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _groupOrderCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Orden',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _saveGroup,
                                  child: Text(
                                    _isSaving
                                        ? 'Guardando...'
                                        : 'Guardar cambios',
                                  ),
                                ),
                              ],
                              if (_selectedType == 'node') ...[
                                TextField(
                                  controller: _nodeTitleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Titulo del nodo',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _nodeType,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'recipe',
                                      child: Text('Recipe'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'explanation',
                                      child: Text('Explanation'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'tips',
                                      child: Text('Tips'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'quiz',
                                      child: Text('Quiz'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'technique',
                                      child: Text('Technique'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cultural',
                                      child: Text('Cultural'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'challenge',
                                      child: Text('Challenge'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _nodeType = value ?? 'recipe',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _nodeStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'active',
                                      child: Text('Active'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'draft',
                                      child: Text('Draft'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'archived',
                                      child: Text('Archived'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _nodeStatus = value ?? 'active',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nodeLevelCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Level',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _nodePositionCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Position',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _nodeXpCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'XP Reward',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Candado inicial activo'),
                                  subtitle: const Text(
                                    'Cuando está activo, el nodo inicia bloqueado para usuario.',
                                  ),
                                  value: _nodeLockedByDefault,
                                  onChanged: (value) => setState(
                                    () => _nodeLockedByDefault = value,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _saveNode,
                                  child: Text(
                                    _isSaving
                                        ? 'Guardando...'
                                        : 'Guardar cambios',
                                  ),
                                ),
                              ],
                              if (_selectedStep != null &&
                                  _selectedType == 'node')
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Paso seleccionado: ${_selectedStep!['title'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (_selectedCard != null &&
                                  _selectedType == 'node')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Card seleccionada: ${_selectedCard!['type'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
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
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Advanced',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Metadata'),
                        const SizedBox(height: 12),
                        if (_selectedNode != null) ...[
                          Text(
                            'Status: ${_selectedNode['status'] ?? 'active'}',
                          ),
                          const SizedBox(height: 8),
                          Text('Type: ${_selectedNode['type'] ?? ''}'),
                          const SizedBox(height: 8),
                          Text('Level: ${_selectedNode['level'] ?? 1}'),
                          const SizedBox(height: 8),
                          Text(
                            'Position: ${_selectedNode['positionIndex'] ?? 1}',
                          ),
                          const SizedBox(height: 8),
                          Text('XP: ${_selectedNode['xpReward'] ?? 0}'),
                          const SizedBox(height: 8),
                          Text(
                            'Candado inicial: ${(_selectedNode['isLockedByDefault'] != false) ? 'activo' : 'inactivo'}',
                          ),
                          const SizedBox(height: 16),
                          // ======== PASOS SECTION ========
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pasos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _openStepDialog(),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Agregar'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        backgroundColor: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (steps.isEmpty)
                                  const Text(
                                    'Sin pasos. Agrega uno para empezar.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: steps.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final step =
                                          entry.value as Map<String, dynamic>;
                                      final stepId = step['_id'] ?? step['id'];
                                      final title =
                                          step['title'] ?? 'Paso sin título';
                                      final order =
                                          step['order'] ?? (index + 1);
                                      final cards = step['cards'];
                                      final cardCount = cards is List
                                          ? cards.length
                                          : 0;
                                      final isSelected = _selectedStep == step;

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue.shade100
                                              : Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue.shade400
                                                : Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _selectStep(step),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
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
                                                            Text(
                                                              title,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            Text(
                                                              'Orden: $order · $cardCount cards',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .black54,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuButton<String>(
                                                        onSelected: (value) {
                                                          if (value == 'edit') {
                                                            _openStepDialog(
                                                              step: step,
                                                            );
                                                          }
                                                          if (value ==
                                                              'delete') {
                                                            _deleteStep(step);
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (context) => const [
                                                              PopupMenuItem(
                                                                value: 'edit',
                                                                child: Text(
                                                                  'Editar',
                                                                ),
                                                              ),
                                                              PopupMenuItem(
                                                                value: 'delete',
                                                                child: Text(
                                                                  'Eliminar',
                                                                ),
                                                              ),
                                                            ],
                                                        child: Icon(
                                                          Icons.more_vert,
                                                          size: 16,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ======== Content Summary ========
                          const Text('Content'),
                          const SizedBox(height: 8),
                          Text('Steps: ${steps.length}'),
                          const SizedBox(height: 4),
                          Text('Cards: ${_totalCardCount(steps)}'),
                          const SizedBox(height: 12),
                          // ======== Dependencies ========
                          const Text('Dependencies'),
                          const SizedBox(height: 8),
                          if (_relationsLoading)
                            const LinearProgressIndicator()
                          else ...[
                            _buildRelationSection(
                              'Linked instances',
                              _relations['linkedInstances'] as List? ?? [],
                            ),
                            const SizedBox(height: 12),
                            _buildRelationSection(
                              'Referenced by',
                              _relations['referencedBy'] as List? ?? [],
                            ),
                          ],
                        ] else
                          const Text('Selecciona un nodo para ver detalles'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// STEP EDITOR DIALOG V2: Formulario profesional de paso
// ==========================================
class _StepEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? step;
  final int stepIndex;

  const _StepEditorDialog({required this.step, required this.stepIndex});

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late final _titleCtrl = TextEditingController(
    text: widget.step?['title'] ?? '',
  );
  late final _orderCtrl = TextEditingController(
    text: (widget.step?['order'] ?? widget.stepIndex).toString(),
  );
  late final _timeCtrl = TextEditingController(
    text: (widget.step?['estimatedTime'] ?? '').toString(),
  );

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orderCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El título del paso es requerido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'title': _titleCtrl.text.trim(),
      'order': int.tryParse(_orderCtrl.text) ?? widget.stepIndex,
      'estimatedTime': int.tryParse(_timeCtrl.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: 550,
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.blue.shade600,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.layers, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.step == null ? 'Nuevo Paso' : 'Editar Paso',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Título del Paso *',
                        hintText: 'ej. Ingredients, Preparation, Tips',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Orden y tiempo en fila
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _orderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Orden',
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _timeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tiempo (min)',
                              prefixIcon: const Icon(Icons.schedule),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Nota: Las tarjetas (cards) se agregan desde el editor derecho después de crear el paso.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(widget.step == null ? 'Crear Paso' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
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
// CARD EDITOR DIALOG: Formulario profesional para tarjetas
// ==========================================
class _CardEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? card;
  final int cardIndex;

  const _CardEditorDialog({required this.card, required this.cardIndex});

  @override
  State<_CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<_CardEditorDialog> {
  late String _cardType;
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cardType = widget.card?['type'] ?? 'text';
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCtrl(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();

      // Pre-cargar datos si es edición
      if (widget.card != null) {
        final data = widget.card!['data'] as Map? ?? {};
        switch (key) {
          case 'text':
            _controllers[key]!.text = (data['text'] ?? '').toString();
            break;
          case 'items':
            _controllers[key]!.text = (data['items'] is List)
                ? (data['items'] as List).join('\n')
                : '';
            break;
          case 'url':
            _controllers[key]!.text = (data['url'] ?? '').toString();
            break;
          case 'question':
            _controllers[key]!.text = (data['question'] ?? '').toString();
            break;
          case 'options':
            _controllers[key]!.text = (data['options'] is List)
                ? (data['options'] as List).join('\n')
                : '';
            break;
          case 'correctIndex':
            _controllers[key]!.text = (data['correctIndex'] ?? '0').toString();
            break;
          case 'duration':
            _controllers[key]!.text = (data['duration'] ?? '').toString();
            break;
          case 'sound':
            _controllers[key]!.text = (data['sound'] ?? '').toString();
            break;
        }
      }
    }
    return _controllers[key]!;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = <String, dynamic>{};

    if (_cardType == 'text') {
      data['text'] = _getCtrl('text').text.trim();
    } else if (_cardType == 'list') {
      data['items'] = _getCtrl('items').text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else if (_cardType == 'image' ||
        _cardType == 'video' ||
        _cardType == 'animation') {
      data['url'] = _getCtrl('url').text.trim();
    } else if (_cardType == 'quiz') {
      data['question'] = _getCtrl('question').text.trim();
      data['options'] = _getCtrl('options').text
          .split('\n')
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList();
      data['correctIndex'] = int.tryParse(_getCtrl('correctIndex').text) ?? 0;
    } else if (_cardType == 'timer') {
      data['duration'] = int.tryParse(_getCtrl('duration').text) ?? 0;
      data['sound'] = _getCtrl('sound').text.trim();
    }

    Navigator.pop(context, {'type': _cardType, 'data': data});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: 650,
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.purple.shade600,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.style, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Card ${widget.cardIndex}${widget.card == null ? '' : ' (Editar)'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de Card
                      DropdownButtonFormField<String>(
                        value: _cardType,
                        items: const [
                          DropdownMenuItem(
                            value: 'text',
                            child: Text('📝 Texto'),
                          ),
                          DropdownMenuItem(
                            value: 'list',
                            child: Text('📋 Lista'),
                          ),
                          DropdownMenuItem(
                            value: 'image',
                            child: Text('🖼️ Imagen'),
                          ),
                          DropdownMenuItem(
                            value: 'video',
                            child: Text('🎥 Video'),
                          ),
                          DropdownMenuItem(
                            value: 'animation',
                            child: Text('🎬 Animación'),
                          ),
                          DropdownMenuItem(
                            value: 'quiz',
                            child: Text('❓ Quiz'),
                          ),
                          DropdownMenuItem(
                            value: 'timer',
                            child: Text('⏱️ Timer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _cardType = value;
                              _controllers.clear();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Tipo de Card *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campos dinámicos según tipo
                      ..._buildTypeSpecificFields(),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
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

  List<Widget> _buildTypeSpecificFields() {
    switch (_cardType) {
      case 'text':
        return [
          TextFormField(
            controller: _getCtrl('text'),
            decoration: InputDecoration(
              labelText: 'Contenido de texto *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              hintText: 'Escribe el contenido...',
            ),
            maxLines: 4,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere contenido' : null,
          ),
        ];
      case 'list':
        return [
          TextFormField(
            controller: _getCtrl('items'),
            decoration: InputDecoration(
              labelText: 'Items (una línea por item) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              helperText: 'Cada línea será un item',
            ),
            maxLines: 5,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere items' : null,
          ),
        ];
      case 'image':
      case 'video':
      case 'animation':
        return [
          TextFormField(
            controller: _getCtrl('url'),
            decoration: InputDecoration(
              labelText: 'URL *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              hintText: 'https://...',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere URL' : null,
          ),
        ];
      case 'quiz':
        return [
          TextFormField(
            controller: _getCtrl('question'),
            decoration: InputDecoration(
              labelText: 'Pregunta *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 2,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere pregunta' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('options'),
            decoration: InputDecoration(
              labelText: 'Opciones (una por línea) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              helperText: 'Una opción por línea',
            ),
            maxLines: 4,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere opciones' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('correctIndex'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Índice respuesta correcta (0-3) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Requiere índice';
              final idx = int.tryParse(v!);
              if (idx == null || idx < 0 || idx > 3) return 'Debe ser 0-3';
              return null;
            },
          ),
        ];
      case 'timer':
        return [
          TextFormField(
            controller: _getCtrl('duration'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Duración (segundos) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixText: 'seg',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere duración' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('sound'),
            decoration: InputDecoration(
              labelText: 'Sound (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              hintText: 'ej. alert_sound.mp3',
            ),
          ),
        ];
      default:
        return [];
    }
  }
}
