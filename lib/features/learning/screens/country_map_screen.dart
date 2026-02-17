import 'package:flutter/material.dart';

// DEPRECATED: Use path_progression_screen.dart instead
class CountryMapScreen extends StatelessWidget {
  final String? countryId;

  const CountryMapScreen({super.key, this.countryId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Screen deprecated',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Use path_progression_screen', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
