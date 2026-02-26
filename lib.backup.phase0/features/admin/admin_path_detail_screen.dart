import 'package:flutter/material.dart';
import 'create_lesson_screen.dart';

class AdminPathDetailScreen extends StatelessWidget {
  final String pathId;
  final String pathName;

  const AdminPathDetailScreen({
    super.key,
    required this.pathId,
    required this.pathName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pathName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateLessonScreen(pathId: pathId),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Crear leccion"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Gestiona las lecciones de este path desde aqui.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
