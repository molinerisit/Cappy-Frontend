import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class SkillLessonsScreen extends StatefulWidget {
  const SkillLessonsScreen({super.key});

  @override
  State<SkillLessonsScreen> createState() => _SkillLessonsScreenState();
}

class _SkillLessonsScreenState extends State<SkillLessonsScreen> {
  late Map<String, dynamic> skill;
  bool isLoading = false;

  String _stepText(dynamic step) {
    if (step is String) {
      return step;
    }

    if (step is Map) {
      final instruction = step["instruction"]?.toString();
      final content = step["content"]?.toString();
      final text = step["text"]?.toString();
      final description = step["description"]?.toString();
      final title = step["title"]?.toString();

      for (final value in [instruction, content, text, description, title]) {
        if (value != null && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return step?.toString() ?? "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    skill = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }

  Future<void> _completeLesson(String lessonId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.completeLesson(lessonId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "¡Lección completada! +${response['xpAwarded'] ?? 0} XP",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Go back and refresh
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showLessonDialog(Map<String, dynamic> lesson) {
    final steps = lesson["steps"] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson["title"] ?? "Lección",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${lesson['estimatedTime'] ?? 0} min",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "+${lesson['xpAwarded'] ?? 0} XP",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (steps.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Sigue las instrucciones de la técnica",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _stepText(step),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      if (step["timer"] != null &&
                                          step["timer"] > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.alarm,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${step["timer"]} segundos",
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _completeLesson(lesson["_id"]);
                              },
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Completar"),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = skill["lessons"] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(skill["name"] ?? "Lecciones")),
      body: lessons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    skill["icon"] ?? "📚",
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay lecciones disponibles",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Las lecciones se agregarán pronto",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final isCompleted = lesson["completed"] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade800
                            : Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    title: Text(
                      lesson["title"] ?? "Lección ${index + 1}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${lesson['estimatedTime'] ?? 0} min"),
                          const SizedBox(width: 16),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text("+${lesson['xpAwarded'] ?? 0} XP"),
                        ],
                      ),
                    ),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: isCompleted ? null : () => _showLessonDialog(lesson),
                  ),
                );
              },
            ),
    );
  }
}
