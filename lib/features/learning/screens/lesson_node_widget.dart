import 'package:flutter/material.dart';
import 'models/path_data.dart';

class LessonNodeWidget extends StatelessWidget {
  final PathNode node;
  final void Function(PathNode)? onTap;
  const LessonNodeWidget({required this.node, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final double size = 74;
    final Color borderColor;
    final Color fillColor;
    final double borderWidth;
    final Widget iconWidget;
    final double shadowBlur;
    final Color shadowColor;

    switch (node.status) {
      case NodeStatus.completed:
        borderColor = Colors.green;
        fillColor = Colors.green.withValues(alpha: 0.10);
        borderWidth = 3.5;
        iconWidget = const Icon(
          Icons.check_circle,
          size: 36,
          color: Colors.green,
        );
        shadowBlur = 0;
        shadowColor = Colors.transparent;
        break;
      case NodeStatus.active:
        borderColor = Colors.blueAccent;
        fillColor = Colors.white;
        borderWidth = 5;
        iconWidget = _buildTypeIcon(node.type, Colors.blueAccent, size: 36);
        shadowBlur = 24;
        shadowColor = Colors.blueAccent.withValues(alpha: 0.18);
        break;
      case NodeStatus.locked:
        borderColor = Colors.grey.shade300;
        fillColor = Colors.grey.shade100;
        borderWidth = 2.5;
        iconWidget = const Icon(
          Icons.lock_outline,
          size: 32,
          color: Color(0xFFB0B5BC),
        );
        shadowBlur = 0;
        shadowColor = Colors.transparent;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (shadowBlur > 0)
                BoxShadow(
                  color: shadowColor,
                  blurRadius: shadowBlur,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 90,
          child: Text(
            node.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: node.status == NodeStatus.locked
                  ? const Color(0xFFB0B5BC)
                  : Colors.black87,
              fontWeight: node.status == NodeStatus.active
                  ? FontWeight.bold
                  : FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildTypeIcon(NodeType type, Color color, {double size = 36}) {
    switch (type) {
      case NodeType.recipe:
        return Text('🍽', style: TextStyle(fontSize: size));
      case NodeType.quiz:
        return Text('❓', style: TextStyle(fontSize: size));
      case NodeType.explanation:
        return Text('📘', style: TextStyle(fontSize: size));
      case NodeType.tips:
        return Text('💡', style: TextStyle(fontSize: size));
      case NodeType.technique:
        return Text('🛠', style: TextStyle(fontSize: size));
      case NodeType.cultural:
        return Text('🌎', style: TextStyle(fontSize: size));
      case NodeType.challenge:
        return Text('🏆', style: TextStyle(fontSize: size));
    }
  }
}
