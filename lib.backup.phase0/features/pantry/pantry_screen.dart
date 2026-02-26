import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  late Future<List<dynamic>> futurePantry;
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futurePantry = ApiService.getPantry();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _refreshPantry() {
    setState(() {
      futurePantry = ApiService.getPantry();
    });
  }

  Future<void> _addIngredient() async {
    final name = _addController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa un nombre")));
      return;
    }

    try {
      await ApiService.addToPantry(name);
      _addController.clear();
      _refreshPantry();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name agregado a la despensa")));
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
    }
  }

  Future<void> _removeIngredient(String id, String name) async {
    try {
      await ApiService.removeFromPantry(id);
      _refreshPantry();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name eliminado")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error eliminando ingrediente"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agregar Ingrediente"),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(
            hintText: "Ej: Tomate, Cebolla, Ajo...",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (_) {
            Navigator.pop(context);
            _addIngredient();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addIngredient();
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Despensa")),
      body: FutureBuilder<List<dynamic>>(
        future: futurePantry,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error cargando despensa"),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshPantry,
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }

          final pantry = snapshot.data!;

          if (pantry.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🥗", style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    "Tu despensa está vacía",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Agrega ingredientes para generar lecciones personalizadas",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar Ingrediente"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.kitchen, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "${pantry.length} ingrediente${pantry.length != 1 ? 's' : ''}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pantry.length,
                  itemBuilder: (context, index) {
                    final ingredient = pantry[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.food_bank, color: Colors.white),
                        ),
                        title: Text(
                          ingredient["name"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeIngredient(
                            ingredient["_id"],
                            ingredient["name"],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
