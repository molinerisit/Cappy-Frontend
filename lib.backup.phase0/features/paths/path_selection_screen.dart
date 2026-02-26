import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/path_model.dart';

class PathSelectionScreen extends StatefulWidget {
  const PathSelectionScreen({super.key});

  @override
  State<PathSelectionScreen> createState() => _PathSelectionScreenState();
}

class _PathSelectionScreenState extends State<PathSelectionScreen> {
  late Future<List<PathModel>> futurePaths;
  String title = "Paths";
  String type = "country";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    title = args?["title"]?.toString() ?? "Paths";
    type = args?["type"]?.toString() ?? "country";
    futurePaths = _loadPaths();
  }

  Future<List<PathModel>> _loadPaths() async {
    final data = await ApiService.getPaths();
    return data
        .map(
          (item) => PathModel(
            id: item.id,
            name: item.name,
            type: item.type,
            icon: item.icon,
            description: item.description,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<PathModel>>(
        future: futurePaths,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error cargando paths"),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futurePaths = _loadPaths();
                      });
                    },
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }

          final paths = snapshot.data ?? [];
          if (paths.isEmpty) {
            return const Center(child: Text("No hay paths disponibles"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: paths.length,
            itemBuilder: (context, index) {
              final path = paths[index];
              return InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/lessonsTree",
                    arguments: {
                      "pathId": path.id,
                      "title": path.name,
                      "icon": path.icon,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            path.icon.isNotEmpty ? path.icon : "\uD83C\uDF0D",
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        path.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        path.description.isNotEmpty
                            ? path.description
                            : "Aprende nuevas tecnicas",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
