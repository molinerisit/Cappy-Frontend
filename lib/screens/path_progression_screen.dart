import 'package:flutter/material.dart';
import '../core/api_service.dart';

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

class _PathProgressionScreenState extends State<PathProgressionScreen> {
  late Future<Map<String, dynamic>> futurePathData;

  @override
  void initState() {
    super.initState();
    futurePathData = ApiService.getPath(widget.pathId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathTitle),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futurePathData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futurePathData = ApiService.getPath(widget.pathId);
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final pathData = snapshot.data!;
          final nodes = pathData['nodes'] as List<dynamic>? ?? [];

          if (nodes.isEmpty) {
            return const Center(child: Text('No hay nodos en este camino'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index] as Map<String, dynamic>;
              final nodeId = node['_id'] ?? node['id'] ?? '';
              final title = node['title'] ?? 'Nodo ${index + 1}';
              final description = node['description'] ?? '';
              final xpReward = node['xpReward'] ?? 0;
              final isCompleted = node['status'] == 'completed';
              final isLocked = node['status'] == 'locked';
              final nodeType = node['type'] ?? 'recipe';

              final isLeft = index % 2 == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: isLeft
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: _LineConnector(
                        isLeft: isLeft,
                        isFirst: index == 0,
                        isLast: index == nodes.length - 1,
                        child: _NodeCard(
                          nodeId: nodeId,
                          title: title,
                          description: description,
                          xpReward: xpReward,
                          isCompleted: isCompleted,
                          isLocked: isLocked,
                          nodeType: nodeType,
                          onTap: !isLocked
                              ? () {
                                  // TODO: Navigate to lesson flow
                                  // For now, show a simple message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Starting: $title')),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
    this.onTap,
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
