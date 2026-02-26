import 'package:flutter/material.dart';
import '../models/culture_step_model.dart';

class CultureNodeDetailScreen extends StatelessWidget {
  final String nodeTitle;
  final List<CultureStep> steps;
  final Function(int) onStepComplete;

  const CultureNodeDetailScreen({
    required this.nodeTitle,
    required this.steps,
    required this.onStepComplete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nodeTitle)),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Card(
            child: ListTile(
              title: Text(step.type),
              subtitle: Text(
                step.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => onStepComplete(index),
            ),
          );
        },
      ),
    );
  }
}
