import 'package:flutter/material.dart';
import '../models/culture_node_model.dart';

class CultureTreeScreen extends StatelessWidget {
  final List<CultureNode> nodes;
  final Function(CultureNode) onNodeTap;

  const CultureTreeScreen({
    required this.nodes,
    required this.onNodeTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Árbol de Cultura')),
      body: Center(
        child: ListView.builder(
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            return Card(
              color: node.isLocked ? Colors.grey[300] : Colors.white,
              child: ListTile(
                title: Text(node.title),
                subtitle: Text(node.description),
                trailing: node.isLocked
                    ? Icon(Icons.lock)
                    : Icon(Icons.check_circle, color: Colors.green),
                onTap: node.isLocked ? null : () => onNodeTap(node),
              ),
            );
          },
        ),
      ),
    );
  }
}
