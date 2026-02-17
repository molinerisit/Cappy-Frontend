import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class TrackTreeScreen extends StatefulWidget {
  const TrackTreeScreen({super.key});

  @override
  State<TrackTreeScreen> createState() => _TrackTreeScreenState();
}

class _TrackTreeScreenState extends State<TrackTreeScreen> {
  late Future<Map<String, dynamic>> futureData;

  final String userId = "demoUser"; // temporal hasta tener auth real

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trackId = ModalRoute.of(context)!.settings.arguments as String;

    futureData = loadData(trackId);
  }

  Future<Map<String, dynamic>> loadData(String trackId) async {
    final tree = await ApiService.getTrackTree(trackId);
    final progress = await ApiService.getProgress(trackId);

    return {
      "tree": tree["tree"],
      "completedSkills": progress["completedSkills"] ?? [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Árbol de Habilidades")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error cargando datos"),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final units = data["tree"];
          final completedSkills = data["completedSkills"];

          List skillsFlat = [];

          for (var unit in units) {
            for (var skill in unit["skills"]) {
              skillsFlat.add(skill);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            itemCount: skillsFlat.length,
            itemBuilder: (context, index) {
              final skill = skillsFlat[index];

              bool isCompleted = completedSkills.contains(skill["_id"]);

              bool isUnlocked =
                  index == 0 ||
                  completedSkills.contains(skillsFlat[index - 1]["_id"]);

              Color color;

              if (isCompleted) {
                color = Colors.green.shade800;
              } else if (isUnlocked) {
                color = Colors.green;
              } else {
                color = Colors.grey;
              }

              final isLeft = index % 2 == 0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: isLeft
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: isUnlocked
                          ? () async {
                              // Navigate to skill lessons
                              final result = await Navigator.pushNamed(
                                context,
                                "/skillLessons",
                                arguments: skill,
                              );

                              // Refresh if lessons were completed
                              if (result == true) {
                                setState(() {
                                  final trackId =
                                      ModalRoute.of(context)!.settings.arguments
                                          as String;
                                  futureData = loadData(trackId);
                                });
                              }
                            }
                          : null,
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(51),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                skill["icon"] ?? "🍳",
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 100,
                            child: Text(
                              skill["name"] ?? "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.black : Colors.grey,
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
    );
  }
}
