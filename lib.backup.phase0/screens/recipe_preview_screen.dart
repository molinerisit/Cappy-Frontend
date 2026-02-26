import 'package:flutter/material.dart';

class RecipePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final int totalTime;
  final int xp;
  final int level;
  final List<String> ingredients;
  final VoidCallback onStartCooking;

  const RecipePreviewScreen({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.totalTime,
    required this.xp,
    required this.level,
    required this.ingredients,
    required this.onStartCooking,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview de Receta')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(imageUrl, height: 220, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Text('Tiempo total: $totalTime min'),
                Text('XP: $xp'),
                Text('Nivel: $level'),
                SizedBox(height: 8),
                Text(
                  'Ingredientes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...ingredients.map((i) => Text('- $i')),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onStartCooking,
                  child: Text('Comenzar Modo Cocina'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
