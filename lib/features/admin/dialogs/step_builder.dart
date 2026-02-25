import 'package:flutter/material.dart';

// ==========================================
// ADD STEP DIALOG V2: Pasos estilo Duolingo con múltiples cards
// ==========================================
class AddStepDialogV2 extends StatefulWidget {
  final String stepType;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? existingStep;

  const AddStepDialogV2({
    super.key,
    required this.stepType,
    required this.onSave,
    this.existingStep,
  });

  @override
  State<AddStepDialogV2> createState() => _AddStepDialogV2State();
}

class _AddStepDialogV2State extends State<AddStepDialogV2>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1');

  late String _stepType;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _stepType = widget.stepType;
    _tabController = TabController(length: 2, vsync: this);

    // Pre-cargar datos si es edición
    if (widget.existingStep != null) {
      _titleCtrl.text = widget.existingStep!['title'] ?? '';
      _descCtrl.text = widget.existingStep!['description'] ?? '';
      _durationCtrl.text = (widget.existingStep!['duration'] ?? 1).toString();
      _stepType = widget.existingStep!['type'] ?? widget.stepType;

      // Pre-cargar cards existentes
      if (widget.existingStep!['cards'] is List) {
        _cards = List<Map<String, dynamic>>.from(
          (widget.existingStep!['cards'] as List).map((card) {
            if (card is Map) {
              return Map<String, dynamic>.from(card);
            }
            return <String, dynamic>{};
          }),
        );
      }
    }

    if (!const {
      'text',
      'quiz',
      'fill-blank',
      'listen',
      'match',
      'arrange',
    }.contains(_stepType)) {
      _stepType = 'text';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _addCard() {
    if (_cards.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Máximo 6 tarjetas por paso')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddCardDialog(
        stepType: _stepType,
        cardIndex: _cards.length + 1,
        onSave: (card) {
          setState(() => _cards.add(card));
        },
      ),
    );
  }

  void _deleteCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  void _editCard(int index) {
    showDialog(
      context: context,
      builder: (context) => AddCardDialog(
        stepType: _stepType,
        cardIndex: index + 1,
        existingCard: _cards[index],
        onSave: (updatedCard) {
          setState(() => _cards[index] = updatedCard);
        },
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título del paso es requerido')),
      );
      return;
    }

    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una tarjeta al paso')),
      );
      return;
    }

    widget.onSave({
      'title': _titleCtrl.text,
      'description': _descCtrl.text,
      'type': _stepType,
      'duration': int.tryParse(_durationCtrl.text) ?? 1,
      'cards': _cards,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.purple.shade700,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.layers, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Paso (Duolingo Style)',
                      style: TextStyle(
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
            // TabBar
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(icon: Icon(Icons.info), text: 'Info Paso'),
                Tab(
                  icon: const Icon(Icons.style),
                  text: 'Tarjetas (${_cards.length}/6)',
                ),
              ],
            ),
            // TabView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildInfoTab(), _buildCardsTab()],
              ),
            ),
            // Acciones
            Padding(
              padding: const EdgeInsets.all(16),
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
                    label: const Text('Crear Paso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Título del Paso',
              hintText: 'ej. Aprender a picar cebolla',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: 'Breve descripción del paso',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _stepType,
            items: const [
              DropdownMenuItem(
                value: 'text',
                child: Text('📝 Lectura / Texto'),
              ),
              DropdownMenuItem(
                value: 'quiz',
                child: Text('❓ Quiz / Opción múltiple'),
              ),
              DropdownMenuItem(
                value: 'fill-blank',
                child: Text('✏️ Completar espacios'),
              ),
              DropdownMenuItem(value: 'listen', child: Text('🎧 Escuchar')),
              DropdownMenuItem(value: 'match', child: Text('🔗 Emparejar')),
              DropdownMenuItem(value: 'arrange', child: Text('📊 Ordenar')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _stepType = value);
            },
            decoration: const InputDecoration(
              labelText: 'Tipo de Paso',
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duración',
              suffixText: 'minutos',
              prefixIcon: Icon(Icons.schedule),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarjetas (${_cards.length}/6)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Tarjeta'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cards.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🎴 Sin tarjetas. Agrega al menos una para crear el paso.',
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _CardPreview(
                  card: card,
                  index: index + 1,
                  onEdit: () => _editCard(index),
                  onDelete: () => _deleteCard(index),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==========================================
// CARD PREVIEW: Vista previa de una tarjeta
// ==========================================
class _CardPreview extends StatelessWidget {
  final Map<String, dynamic> card;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardPreview({
    required this.card,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String _getCardTypeIcon(String type) {
    switch (type) {
      case 'text':
        return '📝';
      case 'image':
        return '🖼️';
      case 'audio':
        return '🎧';
      case 'quiz':
        return '❓';
      case 'fill-blank':
        return '✏️';
      case 'animation':
        return '🎬';
      case 'video':
        return '🎥';
      case 'timer':
        return '⏱️';
      default:
        return '📌';
    }
  }

  String _getCardPreview(Map<String, dynamic> card) {
    final type = card['type'] ?? 'text';
    final content = card['content'] ?? {};

    switch (type) {
      case 'text':
        return content['text'] ?? 'Sin contenido';
      case 'image':
        return content['imageUrl'] ?? 'Sin imagen';
      case 'audio':
        return content['audioUrl'] ?? 'Sin audio';
      case 'video':
        return content['videoUrl'] ?? 'Sin video';
      case 'animation':
        return content['animationUrl'] ?? 'Sin animación';
      case 'quiz':
        final question = content['question'] ?? 'Sin pregunta';
        final options = content['options'] as List? ?? [];
        return '$question (${options.length} opciones)';
      case 'fill-blank':
        return content['sentence'] ?? 'Sin frase';
      case 'timer':
        return '${content['duration'] ?? 0} seg';
      default:
        return 'Sin preview';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(
            index.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          card['content']?['title'] ?? 'Tarjeta sin título',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_getCardTypeIcon(card['type'] ?? 'text')} ${card['type'] ?? 'unknown'}',
              style: const TextStyle(fontSize: 12),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _getCardPreview(card).length > 50
                    ? '${_getCardPreview(card).substring(0, 50)}...'
                    : _getCardPreview(card),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: 'Editar tarjeta',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Eliminar tarjeta',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ADD CARD DIALOG: Agregar una tarjeta a un paso
// ==========================================
class AddCardDialog extends StatefulWidget {
  final String stepType;
  final int cardIndex;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? existingCard;

  const AddCardDialog({
    super.key,
    required this.stepType,
    required this.cardIndex,
    required this.onSave,
    this.existingCard,
  });

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  late String _cardType;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores generales
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _cardType = widget.stepType;

    // Pre-cargar datos si es edición
    if (widget.existingCard != null) {
      _cardType = widget.existingCard!['type'] ?? widget.stepType;
    }

    if (!const {
      'text',
      'image',
      'audio',
      'video',
      'animation',
      'quiz',
      'fill-blank',
      'timer',
    }.contains(_cardType)) {
      _cardType = 'text';
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final card = _buildCardData();
    if (card != null) {
      widget.onSave(card);
      Navigator.pop(context);
    }
  }

  Map<String, dynamic>? _buildCardData() {
    switch (_cardType) {
      case 'text':
        return {
          'type': 'text',
          'order': widget.cardIndex,
          'content': {
            'title': _getCtrl('title').text,
            'text': _getCtrl('text').text,
          },
        };
      case 'image':
        return {
          'type': 'image',
          'order': widget.cardIndex,
          'content': {
            'title': _getCtrl('title').text,
            'imageUrl': _getCtrl('imageUrl').text,
          },
        };
      case 'audio':
        return {
          'type': 'audio',
          'order': widget.cardIndex,
          'content': {
            'title': _getCtrl('title').text,
            'audioUrl': _getCtrl('audioUrl').text,
            'transcription': _getCtrl('transcription').text,
          },
        };
      case 'video':
        return {
          'type': 'video',
          'order': widget.cardIndex,
          'content': {
            'title': _getCtrl('title').text,
            'videoUrl': _getCtrl('videoUrl').text,
          },
        };
      case 'animation':
        return {
          'type': 'animation',
          'order': widget.cardIndex,
          'content': {
            'title': _getCtrl('title').text,
            'animationUrl': _getCtrl('animationUrl').text,
          },
        };
      case 'quiz':
        return {
          'type': 'quiz',
          'order': widget.cardIndex,
          'content': {
            'question': _getCtrl('question').text,
            'options': [
              {
                'text': _getCtrl('option0').text,
                'imageUrl': _getCtrl('optionImage0').text,
                'correct': _getCtrl('correct').text == '0',
              },
              {
                'text': _getCtrl('option1').text,
                'imageUrl': _getCtrl('optionImage1').text,
                'correct': _getCtrl('correct').text == '1',
              },
              {
                'text': _getCtrl('option2').text,
                'imageUrl': _getCtrl('optionImage2').text,
                'correct': _getCtrl('correct').text == '2',
              },
              {
                'text': _getCtrl('option3').text,
                'imageUrl': _getCtrl('optionImage3').text,
                'correct': _getCtrl('correct').text == '3',
              },
            ],
          },
        };
      case 'timer':
        return {
          'type': 'timer',
          'order': widget.cardIndex,
          'content': {'duration': int.tryParse(_getCtrl('duration').text) ?? 0},
        };
      case 'fill-blank':
        final sentence = _getCtrl('sentence').text;
        final blanks = RegExp(r'_+').allMatches(sentence).length;
        return {
          'type': 'fill-blank',
          'order': widget.cardIndex,
          'content': {
            'sentence': sentence,
            'answers': [
              for (int i = 0; i < blanks; i++) _getCtrl('answer$i').text,
            ],
          },
        };
      default:
        return null;
    }
  }

  TextEditingController _getCtrl(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();

      // Pre-cargar datos si es edición
      if (widget.existingCard != null) {
        final content = widget.existingCard!['content'] as Map? ?? {};

        switch (key) {
          case 'title':
            _controllers[key]!.text = content['title'] ?? '';
            break;
          case 'text':
            _controllers[key]!.text = content['text'] ?? '';
            break;
          case 'imageUrl':
            _controllers[key]!.text = content['imageUrl'] ?? '';
            break;
          case 'audioUrl':
            _controllers[key]!.text = content['audioUrl'] ?? '';
            break;
          case 'transcription':
            _controllers[key]!.text = content['transcription'] ?? '';
            break;
          case 'videoUrl':
            _controllers[key]!.text = content['videoUrl'] ?? '';
            break;
          case 'animationUrl':
            _controllers[key]!.text = content['animationUrl'] ?? '';
            break;
          case 'question':
            _controllers[key]!.text = content['question'] ?? '';
            break;
          case 'sentence':
            _controllers[key]!.text = content['sentence'] ?? '';
            break;
          case 'duration':
            _controllers[key]!.text = (content['duration'] ?? '').toString();
            break;
          default:
            if (key.startsWith('option')) {
              final optionIndex = int.tryParse(key.replaceAll('option', ''));
              if (optionIndex != null && content['options'] is List) {
                final options = content['options'] as List;
                if (optionIndex < options.length) {
                  _controllers[key]!.text =
                      (options[optionIndex] as Map?)?['text'] ?? '';
                }
              }
            } else if (key.startsWith('optionImage')) {
              final optionIndex = int.tryParse(
                key.replaceAll('optionImage', ''),
              );
              if (optionIndex != null && content['options'] is List) {
                final options = content['options'] as List;
                if (optionIndex < options.length) {
                  _controllers[key]!.text =
                      (options[optionIndex] as Map?)?['imageUrl'] ?? '';
                }
              }
            } else if (key.startsWith('correct')) {
              if (content['options'] is List) {
                final options = content['options'] as List;
                for (int i = 0; i < options.length; i++) {
                  if ((options[i] as Map?)?['correct'] == true) {
                    _controllers[key]!.text = '$i';
                    break;
                  }
                }
              }
            } else if (key.startsWith('answer')) {
              final answerIndex = int.tryParse(key.replaceAll('answer', ''));
              if (answerIndex != null && content['answers'] is List) {
                final answers = content['answers'] as List;
                if (answerIndex < answers.length) {
                  _controllers[key]!.text = answers[answerIndex] ?? '';
                }
              }
            }
        }
      }
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('🎴 Tarjeta ${widget.cardIndex}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _cardType,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('📝 Texto')),
                  DropdownMenuItem(value: 'image', child: Text('🖼️ Imagen')),
                  DropdownMenuItem(value: 'audio', child: Text('🎧 Audio')),
                  DropdownMenuItem(value: 'video', child: Text('🎥 Video')),
                  DropdownMenuItem(
                    value: 'animation',
                    child: Text('🎬 Animación'),
                  ),
                  DropdownMenuItem(value: 'quiz', child: Text('❓ Quiz')),
                  DropdownMenuItem(
                    value: 'fill-blank',
                    child: Text('✏️ Llenar Blancos'),
                  ),
                  DropdownMenuItem(value: 'timer', child: Text('⏱️ Timer')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _cardType = value;
                      _controllers.clear();
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Tipo de Tarjeta'),
              ),
              const SizedBox(height: 16),
              ..._buildCardFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveCard,
          child: const Text('Agregar Tarjeta'),
        ),
      ],
    );
  }

  List<Widget> _buildCardFields() {
    switch (_cardType) {
      case 'text':
        return [
          TextFormField(
            controller: _getCtrl('title'),
            decoration: const InputDecoration(
              labelText: 'Título (opcional)',
              hintText: 'ej. Introducción',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('text'),
            decoration: const InputDecoration(
              labelText: 'Contenido de texto',
              hintText: 'Escribe el contenido',
            ),
            maxLines: 3,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere contenido' : null,
          ),
        ];
      case 'image':
        return [
          TextFormField(
            controller: _getCtrl('title'),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('imageUrl'),
            decoration: const InputDecoration(
              labelText: 'URL de imagen',
              hintText: 'https://...',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere URL' : null,
          ),
        ];
      case 'audio':
        return [
          TextFormField(
            controller: _getCtrl('title'),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('audioUrl'),
            decoration: const InputDecoration(
              labelText: 'URL de audio',
              hintText: 'https://...',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere URL' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('transcription'),
            decoration: const InputDecoration(
              labelText: 'Transcripción (opcional)',
            ),
            maxLines: 2,
          ),
        ];
      case 'video':
        return [
          TextFormField(
            controller: _getCtrl('title'),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('videoUrl'),
            decoration: const InputDecoration(
              labelText: 'URL de video',
              hintText: 'https://...',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere URL' : null,
          ),
        ];
      case 'animation':
        return [
          TextFormField(
            controller: _getCtrl('title'),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _getCtrl('animationUrl'),
            decoration: const InputDecoration(
              labelText: 'Archivo (.json Lottie)',
              hintText: 'https://...',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere URL' : null,
          ),
        ];
      case 'quiz':
        if (!_controllers.containsKey('correct')) {
          _getCtrl('correct').text = '0';
        }
        return [
          TextFormField(
            controller: _getCtrl('question'),
            decoration: const InputDecoration(
              labelText: 'Pregunta',
              hintText: '¿Cuál es la técnica correcta?',
            ),
            maxLines: 2,
            validator: (v) => v?.isEmpty ?? true ? 'Requiere pregunta' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Opciones (marca la correcta):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildQuizOptions(),
        ];
      case 'fill-blank':
        return [
          TextFormField(
            controller: _getCtrl('sentence'),
            decoration: const InputDecoration(
              labelText: 'Frase con blancos',
              hintText: 'La _____ se pica en _____',
            ),
            maxLines: 2,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Requiere frase';
              if (!v!.contains('_')) return 'Usa _____ para blancos';
              return null;
            },
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          ..._buildBlankAnswers(),
        ];
      case 'timer':
        return [
          TextFormField(
            controller: _getCtrl('duration'),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duracion',
              suffixText: 'seg',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requiere duracion' : null,
          ),
          const SizedBox(height: 8),
          const Text(
            'El timer se renderiza como widget fijo en la app.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildQuizOptions() {
    return [
      for (int i = 0; i < 4; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Radio<String>(
                value: '$i',
                groupValue: _getCtrl('correct').text,
                onChanged: (val) {
                  setState(() => _getCtrl('correct').text = val ?? '0');
                },
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _getCtrl('option$i'),
                    decoration: InputDecoration(
                      labelText: 'Texto Opción ${i + 1}',
                      hintText: 'Escribe la opción ${i + 1}',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _getCtrl('optionImage$i'),
                    decoration: InputDecoration(
                      labelText: 'URL Imagen (opcional)',
                      hintText: 'https://... (opcional)',
                      prefixIcon: const Icon(Icons.image, size: 20),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selecciona la opción correcta marcando el círculo. Las imágenes son opcionales.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildBlankAnswers() {
    final sentence = _getCtrl('sentence').text;
    final blanks = RegExp(r'_+').allMatches(sentence).length;

    if (blanks == 0) {
      return [
        const Text(
          'Usa _____ en la frase para crear blancos',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ];
    }

    return [
      Text(
        'Respuestas para los $blanks blancos:',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      for (int i = 0; i < blanks; i++) ...[
        TextFormField(
          controller: _getCtrl('answer$i'),
          decoration: InputDecoration(
            labelText: 'Respuesta ${i + 1}',
            hintText: 'Respuesta para blanco ${i + 1}',
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}
