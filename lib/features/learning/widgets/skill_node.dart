import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NodeStatus { completed, active, locked }

class SkillNode extends StatefulWidget {
  final String nodeId;
  final String title;
  final int xpReward;
  final NodeStatus status;
  final String nodeType;
  final VoidCallback? onTap;
  final int index;

  const SkillNode({
    super.key,
    required this.nodeId,
    required this.title,
    required this.xpReward,
    required this.status,
    required this.nodeType,
    this.onTap,
    required this.index,
  });

  @override
  State<SkillNode> createState() => _SkillNodeState();
}

class _SkillNodeState extends State<SkillNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animación de pulso para nodos activos
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Si es activo, iniciar pulso continuo
    if (widget.status == NodeStatus.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.status != NodeStatus.locked && widget.onTap != null) {
      _controller.stop();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.status != NodeStatus.locked) {
      _controller.reverse();
      if (widget.status == NodeStatus.active) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _controller.repeat(reverse: true);
        });
      }
    }
  }

  void _handleTapCancel() {
    if (widget.status != NodeStatus.locked) {
      _controller.reverse();
      if (widget.status == NodeStatus.active) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _controller.repeat(reverse: true);
        });
      }
    }
  }

  IconData _getCulinaryIcon() {
    // Iconos culinarios únicos según el tipo
    switch (widget.nodeType) {
      case 'recipe':
        return Icons.restaurant_rounded; // Sartén/cocina
      case 'skill':
        return Icons.local_fire_department_rounded; // Fuego
      case 'quiz':
        return Icons.spa_rounded; // Especias
      case 'technique':
        return Icons.cut_rounded; // Cuchillo
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Color _getNodeColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return const Color(0xFF27AE60);
      case NodeStatus.active:
        return const Color(0xFFFF6B35);
      case NodeStatus.locked:
        return const Color(0xFFD1D5DB);
    }
  }

  Color _getBackgroundColor() {
    switch (widget.status) {
      case NodeStatus.completed:
        return const Color(0xFFD1FAE5);
      case NodeStatus.active:
        return const Color(0xFFFFF3E0);
      case NodeStatus.locked:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nodo circular principal con efecto glow
          ScaleTransition(
            scale: widget.status == NodeStatus.active
                ? _pulseAnimation
                : _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect para nodos activos
                if (widget.status == NodeStatus.active)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                // Nodo principal
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getBackgroundColor(),
                    border: Border.all(color: _getNodeColor(), width: 4),
                    boxShadow: widget.status != NodeStatus.locked
                        ? [
                            BoxShadow(
                              color: _getNodeColor().withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.status != NodeStatus.locked
                          ? widget.onTap
                          : null,
                      borderRadius: BorderRadius.circular(45),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Icono principal
                          Icon(
                            _getCulinaryIcon(),
                            size: 40,
                            color: _getNodeColor(),
                          ),

                          // Overlay para completado o bloqueado
                          if (widget.status == NodeStatus.completed)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),

                          if (widget.status == NodeStatus.locked)
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Título del nodo
          SizedBox(
            width: 120,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.status == NodeStatus.locked
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF1F2937),
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Badge de XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getNodeColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 14, color: _getNodeColor()),
                const SizedBox(width: 4),
                Text(
                  '+${widget.xpReward} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getNodeColor(),
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
