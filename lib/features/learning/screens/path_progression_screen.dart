import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_service.dart';
import '../../../core/models/learning_node.dart';
import '../screens/lesson_game_screen.dart';
import '../widgets/skill_node.dart';
import '../widgets/path_connector_painter.dart';
import '../../../widgets/user_xp_badge.dart';

class PathProgressionScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;

  const PathProgressionScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
  });

  @override
  State<PathProgressionScreen> createState() => _PathProgressionScreenState();
}

class _PathProgressionScreenState extends State<PathProgressionScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> futurePathData;
  final List<Offset> nodePositions = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    futurePathData = ApiService.getPath(widget.pathId);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startLesson(
    String nodeId,
    String title,
    String nodeType,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF27AE60)),
      ),
    );

    try {
      final nodeData = await ApiService.getLearningNode(nodeId);

      if (!mounted) return;
      Navigator.of(context).pop();

      // Convertir nodeData a LearningNode
      final learningNode = LearningNode.fromJson(nodeData);

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonGameScreen(node: learningNode),
        ),
      );

      if (result == true && mounted) {
        setState(() {
          futurePathData = ApiService.getPath(widget.pathId);
          _fadeController.reset();
          _fadeController.forward();
        });
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar la lección: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  NodeStatus _getNodeStatus(String status) {
    switch (status) {
      case 'completed':
        return NodeStatus.completed;
      case 'locked':
        return NodeStatus.locked;
      default:
        return NodeStatus.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futurePathData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF27AE60)),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState();
          }

          final pathData = snapshot.data!;
          final nodes = pathData['nodes'] as List<dynamic>? ?? [];

          if (nodes.isEmpty) {
            return _buildEmptyState();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildNodePath(nodes),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        color: const Color(0xFF6B7280),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      title: Text(
        widget.pathTitle,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Center(child: UserXPBadge()),
        ),
      ],
    );
  }

  Widget _buildNodePath(List<dynamic> nodes) {
    // Calcular estadísticas
    final completedCount = nodes
        .where((n) => n['status'] == 'completed')
        .length;
    final totalCount = nodes.length;
    final progressPercent = totalCount > 0
        ? (completedCount / totalCount * 100).toStringAsFixed(0)
        : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final leftX = width * 0.25;
        final rightX = width * 0.75;
        final verticalSpacing = 180.0;

        // Calcular posiciones de nodos
        nodePositions.clear();
        for (int i = 0; i < nodes.length; i++) {
          final isLeft = i % 2 == 0;
          final x = isLeft ? leftX : rightX;
          final y = 120.0 + (i * verticalSpacing);
          nodePositions.add(Offset(x, y));
        }

        return Stack(
          children: [
            // Contenido scrolleable
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 120, bottom: 80),
              child: SizedBox(
                height: nodes.isNotEmpty ? 40.0 + (nodes.length * 180.0) : 0,
                child: Stack(
                  children: [
                    // Dibujar conexiones primero (detrás de los nodos)
                    if (nodePositions.length > 1)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PathConnectorPainter(
                            nodePositions: nodePositions,
                            lineColor: const Color(0xFFE5E7EB),
                            strokeWidth: 5,
                          ),
                        ),
                      ),

                    // Puntos decorativos en las conexiones
                    if (nodePositions.length > 1)
                      ...List.generate(nodePositions.length - 1, (index) {
                        final start = nodePositions[index];
                        final end = nodePositions[index + 1];
                        final midX = (start.dx + end.dx) / 2;
                        final midY = (start.dy + end.dy) / 2;

                        return Positioned(
                          left: midX - 6,
                          top: midY - 6,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 600 + (index * 150),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE5E7EB),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                    // Dibujar nodos encima
                    ...List.generate(nodes.length, (index) {
                      if (index >= nodePositions.length) {
                        return const SizedBox.shrink();
                      }

                      try {
                        final node = nodes[index] as Map<String, dynamic>?;
                        if (node == null) {
                          return const SizedBox.shrink();
                        }

                        final nodeId =
                            (node['_id'] ?? node['id'] ?? '') as String;
                        final title =
                            (node['title'] ?? 'Nodo ${index + 1}') as String;
                        final xpReward = (node['xpReward'] ?? 0) as int;
                        final status = _getNodeStatus(
                          (node['status'] ?? 'locked') as String,
                        );
                        final nodeType = (node['type'] ?? 'recipe') as String;

                        final position = nodePositions[index];

                        return Positioned(
                          left: position.dx - 60, // Centrar el nodo (120/2)
                          top: position.dy - 45, // Centrar verticalmente
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(nodeId),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: SkillNode(
                              nodeId: nodeId,
                              title: title,
                              xpReward: xpReward,
                              status: status,
                              nodeType: nodeType,
                              index: index,
                              onTap: status != NodeStatus.locked
                                  ? () => _startLesson(nodeId, title, nodeType)
                                  : null,
                            ),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error renderizando nodo $index: $e');
                        return const SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              ),
            ),

            // Header flotante con estadísticas
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icono de progreso
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: completedCount / totalCount,
                                strokeWidth: 4,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF27AE60),
                                ),
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información de progreso
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu Progreso',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completedCount de $totalCount lecciones',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de motivación
                      if (completedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD93D), Color(0xFFFFA800)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '¡Sigue así!',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "¡Oops! Algo salió mal",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No pudimos cargar el camino de aprendizaje",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  futurePathData = ApiService.getPath(widget.pathId);
                  _fadeController.reset();
                  _fadeController.forward();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Reintentar",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🍳", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              "Aún no hay lecciones",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pronto habrán nuevas experiencias culinarias disponibles",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final String nodeId;
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;
  final bool isLocked;
  final String nodeType;
  final VoidCallback? onTap;

  const _NodeCard({
    required this.nodeId,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isCompleted,
    required this.isLocked,
    required this.nodeType,
  });

  String _getNodeIcon() {
    switch (nodeType) {
      case 'recipe':
        return '🍳';
      case 'skill':
        return '🎓';
      case 'quiz':
        return '❓';
      default:
        return '📚';
    }
  }

  Color _getNodeColor() {
    if (isCompleted) return const Color(0xFF4CAF50);
    if (isLocked) return Colors.grey;
    return const Color(0xFFFF6B35);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border(left: BorderSide(color: _getNodeColor(), width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getNodeIcon(), style: const TextStyle(fontSize: 32)),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    )
                  else if (isLocked)
                    const Icon(Icons.lock, color: Colors.grey, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : Colors.black87,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLocked ? Colors.grey : Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNodeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$xpReward XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getNodeColor(),
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

class _LineConnector extends StatelessWidget {
  final Widget child;
  final bool isLeft;
  final bool isFirst;
  final bool isLast;

  const _LineConnector({
    required this.child,
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineConnectorPainter(
        isLeft: isLeft,
        isFirst: isFirst,
        isLast: isLast,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isLeft ? 0 : 0,
          right: isLeft ? 0 : 0,
          top: isFirst ? 0 : 20,
          bottom: isLast ? 0 : 20,
        ),
        child: child,
      ),
    );
  }
}

class _LineConnectorPainter extends CustomPainter {
  final bool isLeft;
  final bool isFirst;
  final bool isLast;

  _LineConnectorPainter({
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!isFirst) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, 20),
        paint,
      );
    }

    if (!isLast) {
      canvas.drawLine(
        Offset(size.width / 2, size.height - 20),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LineConnectorPainter oldDelegate) => false;
}
