import 'package:flutter/material.dart';
import 'learning_state_actions.dart';
import 'learning_state_card.dart';
import 'learning_state_heading.dart';

class LearningErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;
  final String? title;
  final IconData icon;

  const LearningErrorView({
    super.key,
    required this.error,
    this.onBack,
    this.onRetry,
    this.title,
    this.icon = Icons.error_outline,
  });

  String _buildDescription() {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return LearningStateCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: primaryBlue),
          const SizedBox(height: 14),
          LearningStateHeading(
            title: title ?? 'Error al cargar contenido',
            description: _buildDescription(),
          ),
          if (onBack != null || onRetry != null) ...[
            const SizedBox(height: 18),
            LearningStateActions(onBack: onBack, onRetry: onRetry),
          ],
        ],
      ),
    );
  }
}
