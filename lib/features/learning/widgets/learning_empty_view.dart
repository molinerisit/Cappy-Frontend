import 'package:flutter/material.dart';
import 'learning_state_actions.dart';
import 'learning_state_card.dart';
import 'learning_state_heading.dart';

class LearningEmptyView extends StatelessWidget {
  final String emoji;
  final String title;
  final String? description;
  final VoidCallback? onBack;

  const LearningEmptyView({
    super.key,
    required this.emoji,
    required this.title,
    this.description,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LearningStateCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          LearningStateHeading(title: title, description: description),
          if (onBack != null) ...[
            const SizedBox(height: 18),
            LearningStateActions(onBack: onBack),
          ],
        ],
      ),
    );
  }
}
