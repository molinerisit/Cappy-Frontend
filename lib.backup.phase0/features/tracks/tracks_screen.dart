import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class TracksScreen extends StatefulWidget {
  const TracksScreen({super.key});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  late Future<List<dynamic>> futureTracks;

  @override
  void initState() {
    super.initState();
    futureTracks = ApiService.getTracks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CookLevel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.kitchen),
            onPressed: () {
              Navigator.pushNamed(context, "/pantry");
            },
            tooltip: "Mi Despensa",
          ),
          IconButton(
            icon: const Icon(Icons.restaurant),
            onPressed: () {
              Navigator.pushNamed(context, "/lessons");
            },
            tooltip: "Lecciones",
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, "/profile");
            },
            tooltip: "Mi Perfil",
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureTracks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error cargando tracks"),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futureTracks = ApiService.getTracks();
                      });
                    },
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }

          final tracks = snapshot.data!;

          if (tracks.isEmpty) {
            return const Center(child: Text("No hay tracks disponibles"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        track["icon"] ?? "🎯",
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    track["name"] ?? "Track",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    track["description"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      "/trackTree",
                      arguments: track["_id"],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
