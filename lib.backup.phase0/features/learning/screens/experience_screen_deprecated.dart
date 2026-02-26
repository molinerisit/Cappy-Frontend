import 'package:flutter/material.dart';

// This screen is DEPRECATED. Use main_experience_screen.dart instead.
class ExperienceScreenDeprecated extends StatelessWidget {
  const ExperienceScreenDeprecated({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This screen is deprecated. Please use the new experience screen.',
        ),
      ),
    );
  }
}
