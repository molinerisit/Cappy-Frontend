import 'package:flutter/material.dart';
import 'dart:async';

/// Componente para renderizar animaciones interactivas en las lecciones.
/// Soporta múltiples tipos de interacción: click, swipe, drag, hold, etc.
class InteractiveAnimationCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const InteractiveAnimationCard({super.key, required this.data});

  @override
  State<InteractiveAnimationCard> createState() =>
      _InteractiveAnimationCardState();
}

class _InteractiveAnimationCardState extends State<InteractiveAnimationCard>
    with SingleTickerProviderStateMixin {
  bool _showingInteraction = false;
  double _dragPosition = 0.0;
  Timer? _holdTimer;
  late AnimationController _pulseController;

  // Estado para add_remove_objects
  final List<Offset> _addedObjects = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _animationType =>
      widget.data['animationType']?.toString() ?? 'click';
  String get _instruction => widget.data['instruction']?.toString() ?? '';
  Map<String, dynamic> get _initialAsset =>
      _normalizeAsset(widget.data['initialAsset']);
  Map<String, dynamic> get _objectAsset =>
      _normalizeAsset(widget.data['objectAsset']);
  List<dynamic> get _interactionAssets =>
      widget.data['interactionAssets'] is List
      ? List<dynamic>.from(widget.data['interactionAssets'])
      : const [];

  Map<String, dynamic>? get _currentInteractionAsset {
    if (_interactionAssets.isEmpty) return null;
    final first = _interactionAssets[0];
    if (first is Map && first['asset'] != null) {
      return _normalizeAsset(first['asset']);
    }
    return _normalizeAsset(first);
  }

  Map<String, dynamic> _normalizeAsset(dynamic raw) {
    if (raw is Map) {
      return {
        'type': raw['type']?.toString() ?? 'image',
        'url': raw['url']?.toString() ?? '',
      };
    }
    if (raw is String) {
      return {'type': 'image', 'url': raw};
    }
    return {'type': 'image', 'url': ''};
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  void _handleClick() {
    if (_animationType == 'click' || _animationType == 'double_tap') {
      setState(() {
        _showingInteraction = !_showingInteraction;
      });
    }
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;

    if (_animationType == 'swipe_left' && velocity.dx < -500) {
      _showInteraction();
    } else if (_animationType == 'swipe_right' && velocity.dx > 500) {
      _showInteraction();
    } else if (_animationType == 'swipe_up' && velocity.dy < -500) {
      _showInteraction();
    } else if (_animationType == 'swipe_down' && velocity.dy > 500) {
      _showInteraction();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_animationType == 'drag_horizontal') {
      setState(() {
        _dragPosition = (details.localPosition.dx / 300).clamp(0.0, 1.0);
        _showingInteraction = _dragPosition > 0.5;
      });
    } else if (_animationType == 'drag_vertical') {
      setState(() {
        _dragPosition = (details.localPosition.dy / 300).clamp(0.0, 1.0);
        _showingInteraction = _dragPosition > 0.5;
      });
    }
  }

  void _handleLongPressStart() {
    if (_animationType == 'hold') {
      _holdTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _showingInteraction = true;
        });
      });
    }
  }

  void _handleLongPressEnd() {
    if (_animationType == 'hold') {
      _holdTimer?.cancel();
      setState(() {
        _showingInteraction = false;
      });
    }
  }

  void _showInteraction() {
    setState(() {
      _showingInteraction = true;
    });

    // Auto-return después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showingInteraction = false;
        });
      }
    });
  }

  void _handleAddRemoveObjectTap(TapDownDetails details) {
    final allowRemove = _toBool(widget.data['allowRemove']);
    final maxObjects = _toInt(
      (widget.data['config'] as Map?)?['maxObjects'],
      fallback: 50,
    );
    final position = details.localPosition;

    // Verificar si el tap está cerca de un objeto existente
    if (allowRemove) {
      for (int i = _addedObjects.length - 1; i >= 0; i--) {
        final objPos = _addedObjects[i];
        final distance = (objPos - position).distance;
        final objectSize = _toDouble(widget.data['objectSize'], fallback: 40);

        if (distance < objectSize / 2) {
          // Remover objeto si está cerca
          setState(() {
            _addedObjects.removeAt(i);
          });
          return;
        }
      }
    }

    // Agregar nuevo objeto si no se alcanzó el límite
    if (_addedObjects.length < maxObjects) {
      setState(() {
        _addedObjects.add(position);
      });
    }
  }

  Widget _buildAsset(Map<String, dynamic> asset) {
    final type = asset['type']?.toString() ?? 'image';
    final url = asset['url']?.toString() ?? '';

    if (url.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text('Sin contenido'),
      );
    }

    if (type == 'image') {
      return Image.network(
        url,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar imagen',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (type == 'video') {
      // TODO: Implementar video player cuando sea necesario
      return Container(
        height: 300,
        color: Colors.black87,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              'Video: $url',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildInstructionOverlay() {
    if (_instruction.isEmpty) return const SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.6 + (_pulseController.value * 0.4),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
          child: Row(
            children: [
              _buildGestureIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureIcon() {
    IconData icon;
    switch (_animationType) {
      case 'click':
        icon = Icons.touch_app;
        break;
      case 'swipe_left':
        icon = Icons.arrow_back;
        break;
      case 'swipe_right':
        icon = Icons.arrow_forward;
        break;
      case 'swipe_up':
        icon = Icons.arrow_upward;
        break;
      case 'swipe_down':
        icon = Icons.arrow_downward;
        break;
      case 'drag_horizontal':
        icon = Icons.swap_horiz;
        break;
      case 'drag_vertical':
        icon = Icons.swap_vert;
        break;
      case 'hold':
        icon = Icons.timer;
        break;
      case 'double_tap':
        icon = Icons.touch_app;
        break;
      case 'pinch_zoom':
        icon = Icons.zoom_out_map;
        break;
      default:
        icon = Icons.touch_app;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Modo especial para add_remove_objects
    if (_animationType == 'add_remove_objects') {
      return _buildAddRemoveMode();
    }

    // Modo estándar para otros tipos de animación
    final currentAsset = _showingInteraction
        ? _currentInteractionAsset
        : _initialAsset;

    if (currentAsset == null) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text('Configuración incompleta'),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Asset (imagen o video)
            GestureDetector(
              onTap: _animationType == 'click' ? _handleClick : null,
              onDoubleTap: _animationType == 'double_tap' ? _handleClick : null,
              onHorizontalDragEnd: _animationType.startsWith('swipe_')
                  ? _handleSwipe
                  : null,
              onVerticalDragEnd: _animationType.startsWith('swipe_')
                  ? _handleSwipe
                  : null,
              onHorizontalDragUpdate: _animationType == 'drag_horizontal'
                  ? _handleDragUpdate
                  : null,
              onVerticalDragUpdate: _animationType == 'drag_vertical'
                  ? _handleDragUpdate
                  : null,
              onLongPressStart: _animationType == 'hold'
                  ? (_) => _handleLongPressStart()
                  : null,
              onLongPressEnd: _animationType == 'hold'
                  ? (_) => _handleLongPressEnd()
                  : null,
              child: _buildAsset(currentAsset),
            ),

            // Overlay de instrucciones
            if (!_showingInteraction) _buildInstructionOverlay(),

            // Indicador de drag (opcional)
            if (_animationType.startsWith('drag_') && _dragPosition > 0)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 4,
                  color: Colors.white.withOpacity(0.7),
                  child: FractionallySizedBox(
                    alignment: Alignment.topCenter,
                    heightFactor: _dragPosition,
                    child: Container(color: Colors.purple),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRemoveMode() {
    final backgroundAsset = _initialAsset;
    final objectAsset = _objectAsset;
    final objectSize = _toDouble(widget.data['objectSize'], fallback: 40);
    final allowRemove = _toBool(widget.data['allowRemove']);
    final objectType = objectAsset['type']?.toString() ?? 'image';
    final objectUrl = objectAsset['url']?.toString() ?? '';

    if (backgroundAsset['url'] == null || backgroundAsset['url'] == '') {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text(
          'Configuración incompleta: falta background u objeto',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Imagen de fondo
            GestureDetector(
              onTapDown: _handleAddRemoveObjectTap,
              child: _buildAsset(backgroundAsset),
            ),

            // Objetos colocados
            ..._addedObjects.map((position) {
              return Positioned(
                left: position.dx - objectSize / 2,
                top: position.dy - objectSize / 2,
                child: objectType == 'icon'
                    ? Icon(
                        Icons.circle,
                        size: objectSize,
                        color: Colors.purple.withOpacity(0.85),
                      )
                    : Image.network(
                        objectUrl,
                        width: objectSize,
                        height: objectSize,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.circle,
                          size: objectSize,
                          color: Colors.purple.withOpacity(0.7),
                        ),
                      ),
              );
            }).toList(),

            // Instrucciones overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  allowRemove
                      ? 'Toca para agregar objetos. Toca un objeto para quitarlo.'
                      : 'Toca para agregar objetos',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
