import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../models/lesson_model.dart';
import '../../providers/progress_provider.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool isLoading = false;

  Future<void> _completeLesson(String lessonId, int xpReward) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.completePathLesson(lessonId);
      if (mounted) {
        context.read<ProgressProvider>().updateFromResponse(response);
        await _showXpAnimation(xpReward);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showXpAnimation(int xpReward) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "XP",
      barrierColor: Colors.black.withAlpha(120),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final scale = Tween<double>(begin: 0.8, end: 1.1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return Opacity(
          opacity: animation.value,
          child: ScaleTransition(
            scale: scale,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      "XP Ganado",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "+$xpReward XP",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final lesson = args?["lesson"] as LessonModel;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.description.isNotEmpty
                  ? lesson.description
                  : "Una nueva leccion para avanzar.",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  "+${lesson.xpReward} XP",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                if (lesson.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Premium",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Ingredientes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lesson.ingredients.isEmpty)
              const Text("Sin ingredientes definidos"),
            if (lesson.ingredients.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lesson.ingredients.map((ingredient) {
                  final name = ingredient is Map
                      ? ingredient["name"]?.toString() ?? ""
                      : ingredient.toString();
                  return Chip(
                    label: Text(name),
                    backgroundColor: Colors.green.shade50,
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            const Text(
              "Pasos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lesson.steps.isEmpty)
              const Text("Sigue las indicaciones del chef"),
            if (lesson.steps.isNotEmpty)
              Column(
                children: lesson.steps.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final step = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.shade600,
                      child: Text(
                        index.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(step),
                  );
                }).toList(),
              ),
            if (lesson.nutrition != null) ...[
              const SizedBox(height: 24),
              const Text(
                "Nutricion",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _NutritionChip("Cal", lesson.nutrition?["calories"]),
                  _NutritionChip("Prot", lesson.nutrition?["protein"]),
                  _NutritionChip("Carb", lesson.nutrition?["carbs"]),
                  _NutritionChip("Fat", lesson.nutrition?["fat"]),
                ],
              ),
            ],
            if (lesson.tips.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "Tips",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: lesson.tips
                    .map(
                      (tip) => ListTile(
                        leading: const Icon(
                          Icons.lightbulb,
                          color: Colors.orange,
                        ),
                        title: Text(tip),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _completeLesson(lesson.id, lesson.xpReward),
                icon: const Icon(Icons.check_circle),
                label: Text(isLoading ? "Completando..." : "Completar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final dynamic value;

  const _NutritionChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final display = value == null ? "-" : value.toString();
    return Chip(
      label: Text("$label: $display"),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
