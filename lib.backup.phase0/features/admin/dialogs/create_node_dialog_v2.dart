import 'package:flutter/material.dart';
import '../../../core/api_service.dart';

class CreateNodeDialogV2 extends StatefulWidget {
  final String? pathId;
  final VoidCallback onSaved;

  const CreateNodeDialogV2({super.key, this.pathId, required this.onSaved});

  @override
  State<CreateNodeDialogV2> createState() => _CreateNodeDialogV2State();
}

class _CreateNodeDialogV2State extends State<CreateNodeDialogV2> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _levelCtrl = TextEditingController(text: '1');
  final _positionCtrl = TextEditingController(text: '1');
  final _xpCtrl = TextEditingController(text: '0');

  List<dynamic> _paths = [];
  List<dynamic> _groups = [];

  String? _selectedPathId;
  String? _selectedGroupId;
  String _nodeType = 'recipe';
  String _status = 'active';
  bool _isLoading = false;
  bool _isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _loadPaths();
    _selectedPathId = widget.pathId;
    if (widget.pathId != null) {
      _loadGroups(widget.pathId!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _levelCtrl.dispose();
    _positionCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoading = true);
    try {
      final paths = await ApiService.adminGetAllLearningPaths();
      setState(() => _paths = paths);
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

  Future<void> _loadGroups(String pathId) async {
    setState(() => _isLoadingGroups = true);
    try {
      final groups = await ApiService.adminGetGroupsByPath(pathId);
      setState(() => _groups = groups);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando grupos: $e')));
      }
    } finally {
      setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _openCreateGroupDialog() async {
    if (_selectedPathId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un camino primero.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titulo del grupo'),
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
      await _loadGroups(_selectedPathId!);
      if (mounted && group is Map) {
        setState(() => _selectedGroupId = group['_id']?.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creando grupo: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPathId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un camino.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'pathId': _selectedPathId,
        'title': _titleCtrl.text.trim(),
        'type': _nodeType,
        'status': _status,
        'level': int.tryParse(_levelCtrl.text) ?? 1,
        'positionIndex': int.tryParse(_positionCtrl.text) ?? 1,
        'xpReward': int.tryParse(_xpCtrl.text) ?? 0,
      };

      // groupId es opcional - si se selecciona, se incluye
      if (_selectedGroupId != null) {
        payload['groupId'] = _selectedGroupId;
      }

      await ApiService.adminCreateContentNode(payload);

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nodo creado correctamente.')),
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
      title: const Text('Crear nodo'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPathId,
                  items: _paths
                      .map(
                        (path) => DropdownMenuItem(
                          value:
                              path['_id']?.toString() ?? path['id']?.toString(),
                          child: Text(path['title'] ?? 'Sin titulo'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPathId = value;
                      _selectedGroupId = null;
                      _groups = [];
                    });
                    if (value != null) {
                      _loadGroups(value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Camino'),
                  validator: (value) => value == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                if (_isLoadingGroups)
                  const LinearProgressIndicator()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        items: _groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group['_id']?.toString(),
                                child: Text(group['title'] ?? 'Sin titulo'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedGroupId = value),
                        decoration: const InputDecoration(labelText: 'Grupo'),
                        validator: (value) =>
                            value == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _openCreateGroupDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear grupo'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _nodeType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
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
                    DropdownMenuItem(
                      value: 'cultural',
                      child: Text('Cultural'),
                    ),
                    DropdownMenuItem(
                      value: 'challenge',
                      child: Text('Challenge'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _nodeType = value ?? 'recipe'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Archived'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _levelCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Level'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _positionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _xpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'XP Reward'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
