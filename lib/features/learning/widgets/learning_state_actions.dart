import 'package:flutter/material.dart';

class LearningStateActions extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  const LearningStateActions({super.key, this.onBack, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (onBack == null && onRetry == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (onBack != null)
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Volver'),
          ),
        if (onRetry != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
      ],
    );
  }
}
