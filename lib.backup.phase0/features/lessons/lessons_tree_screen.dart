import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../models/lesson_model.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/xp_display.dart';

class LessonsTreeScreen extends StatefulWidget {
  const LessonsTreeScreen({super.key});

  @override
  State<LessonsTreeScreen> createState() => _LessonsTreeScreenState();
}

class _LessonsTreeScreenState extends State<LessonsTreeScreen> {
  late Future<List<LessonModel>> futureLessons;
  late String pathId;
  String title = "Lecciones";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    pathId = args?["pathId"]?.toString() ?? "";
    title = args?["title"]?.toString() ?? "Lecciones";
    futureLessons = _loadLessons();
    context.read<ProgressProvider>().loadProgress(pathId);
  }

  Future<List<LessonModel>> _loadLessons() async {
    final data = await ApiService.getPathLessons(pathId);
    return data
        .map(
          (item) => LessonModel(
            id: item.id,
            title: item.title,
            description: item.description,
            order: item.order,
            locked: item.locked,
            completed: item.completed,
            xpReward: item.xpReward,
            ingredients: item.ingredients,
            steps: item.steps,
            nutrition: item.nutrition,
            tips: item.tips,
            isPremium: item.isPremium,
          ),
        )
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      futureLessons = _loadLessons();
    });
    await context.read<ProgressProvider>().loadProgress(pathId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Consumer<ProgressProvider>(
            builder: (context, progressProvider, _) {
              final progress = progressProvider.progress;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: XPDisplay(
                  currentXp: progress.xp,
                  level: progress.level,
                  xpForNextLevel: (progress.level + 1) * 100,
                  streak: progress.streak,
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<LessonModel>>(
              future: futureLessons,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Error cargando lecciones"),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  );
                }

                final lessons = snapshot.data ?? [];
                if (lessons.isEmpty) {
                  return const Center(
                    child: Text("No hay lecciones disponibles"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final isLeft = index % 2 == 0;

                    Color color;
                    IconData icon;

                    if (lesson.completed) {
                      color = Colors.green.shade800;
                      icon = Icons.check_circle;
                    } else if (!lesson.locked) {
                      color = Colors.green.shade500;
                      icon = Icons.play_arrow;
                    } else {
                      color = Colors.grey.shade400;
                      icon = Icons.lock;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: isLeft
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: lesson.locked
                                ? null
                                : () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      "/lessonDetail",
                                      arguments: {
                                        "lesson": lesson,
                                        "pathId": pathId,
                                      },
                                    );

                                    if (result == true) {
                                      _refresh();
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(40),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    lesson.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: lesson.locked
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
