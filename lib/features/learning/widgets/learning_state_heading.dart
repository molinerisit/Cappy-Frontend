import 'package:flutter/material.dart';

class LearningStateHeading extends StatelessWidget {
  final String title;
  final String? description;

  const LearningStateHeading({
    super.key,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
