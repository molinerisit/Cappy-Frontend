import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/api_service.dart';
import '../../../../core/models/learning_node.dart';
import '../../../../widgets/image_upload_field.dart';
import '../../../../widgets/video_upload_field.dart';
import '../../../learning/screens/lesson_game_screen.dart';

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

  static const List<Map<String, Object>> _previewDevices = [
    {
      'id': 'iphone-se',
      'label': 'iPhone SE',
      'size': '375 x 667',
      'kind': 'phone',
      'width': 375.0,
      'height': 667.0,
    },
    {
      'id': 'iphone-14-pro',
      'label': 'iPhone 14 Pro',
      'size': '393 x 852',
      'kind': 'phone',
      'width': 393.0,
      'height': 852.0,
    },
    {
      'id': 'pixel-7',
      'label': 'Pixel 7',
      'size': '412 x 915',
      'kind': 'phone',
      'width': 412.0,
      'height': 915.0,
    },
    {
      'id': 'galaxy-s20',
      'label': 'Galaxy S20',
      'size': '360 x 800',
      'kind': 'phone',
      'width': 360.0,
      'height': 800.0,
    },
    {
      'id': 'ipad-mini',
      'label': 'iPad mini',
      'size': '768 x 1024',
      'kind': 'tablet',
      'width': 768.0,
      'height': 1024.0,
    },
    {
      'id': 'ipad-pro-11',
      'label': 'iPad Pro 11"',
      'size': '834 x 1194',
      'kind': 'tablet',
      'width': 834.0,
      'height': 1194.0,
    },
    {
      'id': 'galaxy-tab-s8',
      'label': 'Galaxy Tab S8',
      'size': '800 x 1280',
      'kind': 'tablet',
      'width': 800.0,
      'height': 1280.0,
    },
  ];

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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando caminos: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContent(String pathId) async {
    setState(() => _isLoading = true);
    try {
      final groups = await ApiService.adminGetGroupsByPath(pathId);
      final nodes = await ApiService.adminGetContentNodesByPath(pathId);

      debugPrint('🔍 [_loadContent] Loaded data:');
      debugPrint('  Groups: ${groups.length} items');
      for (var g in groups) {
        debugPrint('    - ${g['title']} (${g['_id']})');
      }
      debugPrint('  Nodes: ${nodes.length} items');
      for (var n in nodes) {
        final gid = n['groupId'];
        final groupIdDisplay = gid is Map
            ? '${gid['_id']} (${gid['title']})'
            : gid?.toString() ?? 'null';
        debugPrint(
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
      debugPrint('❌ [_loadContent] Error: $e');
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

      if (!mounted) return;
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

    if (!mounted) return;
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
                    DropdownMenuItem(value: 'recipe', child: Text('🍽 Recipe')),
                    DropdownMenuItem(
                      value: 'explanation',
                      child: Text('📖 Explanation'),
                    ),
                    DropdownMenuItem(value: 'tips', child: Text('💡 Tips')),
                    DropdownMenuItem(value: 'quiz', child: Text('❓ Quiz')),
                    DropdownMenuItem(
                      value: 'technique',
                      child: Text('🔧 Technique'),
                    ),
                    DropdownMenuItem(
                      value: 'cultural',
                      child: Text('🌍 Cultural'),
                    ),
                    DropdownMenuItem(
                      value: 'challenge',
                      child: Text('🏆 Challenge'),
                    ),
                    DropdownMenuItem(
                      value: 'defense',
                      child: Text('🛡️ Defense'),
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

  Future<void> _openNodePreviewDialog(Map<String, dynamic> node) async {
    final rawSteps = node['steps'];
    if (rawSteps is! List || rawSteps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este nodo no tiene pasos para previsualizar.'),
          ),
        );
      }
      return;
    }

    final previewNode = LearningNode.fromJson(Map<String, dynamic>.from(node));
    if (previewNode.steps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo construir la vista previa del nodo.'),
          ),
        );
      }
      return;
    }

    String selectedDeviceId = (_previewDevices.first['id'] ?? 'iphone-14-pro')
        .toString();
    bool isLandscape = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedDevice = _previewDevices.firstWhere(
              (device) => (device['id'] ?? '').toString() == selectedDeviceId,
              orElse: () => _previewDevices.first,
            );
            final baseWidth =
                (selectedDevice['width'] as num?)?.toDouble() ?? 393.0;
            final baseHeight =
                (selectedDevice['height'] as num?)?.toDouble() ?? 852.0;
            final isTablet =
                (selectedDevice['kind'] ?? 'phone').toString() == 'tablet';
            final viewportWidth = isLandscape ? baseHeight : baseWidth;
            final viewportHeight = isLandscape ? baseWidth : baseHeight;
            final ratio = viewportWidth / viewportHeight;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: SizedBox(
                width: math.min(MediaQuery.of(context).size.width * 0.92, 1080),
                height: math.min(
                  MediaQuery.of(context).size.height * 0.92,
                  860,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.remove_red_eye_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vista previa del nodo: ${node['title'] ?? 'Sin titulo'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Previsualizacion en formato de dispositivo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedDeviceId,
                                    items: _previewDevices
                                        .map(
                                          (device) => DropdownMenuItem<String>(
                                            value: (device['id'] ?? '')
                                                .toString(),
                                            child: Text(
                                              '${device['label']} (${device['size']})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(
                                        () => selectedDeviceId = value,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cerrar',
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Portrait'),
                                selected: !isLandscape,
                                onSelected: (_) =>
                                    setDialogState(() => isLandscape = false),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Landscape'),
                                selected: isLandscape,
                                onSelected: (_) =>
                                    setDialogState(() => isLandscape = true),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isTablet
                                      ? Colors.indigo.shade50
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isTablet
                                        ? Colors.indigo.shade200
                                        : Colors.teal.shade200,
                                  ),
                                ),
                                child: Text(
                                  isTablet ? 'Tablet' : 'Celular',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isTablet
                                        ? Colors.indigo.shade700
                                        : Colors.teal.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxPhoneWidth = math.min(
                            constraints.maxWidth - 36,
                            (constraints.maxHeight - 12) * ratio,
                          );
                          final minDeviceWidth = isTablet ? 340.0 : 280.0;
                          final maxDeviceWidth = isTablet ? 760.0 : 460.0;
                          final phoneWidth = maxPhoneWidth
                              .clamp(minDeviceWidth, maxDeviceWidth)
                              .toDouble();
                          final phoneHeight = (phoneWidth / ratio).toDouble();

                          return Center(
                            child: Container(
                              width: phoneWidth + 20,
                              height: phoneHeight + 20,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1220),
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 20 : 28,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 14 : 20,
                                ),
                                child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    size: Size(viewportWidth, viewportHeight),
                                  ),
                                  child: SizedBox(
                                    width: phoneWidth,
                                    height: phoneHeight,
                                    child: LessonGameScreen(
                                      key: ValueKey(
                                        '${node['_id'] ?? node['id']}-${selectedDeviceId}-${isLandscape ? 'land' : 'port'}',
                                      ),
                                      node: previewNode,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _inferFirstLevel(List<dynamic> nodes) {
    if (nodes.isEmpty) return 1;
    final levels =
        nodes.map((node) => (node['level'] ?? 1) as int).toSet().toList()
          ..sort();
    return levels.first;
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

    debugPrint(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Vista previa',
                        onPressed: () => _openNodePreviewDialog(node),
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 16,
                          color: Colors.blueGrey.shade700,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                      PopupMenuButton<String>(
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
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                    ],
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
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

  Future<void> _moveCardInStep({
    required Map<String, dynamic> step,
    required int fromIndex,
    required int toIndex,
  }) async {
    if (_selectedNode == null) return;

    final currentCards = _getStepCards(step);
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= currentCards.length ||
        toIndex >= currentCards.length ||
        fromIndex == toIndex) {
      return;
    }

    final reorderedCards = List<Map<String, dynamic>>.from(currentCards);
    final movedCard = reorderedCards.removeAt(fromIndex);
    reorderedCards.insert(toIndex, movedCard);

    setState(() => _isSaving = true);

    try {
      final nodeId = (_selectedNode['_id'] ?? _selectedNode['id'])?.toString();
      final stepId = (step['_id'] ?? step['id'])?.toString();
      if (nodeId == null || stepId == null) {
        throw Exception('No se pudo identificar nodo/paso para reordenar');
      }

      await ApiService.adminUpdateNodeStep(nodeId, stepId, {
        'cards': reorderedCards,
      });

      if (_selectedPathId != null) {
        _pendingSelectNodeId = nodeId;
        await _loadContent(_selectedPathId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Orden de tarjetas actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reordenando tarjetas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
      case 'checklist':
        return '☑️';
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
      case 'checklist':
        final checklistItems = data['items'] as List? ?? [];
        return '${checklistItems.length} items interactivos';
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
    bool isSelected, {
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
    Map<String, dynamic>? step,
  }) {
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Subir',
                      onPressed: onMoveUp,
                      icon: Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: onMoveUp == null
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bajar',
                      onPressed: onMoveDown,
                      icon: Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: onMoveDown == null
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          if (step != null) _selectStep(step);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _currentSteps();
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
                                                        onWillAcceptWithDetails: (details) {
                                                          final current =
                                                              (details.data['level'] ??
                                                                      1)
                                                                  as int;
                                                          final currentGroupId =
                                                              (details
                                                                  .data['groupId']
                                                                  ?.toString() ??
                                                              '');
                                                          return currentGroupId !=
                                                                  groupId
                                                                      .toString() ||
                                                              current != level;
                                                        },
                                                        onAcceptWithDetails:
                                                            (details) async {
                                                              await _applyNodeDrop(
                                                                dragged: details
                                                                    .data,
                                                                targetGroupId:
                                                                    groupId
                                                                        .toString(),
                                                                targetLevel:
                                                                    level,
                                                                targetIndex:
                                                                    levelNodes
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
                                                                            .green
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
                                                                              .green
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
                                                                              .green
                                                                              .shade700
                                                                        : Colors
                                                                              .black54,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                      const SizedBox(height: 4),
                                                      ...levelNodes.asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        final index = entry.key;
                                                        final node =
                                                            entry.value;
                                                        return DragTarget<
                                                          Map<String, dynamic>
                                                        >(
                                                          onWillAcceptWithDetails: (details) {
                                                            final draggedId =
                                                                (details.data['_id'] ??
                                                                        details
                                                                            .data['id'])
                                                                    .toString();
                                                            final targetId =
                                                                (node['_id'] ??
                                                                        node['id'])
                                                                    .toString();
                                                            return draggedId !=
                                                                targetId;
                                                          },
                                                          onAcceptWithDetails:
                                                              (details) async {
                                                                await _applyNodeDrop(
                                                                  dragged:
                                                                      details
                                                                          .data,
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
                                                                            .green
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
                                                                              ? Colors.green.shade300
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
                                                                                    color: Colors.black.withValues(
                                                                                      alpha: 0.05,
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
                                                                                                          tooltip: 'Vista previa del nodo',
                                                                                                          icon: Icon(
                                                                                                            Icons.remove_red_eye_outlined,
                                                                                                            size: 16,
                                                                                                            color: Colors.blueGrey.shade700,
                                                                                                          ),
                                                                                                          onPressed: () => _openNodePreviewDialog(
                                                                                                            node,
                                                                                                          ),
                                                                                                        ),
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
                                                                                                                      final card = cardEntry.value;
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
                                                                                                                          step: step,
                                                                                                                          onMoveUp:
                                                                                                                              cardIdx >
                                                                                                                                  0
                                                                                                                              ? () => _moveCardInStep(
                                                                                                                                  step: step,
                                                                                                                                  fromIndex: cardIdx,
                                                                                                                                  toIndex:
                                                                                                                                      cardIdx -
                                                                                                                                      1,
                                                                                                                                )
                                                                                                                              : null,
                                                                                                                          onMoveDown:
                                                                                                                              cardIdx <
                                                                                                                                  stepCards.length -
                                                                                                                                      1
                                                                                                                              ? () => _moveCardInStep(
                                                                                                                                  step: step,
                                                                                                                                  fromIndex: cardIdx,
                                                                                                                                  toIndex:
                                                                                                                                      cardIdx +
                                                                                                                                      1,
                                                                                                                                )
                                                                                                                              : null,
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
                                                      }),
                                                      DragTarget<
                                                        Map<String, dynamic>
                                                      >(
                                                        onWillAcceptWithDetails:
                                                            (details) {
                                                              return true;
                                                            },
                                                        onAcceptWithDetails:
                                                            (details) async {
                                                              await _applyNodeDrop(
                                                                dragged: details
                                                                    .data,
                                                                targetGroupId:
                                                                    groupId
                                                                        .toString(),
                                                                targetLevel:
                                                                    level,
                                                                targetIndex:
                                                                    levelNodes
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
                                                                            .green
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
                                    final step = entry.value;
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
                                                    children: stepCards.asMap().entries.map((
                                                      cardEntry,
                                                    ) {
                                                      final cardIdx =
                                                          cardEntry.key;
                                                      final card =
                                                          cardEntry.value;
                                                      final isSelectedCard =
                                                          _selectedCard == card;
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 8,
                                                            ),
                                                        child: _buildCardPreview(
                                                          card,
                                                          cardIdx + 1,
                                                          isSelectedCard,
                                                          step: step,
                                                          onMoveUp: cardIdx > 0
                                                              ? () => _moveCardInStep(
                                                                  step: step,
                                                                  fromIndex:
                                                                      cardIdx,
                                                                  toIndex:
                                                                      cardIdx -
                                                                      1,
                                                                )
                                                              : null,
                                                          onMoveDown:
                                                              cardIdx <
                                                                  stepCards
                                                                          .length -
                                                                      1
                                                              ? () => _moveCardInStep(
                                                                  step: step,
                                                                  fromIndex:
                                                                      cardIdx,
                                                                  toIndex:
                                                                      cardIdx +
                                                                      1,
                                                                )
                                                              : null,
                                                        ),
                                                      );
                                                    }).toList(),
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
                                _buildNodeTypeSelector(),
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
                                      final step = entry.value;
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

  Widget _buildNodeTypeSelector() {
    final types = [
      ('recipe', Icons.restaurant, Colors.green),
      ('explanation', Icons.auto_stories, Colors.blue),
      ('tips', Icons.lightbulb, Colors.yellow.shade700),
      ('quiz', Icons.quiz, Colors.red),
      ('technique', Icons.construction, Colors.purple),
      ('cultural', Icons.public, Colors.green),
      ('challenge', Icons.sports_score, Colors.amber),
      ('defense', Icons.security, Colors.cyan),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Nodo',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isSelected = _nodeType == type.$1;
            return GestureDetector(
              onTap: () => setState(() => _nodeType = type.$1),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isSelected
                      ? type.$3.withValues(alpha: 0.2)
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: isSelected ? type.$3 : Colors.grey.shade200,
                    width: isSelected ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: type.$3.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.$2,
                      size: 32,
                      color: isSelected ? type.$3 : Colors.grey.shade600,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: type.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          backgroundColor: Colors.green,
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
  static const int _quizOptionCount = 4;
  late String _cardType;
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  // Estado específico para animaciones interactivas
  String _animationType = 'click';
  String _initialAssetType = 'image';
  bool _interactionLoop = true;
  final List<Map<String, dynamic>> _interactionAssets = [];

  // Estado específico para add_remove_objects
  String _objectAssetType = 'image';
  bool _allowRemove = false;

  // Estado específico para list
  String _listStyle = 'checks';

  // Estado específico para magnifier_reveal
  double _lensRadius = 24;
  double _lensOpacity = 0.92;
  double _lensGlowRadius = 8;
  bool _allowBoundaryDrag = false;
  bool _autoResetOnRelease = false;

  // Estado específico para object_sweep
  double _sweeperSize = 90.0;
  List<Map<String, dynamic>> _sweepObjects = [];
  int? _selectedSweepObjectIndex;

  // Estado para formato de texto
  final Map<String, bool> _formatFlags = {};

  // Ajustes de visualizacion de imagen por campo (fit/zoom/offset)
  final Map<String, Map<String, dynamic>> _imageAdjustments = {};

  Map<String, dynamic> _defaultImageAdjustment() => {
    'fit': 'cover',
    'zoom': 1.0,
    'offsetX': 0.0,
    'offsetY': 0.0,
  };

  Map<String, dynamic> _sanitizeImageAdjustment(dynamic raw) {
    final defaults = _defaultImageAdjustment();
    if (raw is! Map) return defaults;

    final fit = raw['fit']?.toString() ?? defaults['fit'] as String;
    final zoom = raw['zoom'] is num
        ? (raw['zoom'] as num).toDouble().clamp(1.0, 2.5)
        : double.tryParse('${raw['zoom']}')?.clamp(1.0, 2.5) ?? 1.0;
    final offsetX = raw['offsetX'] is num
        ? (raw['offsetX'] as num).toDouble().clamp(-1.0, 1.0)
        : double.tryParse('${raw['offsetX']}')?.clamp(-1.0, 1.0) ?? 0.0;
    final offsetY = raw['offsetY'] is num
        ? (raw['offsetY'] as num).toDouble().clamp(-1.0, 1.0)
        : double.tryParse('${raw['offsetY']}')?.clamp(-1.0, 1.0) ?? 0.0;

    return {
      'fit':
          const [
            'cover',
            'contain',
            'fill',
            'fitWidth',
            'fitHeight',
          ].contains(fit)
          ? fit
          : defaults['fit'],
      'zoom': zoom,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  void _setImageAdjustment(String key, Map<String, dynamic> value) {
    _imageAdjustments[key] = _sanitizeImageAdjustment(value);
  }

  bool _isDefaultImageAdjustment(Map<String, dynamic> value) {
    final defaults = _defaultImageAdjustment();
    return (value['fit'] ?? defaults['fit']) == defaults['fit'] &&
        (value['zoom'] ?? defaults['zoom']) == defaults['zoom'] &&
        (value['offsetX'] ?? defaults['offsetX']) == defaults['offsetX'] &&
        (value['offsetY'] ?? defaults['offsetY']) == defaults['offsetY'];
  }

  double _toDoubleValue(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _toBoolValue(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _cardType = widget.card?['type'] ?? 'text';

    if (widget.card != null) {
      final data = widget.card!['data'] as Map? ?? {};

      _imageAdjustments['text.image'] = _sanitizeImageAdjustment(
        data['imageDisplay'],
      );
      _imageAdjustments['media.main'] = _sanitizeImageAdjustment(
        data['display'] ?? data['imageDisplay'],
      );
      _imageAdjustments['quiz.image'] = _sanitizeImageAdjustment(
        data['quizImageDisplay'],
      );

      final optionItems = data['optionItems'] is List
          ? List<dynamic>.from(data['optionItems'] as List)
          : const <dynamic>[];
      for (int i = 0; i < optionItems.length; i++) {
        final option = optionItems[i] is Map
            ? Map<String, dynamic>.from(optionItems[i] as Map)
            : <String, dynamic>{};
        _imageAdjustments['quiz.option.$i'] = _sanitizeImageAdjustment(
          option['imageDisplay'],
        );
      }

      _formatFlags['videoLoop'] = _toBoolValue(
        data['loop'] ?? data['videoLoop'],
        fallback: false,
      );
      _formatFlags['videoMuted'] = _toBoolValue(
        data['muted'] ?? data['videoMuted'],
        fallback: false,
      );
    }

    // Pre-cargar datos de list si existen
    if (_cardType == 'list' && widget.card != null) {
      final data = widget.card!['data'] as Map? ?? {};
      _listStyle = data['listStyle']?.toString() ?? 'checks';
    }

    // Pre-cargar datos de animación si existen
    if (_cardType == 'animation' && widget.card != null) {
      final data = widget.card!['data'] as Map? ?? {};
      _animationType = data['animationType'] ?? 'click';
      _initialAssetType = (data['initialAsset'] as Map?)?['type'] ?? 'image';
      final config = data['config'] as Map? ?? {};
      _interactionLoop = config['loop'] is bool ? config['loop'] as bool : true;

      final assets = data['interactionAssets'] as List? ?? [];
      for (var asset in assets) {
        final normalizedAsset = asset is Map && asset['asset'] is Map
            ? Map<String, dynamic>.from(asset['asset'] as Map)
            : (asset is Map
                  ? Map<String, dynamic>.from(asset)
                  : <String, dynamic>{});
        final rawType = (normalizedAsset['type'] ?? 'image').toString();
        final normalizedType = rawType.toLowerCase() == 'texto'
            ? 'text'
            : rawType.toLowerCase();
        final rawUrl = (normalizedAsset['url'] ?? '').toString();
        final rawText = (normalizedAsset['text'] ?? '').toString();

        _interactionAssets.add({
          'type': normalizedType,
          'url': rawUrl,
          'text': normalizedType == 'text' && rawText.trim().isEmpty
              ? rawUrl
              : rawText,
        });
      }

      // Cargar datos específicos de add_remove_objects
      if (_animationType == 'add_remove_objects') {
        _objectAssetType = (data['objectAsset'] as Map?)?['type'] ?? 'image';
        _allowRemove = data['allowRemove'] ?? false;
      } else if (_animationType == 'magnifier_reveal') {
        final config = data['config'] as Map? ?? {};
        _lensRadius = _toDoubleValue(
          config['lensRadius'],
          fallback: 24,
        ).clamp(24, 140);
        _lensOpacity = _toDoubleValue(
          config['lensOpacity'],
          fallback: 0.92,
        ).clamp(0.2, 1.0);
        _lensGlowRadius = _toDoubleValue(
          config['lensGlowRadius'],
          fallback: 8,
        ).clamp(0, 30);
        _allowBoundaryDrag = _toBoolValue(
          config['allowBoundaryDrag'],
          fallback: false,
        );
        _autoResetOnRelease = _toBoolValue(
          config['autoResetOnRelease'],
          fallback: false,
        );
      } else if (_animationType == 'object_sweep') {
        final config = data['config'] as Map? ?? {};
        _sweeperSize = _toDoubleValue(
          config['sweeperSize'],
          fallback: 90,
        ).clamp(40, 200);
        final rawObjects = config['sweepObjects'];
        if (rawObjects is List) {
          _sweepObjects = rawObjects
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        } else {
          _sweepObjects = [];
        }
      }
    }

    // Si es nueva animación o no tiene assets, agregar uno vacío
    if (_cardType == 'animation' && _interactionAssets.isEmpty) {
      _interactionAssets.add({'type': 'image', 'url': '', 'text': ''});
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  bool _getCtrlBool(String key) => _formatFlags[key] ?? false;

  void _setCtrlBool(String key, bool value) {
    _formatFlags[key] = value;
  }

  TextEditingController _getCtrl(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();

      // Pre-cargar datos si es edición
      if (widget.card != null) {
        final data = widget.card!['data'] as Map? ?? {};

        if (key.startsWith('optionText_') || key.startsWith('optionImage_')) {
          final keyParts = key.split('_');
          final optionIndex = keyParts.length > 1
              ? int.tryParse(keyParts.last) ?? -1
              : -1;

          final optionItems = data['optionItems'] is List
              ? List<dynamic>.from(data['optionItems'] as List)
              : const <dynamic>[];

          Map<String, dynamic>? optionItem;
          if (optionIndex >= 0 &&
              optionIndex < optionItems.length &&
              optionItems[optionIndex] is Map) {
            optionItem = Map<String, dynamic>.from(optionItems[optionIndex]);
          }

          if (key.startsWith('optionText_')) {
            final legacyOptions = data['options'] is List
                ? List<dynamic>.from(data['options'] as List)
                : const <dynamic>[];

            final itemText = (optionItem?['text'] ?? '').toString();
            final legacyText =
                (optionIndex >= 0 && optionIndex < legacyOptions.length)
                ? (legacyOptions[optionIndex] ?? '').toString()
                : '';

            _controllers[key]!.text = itemText.isNotEmpty
                ? itemText
                : legacyText;
          } else {
            _controllers[key]!.text =
                (optionItem?['imageUrl'] ?? optionItem?['image'] ?? '')
                    .toString();
          }

          return _controllers[key]!;
        }

        switch (key) {
          case 'text':
            _controllers[key]!.text = (data['text'] ?? '').toString();
            break;
          case 'title':
            _controllers[key]!.text = (data['title'] ?? '').toString();
            break;
          case 'imageUrl':
            _controllers[key]!.text = (data['imageUrl'] ?? '').toString();
            break;
          case 'items':
            _controllers[key]!.text = (data['items'] is List)
                ? (data['items'] as List).join('\n')
                : '';
            break;
          case 'url':
            _controllers[key]!.text = (data['url'] ?? data['videoUrl'] ?? '')
                .toString();
            break;
          case 'videoEndText':
            _controllers[key]!.text =
                (data['completionText'] ?? data['videoEndText'] ?? '')
                    .toString();
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
          case 'explanation':
            _controllers[key]!.text = (data['explanation'] ?? '').toString();
            break;
          case 'quizImageUrl':
            _controllers[key]!.text = (data['quizImageUrl'] ?? '').toString();
            break;
          case 'isBold':
            _formatFlags[key] = data['isBold'] ?? false;
            break;
          case 'isItalic':
            _formatFlags[key] = data['isItalic'] ?? false;
            break;
          case 'duration':
            _controllers[key]!.text = (data['duration'] ?? '').toString();
            break;
          case 'sound':
            _controllers[key]!.text = (data['sound'] ?? '').toString();
            break;
          case 'anim_instruction':
            _controllers[key]!.text = (data['instruction'] ?? '').toString();
            break;
          case 'anim_initial_url':
            final initialAsset = (data['initialAsset'] as Map?) ?? {};
            _controllers[key]!.text =
                (initialAsset['url'] ?? initialAsset['text'] ?? '').toString();
            break;
          case 'anim_object_url':
            _controllers[key]!.text =
                ((data['objectAsset'] as Map?)?['url'] ?? '').toString();
            break;
          case 'anim_object_size':
            _controllers[key]!.text = (data['objectSize']?.toString() ?? '40')
                .toString();
            break;
          case 'anim_reveal_url':
            _controllers[key]!.text =
                ((data['revealAsset'] as Map?)?['url'] ?? '').toString();
            break;
        }
      }
    }
    return _controllers[key]!;
  }

  String? _validateAnimationRequiredFields() {
    if (_cardType != 'animation') return null;

    final initialAssetValue = _getCtrl('anim_initial_url').text.trim();
    if (initialAssetValue.isEmpty) {
      return _initialAssetType == 'text'
          ? 'Requiere texto inicial'
          : 'Requiere asset inicial';
    }

    if (_animationType == 'add_remove_objects') {
      final objectValue = _getCtrl('anim_object_url').text.trim();
      if (objectValue.isEmpty) {
        return 'Requiere ${_objectAssetType == 'icon' ? 'ícono' : 'objeto'}';
      }
      return null;
    }

    if (_animationType == 'magnifier_reveal') {
      if (_getCtrl('anim_reveal_url').text.trim().isEmpty) {
        return 'Requiere imagen oculta';
      }
      return null;
    }

    if (_animationType == 'object_sweep') {
      if (_getCtrl('sweep_sweeper_url').text.trim().isEmpty) {
        return 'Requiere imagen del objeto limpiador';
      }
      return null;
    }

    if (_interactionAssets.isEmpty) {
      return 'Agrega al menos un asset de interacción';
    }

    for (int i = 0; i < _interactionAssets.length; i++) {
      final asset = _interactionAssets[i];
      final type = (asset['type'] ?? 'image').toString();

      if (type == 'text') {
        final textValue = (asset['text'] ?? '').toString().trim();
        if (textValue.isEmpty) {
          return 'El texto del asset ${i + 1} es obligatorio';
        }
      } else {
        final urlValue = (asset['url'] ?? '').toString().trim();
        if (urlValue.isEmpty) {
          return 'La URL del asset ${i + 1} es obligatoria';
        }
      }
    }

    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final animationValidationError = _validateAnimationRequiredFields();
    if (animationValidationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(animationValidationError)));
      return;
    }

    _formKey.currentState!.save();

    final data = <String, dynamic>{};

    if (_cardType == 'text') {
      data['text'] = _getCtrl('text').text.trim();
      final title = _getCtrl('title').text.trim();
      if (title.isNotEmpty) {
        data['title'] = title;
      }
      final imageUrl = _getCtrl('imageUrl').text.trim();
      if (imageUrl.isNotEmpty) {
        data['imageUrl'] = imageUrl;
        final display = _imageAdjustments['text.image'];
        if (display != null && !_isDefaultImageAdjustment(display)) {
          data['imageDisplay'] = display;
        }
      }
      if (_getCtrlBool('isBold')) {
        data['isBold'] = true;
      }
      if (_getCtrlBool('isItalic')) {
        data['isItalic'] = true;
      }
    } else if (_cardType == 'list') {
      data['items'] = _getCtrl('items').text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      data['listStyle'] = _listStyle;
    } else if (_cardType == 'checklist') {
      data['items'] = _getCtrl('items').text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else if (_cardType == 'image') {
      data['url'] = _getCtrl('url').text.trim();
      if (data['url'].toString().isNotEmpty) {
        final display = _imageAdjustments['media.main'];
        if (display != null && !_isDefaultImageAdjustment(display)) {
          data['display'] = display;
        }
      }
    } else if (_cardType == 'video') {
      final url = _getCtrl('url').text.trim();
      if (url.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Requiere URL de video')));
        return;
      }

      data['url'] = url;
      data['videoUrl'] = url;
      data['loop'] = _getCtrlBool('videoLoop');
      data['videoLoop'] = _getCtrlBool('videoLoop');
      data['muted'] = _getCtrlBool('videoMuted');
      data['videoMuted'] = _getCtrlBool('videoMuted');

      final completionText = _getCtrl('videoEndText').text.trim();
      if (completionText.isNotEmpty) {
        data['completionText'] = completionText;
        data['videoEndText'] = completionText;
      }
    } else if (_cardType == 'animation') {
      // Construcción del objeto de animación interactiva
      data['animationType'] = _animationType;
      data['instruction'] = _getCtrl('anim_instruction').text.trim();
      final initialAssetValue = _getCtrl('anim_initial_url').text.trim();

      if (_animationType == 'add_remove_objects') {
        // Configuración específica para agregar/quitar objetos
        data['initialAsset'] = {
          'type': _initialAssetType,
          'url': initialAssetValue,
        };
        data['objectAsset'] = {
          'type': _objectAssetType,
          'url': _getCtrl('anim_object_url').text.trim(),
        };
        data['objectSize'] =
            int.tryParse(_getCtrl('anim_object_size').text) ?? 40;
        data['allowRemove'] = _allowRemove;
        data['config'] = {
          'maxObjects': 50, // Límite de objetos que se pueden agregar
        };
      } else if (_animationType == 'magnifier_reveal') {
        data['initialAsset'] = {'type': 'image', 'url': initialAssetValue};
        data['revealAsset'] = {
          'type': 'image',
          'url': _getCtrl('anim_reveal_url').text.trim(),
        };
        data['config'] = {
          'lensRadius': _lensRadius,
          'lensOpacity': _lensOpacity,
          'lensGlowRadius': _lensGlowRadius,
          'allowBoundaryDrag': _allowBoundaryDrag,
          'autoResetOnRelease': _autoResetOnRelease,
        };
      } else if (_animationType == 'object_sweep') {
        data['initialAsset'] = {'type': 'image', 'url': initialAssetValue};
        data['sweeperAsset'] = {
          'type': 'image',
          'url': _getCtrl('sweep_sweeper_url').text.trim(),
        };
        data['config'] = {
          'sweeperSize': _sweeperSize,
          'sweepObjects': _sweepObjects,
        };
      } else {
        // Configuración estándar para otros tipos de animación
        data['initialAsset'] = _initialAssetType == 'text'
            ? {'type': 'text', 'text': initialAssetValue}
            : {'type': _initialAssetType, 'url': initialAssetValue};

        data['interactionAssets'] = _interactionAssets
            .where((asset) {
              final type = (asset['type'] ?? 'image').toString();
              if (type == 'text') {
                return (asset['text']?.toString().trim().isNotEmpty ?? false);
              }
              return (asset['url']?.toString().trim().isNotEmpty ?? false);
            })
            .map(
              (asset) => {
                'trigger': 'action',
                'asset': (asset['type'] ?? 'image').toString() == 'text'
                    ? {
                        'type': 'text',
                        'text': (asset['text'] ?? '').toString().trim(),
                      }
                    : {
                        'type': asset['type'],
                        'url': (asset['url'] ?? '').toString().trim(),
                      },
              },
            )
            .toList();
        data['config'] = {
          'loop': _interactionLoop,
          'autoReturn': false,
          'allowMultipleInteractions': true,
        };
      }
    } else if (_cardType == 'quiz') {
      data['question'] = _getCtrl('question').text.trim();

      final optionItems = List<Map<String, dynamic>>.generate(
        _quizOptionCount,
        (index) {
          final text = _getCtrl('optionText_$index').text.trim();
          final imageUrl = _getCtrl('optionImage_$index').text.trim();

          final option = <String, dynamic>{'text': text};
          if (imageUrl.isNotEmpty) {
            option['imageUrl'] = imageUrl;
            final display = _imageAdjustments['quiz.option.$index'];
            if (display != null && !_isDefaultImageAdjustment(display)) {
              option['imageDisplay'] = display;
            }
          }
          return option;
        },
      );

      data['optionItems'] = optionItems;
      data['options'] = optionItems.map((option) => option['text']).toList();
      data['correctIndex'] = int.tryParse(_getCtrl('correctIndex').text) ?? 0;
      final explanation = _getCtrl('explanation').text.trim();
      if (explanation.isNotEmpty) {
        data['explanation'] = explanation;
      }
      final quizImageUrl = _getCtrl('quizImageUrl').text.trim();
      if (quizImageUrl.isNotEmpty) {
        data['quizImageUrl'] = quizImageUrl;
        final display = _imageAdjustments['quiz.image'];
        if (display != null && !_isDefaultImageAdjustment(display)) {
          data['quizImageDisplay'] = display;
        }
      }
    } else if (_cardType == 'timer') {
      data['duration'] = int.tryParse(_getCtrl('duration').text) ?? 0;
      data['sound'] = 'alarma.mp3';
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
                            value: 'checklist',
                            child: Text('☑️ Checklist'),
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
          // Título opcional
          TextFormField(
            controller: _getCtrl('title'),
            decoration: InputDecoration(
              labelText: 'Título (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          // Contenido principal
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
          const SizedBox(height: 12),
          // Imagen opcional con upload profesional
          ImageUploadField(
            label: 'Imagen (opcional)',
            initialUrl: _getCtrl('imageUrl').text,
            initialAdjustments: _imageAdjustments['text.image'],
            onImageChanged: (url) {
              _getCtrl('imageUrl').text = url ?? '';
            },
            onAdjustmentsChanged: (value) {
              _setImageAdjustment('text.image', value);
            },
            aspectRatio: 16 / 9,
            helperText: 'Sube una imagen o pega una URL externa',
          ),
          const SizedBox(height: 12),
          // Opciones de formato
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opciones de Formato',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _getCtrlBool('isBold'),
                          onChanged: (v) => setState(
                            () => _setCtrlBool('isBold', v ?? false),
                          ),
                        ),
                        const Text('Negrita'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _getCtrlBool('isItalic'),
                          onChanged: (v) => setState(
                            () => _setCtrlBool('isItalic', v ?? false),
                          ),
                        ),
                        const Text('Itálica'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      case 'list':
        return [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estilo de lista',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'checks', label: Text('✅ Checks')),
                  ButtonSegment(value: 'crosses', label: Text('❌ Cruces')),
                  ButtonSegment(value: 'numbered', label: Text('🔢 Pasos')),
                ],
                selected: {_listStyle},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    setState(() => _listStyle = set.first);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
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
      case 'checklist':
        return [
          TextFormField(
            controller: _getCtrl('items'),
            decoration: InputDecoration(
              labelText: 'Items del checklist (una línea por item) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              helperText:
                  'El usuario debe marcar todos para continuar al siguiente paso',
            ),
            maxLines: 8,
            validator: (v) =>
                v?.trim().isEmpty ?? true ? 'Requiere al menos un item' : null,
          ),
        ];
      case 'image':
      case 'video':
        final isImage = _cardType == 'image';
        return [
          if (isImage)
            ImageUploadField(
              label: 'Imagen',
              initialUrl: _getCtrl('url').text,
              initialAdjustments: _imageAdjustments['media.main'],
              onImageChanged: (url) {
                _getCtrl('url').text = url ?? '';
              },
              onAdjustmentsChanged: (value) {
                _setImageAdjustment('media.main', value);
              },
              aspectRatio: 16 / 9,
              required: true,
              helperText: 'Sube una imagen o pega una URL externa',
            )
          else
            Column(
              children: [
                VideoUploadField(
                  label: 'Video',
                  initialUrl: _getCtrl('url').text,
                  required: true,
                  helperText:
                      'Sube un archivo desde tu PC a Cloudinary o usa una URL directa',
                  onVideoChanged: (url) {
                    _getCtrl('url').text = url ?? '';
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comportamiento del Video',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Activar loop'),
                        dense: true,
                        value: _getCtrlBool('videoLoop'),
                        onChanged: (value) {
                          setState(() => _setCtrlBool('videoLoop', value));
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Iniciar sin sonido'),
                        dense: true,
                        value: _getCtrlBool('videoMuted'),
                        onChanged: (value) {
                          setState(() => _setCtrlBool('videoMuted', value));
                        },
                      ),
                      TextFormField(
                        controller: _getCtrl('videoEndText'),
                        decoration: InputDecoration(
                          labelText: 'Texto personalizado al finalizar',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Ej: ¡Perfecto! Ya dominaste esta técnica',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ];
      case 'animation':
        return _buildInteractiveAnimationFields();
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
          ..._buildQuizOptionFields(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('correctIndex'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  'Índice respuesta correcta (0-${_quizOptionCount - 1}) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Requiere índice';
              final idx = int.tryParse(v!);
              if (idx == null || idx < 0 || idx >= _quizOptionCount) {
                return 'Debe ser 0-${_quizOptionCount - 1}';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('explanation'),
            decoration: InputDecoration(
              labelText: 'Feedback al responder correctamente',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.green.shade50,
              helperText: 'Texto pequeño que se muestra cuando aciertan',
              prefixIcon: Icon(Icons.lightbulb_outline, color: Colors.green),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ImageUploadField(
            label: 'Imagen del Quiz (opcional)',
            initialUrl: _getCtrl('quizImageUrl').text,
            initialAdjustments: _imageAdjustments['quiz.image'],
            onImageChanged: (url) {
              _getCtrl('quizImageUrl').text = url ?? '';
            },
            onAdjustmentsChanged: (value) {
              _setImageAdjustment('quiz.image', value);
            },
            aspectRatio: 1.0,
            helperText: 'Se mostrará al lado de la pregunta',
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
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildQuizOptionFields() {
    return List<Widget>.generate(_quizOptionCount, (index) {
      final optionLabel = String.fromCharCode(65 + index);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opción $optionLabel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _getCtrl('optionText_$index'),
                  decoration: InputDecoration(
                    labelText: 'Texto opción $optionLabel *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Requiere texto' : null,
                ),
                const SizedBox(height: 10),
                ImageUploadField(
                  label: 'Imagen opción $optionLabel (opcional)',
                  initialUrl: _getCtrl('optionImage_$index').text,
                  initialAdjustments: _imageAdjustments['quiz.option.$index'],
                  onImageChanged: (url) {
                    _getCtrl('optionImage_$index').text = url ?? '';
                  },
                  onAdjustmentsChanged: (value) {
                    _setImageAdjustment('quiz.option.$index', value);
                  },
                  aspectRatio: 1.0,
                  helperText: 'Se mostrará debajo del texto de esta opción',
                ),
              ],
            ),
          ),
          if (index < _quizOptionCount - 1) const SizedBox(height: 12),
        ],
      );
    });
  }

  List<Widget> _buildInteractiveAnimationFields() {
    return [
      // Tipo de interacción
      DropdownButtonFormField<String>(
        value: _animationType,
        items: const [
          DropdownMenuItem(value: 'click', child: Text('👆 Click / Tap')),
          DropdownMenuItem(
            value: 'swipe_left',
            child: Text('👈 Deslizar Izquierda'),
          ),
          DropdownMenuItem(
            value: 'swipe_right',
            child: Text('👉 Deslizar Derecha'),
          ),
          DropdownMenuItem(
            value: 'swipe_up',
            child: Text('👆 Deslizar Arriba'),
          ),
          DropdownMenuItem(
            value: 'swipe_down',
            child: Text('👇 Deslizar Abajo'),
          ),
          DropdownMenuItem(
            value: 'drag_horizontal',
            child: Text('↔️ Arrastrar Horizontal'),
          ),
          DropdownMenuItem(
            value: 'drag_vertical',
            child: Text('↕️ Arrastrar Vertical'),
          ),
          DropdownMenuItem(value: 'hold', child: Text('✋ Mantener Presionado')),
          DropdownMenuItem(
            value: 'double_tap',
            child: Text('👆👆 Doble Toque'),
          ),
          DropdownMenuItem(
            value: 'pinch_zoom',
            child: Text('🤏 Pellizcar / Zoom'),
          ),
          DropdownMenuItem(
            value: 'add_remove_objects',
            child: Text('🎨 Agregar/Quitar Objetos'),
          ),
          DropdownMenuItem(
            value: 'magnifier_reveal',
            child: Text('🔍 Lupa Reveladora'),
          ),
          DropdownMenuItem(
            value: 'object_sweep',
            child: Text('🧹 Limpiar con Objeto'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _animationType = value;
              if ((_animationType == 'add_remove_objects' ||
                      _animationType == 'magnifier_reveal' ||
                      _animationType == 'object_sweep') &&
                  (_initialAssetType == 'text' ||
                      _initialAssetType == 'video')) {
                _initialAssetType = 'image';
              }
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Tipo de Interacción *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      const SizedBox(height: 16),

      // Instrucciones para el usuario
      TextFormField(
        controller: _getCtrl('anim_instruction'),
        decoration: InputDecoration(
          labelText: 'Instrucción para el Usuario *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
          hintText: 'Ej: Toca la imagen para ver el resultado final',
          helperText: 'Mensaje que verá el usuario para saber qué hacer',
        ),
        maxLines: 2,
        validator: (v) => v?.isEmpty ?? true ? 'Requiere instrucción' : null,
      ),
      const SizedBox(height: 16),

      // Asset inicial
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎬 Contenido Inicial',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _initialAssetType,
              items:
                  (_animationType == 'magnifier_reveal' ||
                      _animationType == 'object_sweep')
                  ? const [
                      DropdownMenuItem(
                        value: 'image',
                        child: Text('🖼️ Imagen'),
                      ),
                    ]
                  : _animationType == 'add_remove_objects'
                  ? const [
                      DropdownMenuItem(
                        value: 'image',
                        child: Text('🖼️ Imagen'),
                      ),
                      DropdownMenuItem(value: 'video', child: Text('🎥 Video')),
                    ]
                  : const [
                      DropdownMenuItem(
                        value: 'image',
                        child: Text('🖼️ Imagen'),
                      ),
                      DropdownMenuItem(value: 'video', child: Text('🎥 Video')),
                      DropdownMenuItem(value: 'text', child: Text('📝 Texto')),
                    ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _initialAssetType = value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_initialAssetType == 'text')
              TextFormField(
                controller: _getCtrl('anim_initial_url'),
                decoration: InputDecoration(
                  labelText: 'Texto Inicial *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Escribe el texto inicial...',
                ),
                maxLines: 3,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Requiere texto inicial' : null,
              )
            else if (_initialAssetType == 'image')
              ImageUploadField(
                label: 'Imagen Inicial *',
                initialUrl: _getCtrl('anim_initial_url').text,
                onImageChanged: (url) {
                  _getCtrl('anim_initial_url').text = url ?? '';
                },
                aspectRatio: 16 / 9,
                required: true,
                helperText: 'Sube una imagen o importa una URL externa',
              )
            else
              TextFormField(
                controller: _getCtrl('anim_initial_url'),
                decoration: InputDecoration(
                  labelText: 'URL del Video Inicial *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'https://...',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Requiere URL inicial' : null,
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Campos específicos según tipo de animación
      if (_animationType == 'add_remove_objects')
        ..._buildAddRemoveObjectsFields()
      else if (_animationType == 'magnifier_reveal')
        ..._buildMagnifierRevealFields()
      else if (_animationType == 'object_sweep')
        ..._buildObjectSweepFields()
      else
        ..._buildStandardAnimationFields(),
    ];
  }

  List<Widget> _buildAddRemoveObjectsFields() {
    return [
      // Configuración del objeto que se agregará
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.green.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 Objeto a Agregar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configura el objeto/ícono que aparecerá donde el usuario haga click',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _objectAssetType,
              items: const [
                DropdownMenuItem(value: 'image', child: Text('🖼️ Imagen')),
                DropdownMenuItem(value: 'icon', child: Text('🔷 Ícono')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _objectAssetType = value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Tipo de Objeto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_objectAssetType == 'image')
              ImageUploadField(
                label: 'Imagen del Objeto *',
                initialUrl: _getCtrl('anim_object_url').text,
                onImageChanged: (url) {
                  _getCtrl('anim_object_url').text = url ?? '';
                },
                aspectRatio: 1.0,
                required: true,
                helperText:
                    'Usar imagen PNG con transparencia para mejor resultado',
              )
            else
              TextFormField(
                controller: _getCtrl('anim_object_url'),
                decoration: InputDecoration(
                  labelText: 'Nombre del Ícono *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'circle',
                  helperText: 'Referencia interna del ícono',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Requiere ícono' : null,
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _getCtrl('anim_object_size'),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tamaño del Objeto (px)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: '40',
                helperText: 'Tamaño en píxeles (recomendado: 30-60)',
                suffixText: 'px',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _allowRemove,
              onChanged: (value) {
                setState(() => _allowRemove = value);
              },
              title: const Text(
                'Permitir Remover',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Si está activo, tocar un objeto lo elimina',
                style: TextStyle(fontSize: 12),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'El usuario verá la imagen/video de fondo. Al hacer click en cualquier parte, aparecerá el objeto configurado en esa posición.',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildMagnifierRevealFields() {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.teal.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Capa Oculta (Revelada por Lupa)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta imagen solo se verá dentro del círculo de la lupa al arrastrarla.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ImageUploadField(
              label: 'Imagen Oculta *',
              initialUrl: _getCtrl('anim_reveal_url').text,
              onImageChanged: (url) {
                _getCtrl('anim_reveal_url').text = url ?? '';
              },
              aspectRatio: 16 / 9,
              required: true,
              helperText: 'Sube la capa que se revelará con la lupa',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blueGrey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Configuración de Lupa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Radio de lupa: ${_lensRadius.toStringAsFixed(0)} px',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _lensRadius,
              min: 24,
              max: 140,
              divisions: 58,
              label: _lensRadius.toStringAsFixed(0),
              onChanged: (value) {
                setState(() => _lensRadius = value);
              },
            ),
            Text(
              'Opacidad del borde: ${_lensOpacity.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _lensOpacity,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              label: _lensOpacity.toStringAsFixed(2),
              onChanged: (value) {
                setState(() => _lensOpacity = value);
              },
            ),
            Text(
              'Brillo de borde: ${_lensGlowRadius.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _lensGlowRadius,
              min: 0,
              max: 30,
              divisions: 30,
              label: _lensGlowRadius.toStringAsFixed(0),
              onChanged: (value) {
                setState(() => _lensGlowRadius = value);
              },
            ),
            SwitchListTile(
              value: _allowBoundaryDrag,
              onChanged: (value) {
                setState(() => _allowBoundaryDrag = value);
              },
              title: const Text(
                'Permitir mover fuera de bordes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Si está desactivado, la lupa se limita al área visible',
                style: TextStyle(fontSize: 12),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _autoResetOnRelease,
              onChanged: (value) {
                setState(() => _autoResetOnRelease = value);
              },
              title: const Text(
                'Reset automático al soltar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Regresa la lupa al centro cuando termina el drag',
                style: TextStyle(fontSize: 12),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ejemplo: fondo = mano limpia, imagen oculta = gérmenes. Al arrastrar la lupa, se revelan solo dentro del círculo.',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSweepCanvasPreview() {
    final bgUrl = _getCtrl('anim_initial_url').text.trim();
    final isSelecting = _selectedSweepObjectIndex != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = canvasW * 9 / 16;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelecting ? Colors.green.shade500 : Colors.grey.shade400,
              width: isSelecting ? 2.5 : 1,
            ),
            color: Colors.grey.shade100,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grid_on,
                    size: 15,
                    color: isSelecting
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSelecting
                          ? '🎯 Tocá el canvas para colocar el Objeto ${_selectedSweepObjectIndex! + 1}'
                          : '📐 Canvas de posicionamiento',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelecting
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelecting)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          setState(() => _selectedSweepObjectIndex = null),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTapDown: (details) {
                  if (_selectedSweepObjectIndex == null) return;
                  final local = details.localPosition;
                  setState(() {
                    _sweepObjects[_selectedSweepObjectIndex!]['nx'] =
                        (local.dx / canvasW).clamp(0.0, 1.0);
                    _sweepObjects[_selectedSweepObjectIndex!]['ny'] =
                        (local.dy / canvasH).clamp(0.0, 1.0);
                    _selectedSweepObjectIndex = null;
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: canvasW,
                    height: canvasH,
                    color: Colors.grey.shade300,
                    child: Stack(
                      children: [
                        if (bgUrl.isNotEmpty)
                          Image.network(
                            bgUrl,
                            width: canvasW,
                            height: canvasH,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Agrega primero la imagen de fondo',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        for (int i = 0; i < _sweepObjects.length; i++)
                          Positioned(
                            left:
                                ((_sweepObjects[i]['nx'] as double? ?? 0.5) *
                                            canvasW -
                                        14)
                                    .clamp(0.0, canvasW - 28),
                            top:
                                ((_sweepObjects[i]['ny'] as double? ?? 0.5) *
                                            canvasH -
                                        14)
                                    .clamp(0.0, canvasH - 28),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedSweepObjectIndex =
                                    _selectedSweepObjectIndex == i ? null : i,
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _selectedSweepObjectIndex == i
                                      ? Colors.green.shade500
                                      : Colors.orange.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (isSelecting)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.6),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca un marcador para seleccionarlo, o usa «Posicionar» en cada objeto.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildObjectSweepFields() {
    return [
      // -- Objeto limpiador --
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.deepPurple.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.deepPurple.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧹 Objeto Limpiador',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Imagen que el usuario arrastrará por la pantalla (ej: jabón, esponja, trapo).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ImageUploadField(
              label: 'Imagen del limpiador *',
              initialUrl: _getCtrl('sweep_sweeper_url').text,
              onImageChanged: (url) {
                _getCtrl('sweep_sweeper_url').text = url ?? '';
              },
              aspectRatio: 1,
              helperText: 'PNG con fondo transparente recomendado',
            ),
            const SizedBox(height: 10),
            Text(
              'Tamaño del limpiador: ${_sweeperSize.toStringAsFixed(0)} px',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _sweeperSize,
              min: 40,
              max: 200,
              divisions: 32,
              label: _sweeperSize.toStringAsFixed(0),
              onChanged: (v) => setState(() => _sweeperSize = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // -- Objetos de suciedad --
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.brown.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '💧 Objetos de Suciedad',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _sweepObjects.add({
                        'id': 'obj_${DateTime.now().millisecondsSinceEpoch}',
                        'url': '',
                        'nx': 0.5,
                        'ny': 0.5,
                        'size': 60.0,
                      });
                      _selectedSweepObjectIndex = _sweepObjects.length - 1;
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const Text(
              'Cada objeto tiene posición (X/Y en %) y tamaño. Al pasar el limpiador encima, desaparece.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            _buildSweepCanvasPreview(),
            const SizedBox(height: 8),
            if (_sweepObjects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin objetos. Presiona «Agregar» para añadir suciedad.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sweepObjects.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  final obj = _sweepObjects[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Objeto ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _selectedSweepObjectIndex =
                                  _selectedSweepObjectIndex == i ? null : i;
                            }),
                            icon: Icon(
                              Icons.my_location,
                              size: 16,
                              color: _selectedSweepObjectIndex == i
                                  ? Colors.green.shade700
                                  : Colors.blueGrey,
                            ),
                            label: Text(
                              _selectedSweepObjectIndex == i
                                  ? 'Tocá el canvas ↑'
                                  : 'Posicionar',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedSweepObjectIndex == i
                                    ? Colors.green.shade700
                                    : Colors.blueGrey,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Eliminar',
                            onPressed: () {
                              setState(() {
                                if (_selectedSweepObjectIndex == i) {
                                  _selectedSweepObjectIndex = null;
                                }
                                _sweepObjects.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                      ImageUploadField(
                        label: 'Imagen de suciedad',
                        initialUrl: obj['url']?.toString() ?? '',
                        onImageChanged: (url) {
                          setState(() => _sweepObjects[i]['url'] = url ?? '');
                        },
                        aspectRatio: 1,
                        helperText: 'PNG con fondo transparente recomendado',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pos. horizontal: ${((obj['nx'] as double? ?? 0.5) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Slider(
                        value: (obj['nx'] as double? ?? 0.5).clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label:
                            '${((obj['nx'] as double? ?? 0.5) * 100).toStringAsFixed(0)}%',
                        onChanged: (v) {
                          setState(() => _sweepObjects[i]['nx'] = v);
                        },
                      ),
                      Text(
                        'Pos. vertical: ${((obj['ny'] as double? ?? 0.5) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Slider(
                        value: (obj['ny'] as double? ?? 0.5).clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label:
                            '${((obj['ny'] as double? ?? 0.5) * 100).toStringAsFixed(0)}%',
                        onChanged: (v) {
                          setState(() => _sweepObjects[i]['ny'] = v);
                        },
                      ),
                      Text(
                        'Tamaño: ${(obj['size'] as double? ?? 60.0).toStringAsFixed(0)} px',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Slider(
                        value: (obj['size'] as double? ?? 60.0).clamp(
                          20.0,
                          200.0,
                        ),
                        min: 20,
                        max: 200,
                        divisions: 36,
                        label: (obj['size'] as double? ?? 60.0).toStringAsFixed(
                          0,
                        ),
                        onChanged: (v) {
                          setState(() => _sweepObjects[i]['size'] = v);
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ejemplo: fondo = mano sucia, limpiador = jabón, suciedad = gotas de barro. Al pasar el jabón, la mugre desaparece.',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildStandardAnimationFields() {
    return [
      // Assets de interacción
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.purple.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.purple.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '✨ Assets de Interacción',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _interactionAssets.add({
                        'type': 'image',
                        'url': '',
                        'text': '',
                      });
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Contenido que se muestra cuando el usuario realiza la interacción',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ..._interactionAssets.asMap().entries.map((entry) {
              final index = entry.key;
              final asset = entry.value;
              return _buildInteractionAssetItem(index, asset);
            }),
            if (_interactionAssets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text(
                  'No hay assets. Agrega al menos uno.',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _interactionLoop,
              onChanged: (value) {
                setState(() => _interactionLoop = value);
              },
              title: const Text(
                'Repetir secuencia (loop)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _interactionLoop
                    ? 'Cuando llega al último asset vuelve al primero'
                    : 'Cuando llega al último asset se mantiene ahí',
                style: const TextStyle(fontSize: 12),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'El usuario verá el contenido inicial. Cada interacción ($_animationType) avanza al siguiente asset en secuencia (1, 2, 3...). ${_interactionLoop ? 'Con loop: vuelve al primero.' : 'Sin loop: se queda en el último.'}',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildInteractionAssetItem(int index, Map<String, dynamic> asset) {
    final assetType = (asset['type'] ?? 'image').toString();
    final isText = assetType == 'text';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Asset ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    _interactionAssets.removeAt(index);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: assetType,
            items: const [
              DropdownMenuItem(value: 'image', child: Text('🖼️ Imagen')),
              DropdownMenuItem(value: 'video', child: Text('🎥 Video')),
              DropdownMenuItem(value: 'text', child: Text('📝 Texto')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _interactionAssets[index]['type'] = value;
                  if (value == 'text') {
                    _interactionAssets[index]['url'] = '';
                  } else {
                    _interactionAssets[index]['text'] = '';
                  }
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isText)
            TextFormField(
              key: ValueKey('interaction-$index-$assetType'),
              initialValue: (asset['text'] ?? '').toString(),
              onChanged: (value) {
                _interactionAssets[index]['text'] = value;
              },
              decoration: InputDecoration(
                labelText: 'Texto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'Texto que aparecerá en esta interacción',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 3,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Requiere texto' : null,
            )
          else if (assetType == 'image')
            ImageUploadField(
              key: ValueKey('interaction-image-$index'),
              label: 'Imagen',
              initialUrl: (asset['url'] ?? '').toString(),
              onImageChanged: (url) {
                _interactionAssets[index]['url'] = url ?? '';
              },
              aspectRatio: 16 / 9,
              required: true,
              helperText: 'Sube una imagen o importa una URL externa',
            )
          else
            TextFormField(
              key: ValueKey('interaction-video-$index'),
              initialValue: (asset['url'] ?? '').toString(),
              onChanged: (value) {
                _interactionAssets[index]['url'] = value;
              },
              decoration: InputDecoration(
                labelText: 'URL de Video',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'https://...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Requiere URL' : null,
            ),
        ],
      ),
    );
  }
}
