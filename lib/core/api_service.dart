import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/path.dart';
import '../models/lesson.dart';
// import './models/learning_path.dart'; // Not used in this version

class ApiService {
  static const String baseUrl = "http://localhost:5000/api";
  static String? _token;

  // Auth methods
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? body['error'] ?? "Error en registro");
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? body['error'] ?? "Error en login");
  }

  static void setToken(String token) {
    _token = token.isEmpty ? null : token;
  }

  static String? getToken() {
    return _token;
  }

  static void logout() {
    _token = null;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/profile"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final body = jsonDecode(response.body);
    throw Exception(
      body['message'] ?? body['error'] ?? "Error cargando perfil",
    );
  }

  // ========================================
  // UNIFIED API (v2.0 - Main Routes)
  // ========================================

  /// Get Country Hub with Recipes + Culture paths
  static Future<Map<String, dynamic>> getCountryHub(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries/$countryId/hub"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando hub del país");
  }

  /// Get all Goal paths for Seguir Objetivos
  static Future<List<dynamic>> getGoalPaths() async {
    final response = await http.get(
      Uri.parse("$baseUrl/goals"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando objetivos");
  }

  /// Get path with nodes (generic)
  static Future<Map<String, dynamic>> getPathWithNodes(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando path");
  }

  /// Complete a learning node (progression)
  static Future<Map<String, dynamic>> completeNode(String nodeId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nodes/complete"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"nodeId": nodeId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error completando nodo");
  }

  /// Get user progress for specific path
  static Future<Map<String, dynamic>> getPathProgress(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/paths/$pathId/progress"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando progreso");
  }

  /// Get global ranking
  static Future<List<dynamic>> getRanking({int limit = 50}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/ranking?limit=$limit"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando ranking");
  }

  // ========================================
  // LEGACY METHODS (Backward Compatibility)
  // ========================================

  // Pantry methods
  static Future<List<dynamic>> getPantry() async {
    final response = await http.get(
      Uri.parse("$baseUrl/pantry"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error cargando despensa");
    }
  }

  static Future<Map<String, dynamic>> addToPantry(String name) async {
    final response = await http.post(
      Uri.parse("$baseUrl/pantry"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? "Error añadiendo ingrediente",
      );
    }
  }

  static Future<void> removeFromPantry(String ingredientId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/pantry/$ingredientId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando ingrediente");
    }
  }

  // Path methods
  static Future<List<Path>> getPaths() async {
    final response = await http.get(
      Uri.parse("$baseUrl/paths"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((item) => Path.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception("Error cargando paths");
  }

  static Future<List<Lesson>> getPathLessons(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/paths/$pathId/lessons"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((item) => Lesson.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception("Error cargando lecciones");
  }

  // Progress methods
  static Future<Map<String, dynamic>> getProgress(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/progress/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando progreso");
  }

  static Future<Map<String, dynamic>> completePathLesson(
    String lessonId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/progress/complete"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"lessonId": lessonId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error completando lección");
  }

  // Lesson methods (legacy personalized lessons)
  static Future<Map<String, dynamic>> generateLesson() async {
    final response = await http.post(
      Uri.parse("$baseUrl/lesson/generate"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error generando lección");
    }
  }

  static Future<Map<String, dynamic>> completeLesson(String lessonId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/lesson/$lessonId/complete"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error completando lección");
    }
  }

  // Track/technique legacy methods
  static Future<List<dynamic>> getTracks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/tracks"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando tracks");
  }

  static Future<Map<String, dynamic>> getTrackTree(String trackId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/tracks/$trackId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando track");
  }

  // Country methods
  static Future<List<dynamic>> getAllCountries() async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando países");
  }

  static Future<Map<String, dynamic>> getCountry(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries/$countryId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando país");
  }

  static Future<Map<String, dynamic>> getCountrySections(
    String countryId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries/$countryId/sections"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando secciones del país");
  }

  static Future<Map<String, dynamic>> getUserCountryProgress(
    String countryId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries/$countryId/progress"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando progreso del país");
  }

  // Recipe methods
  static Future<List<dynamic>> getRecipesByCountry(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recipes/country/$countryId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando recetas");
  }

  static Future<Map<String, dynamic>> getRecipe(String recipeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recipes/$recipeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando receta");
  }

  static Future<Map<String, dynamic>> checkRecipeUnlock(String recipeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recipes/$recipeId/unlock"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error verificando desbloqueo de receta");
  }

  static Future<Map<String, dynamic>> completeRecipe(String recipeId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/recipes/complete"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"recipeId": recipeId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error completando receta");
  }

  // Skill methods
  static Future<Map<String, dynamic>> getSkillTree(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/skills/tree/$countryId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando árbol de habilidades");
  }

  static Future<Map<String, dynamic>> getSkill(String skillId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/skills/$skillId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando habilidad");
  }

  static Future<Map<String, dynamic>> checkSkillUnlock(String skillId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/skills/$skillId/unlock"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error verificando desbloqueo de habilidad");
  }

  static Future<Map<String, dynamic>> learnSkill(String skillId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/skills/learn"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"skillId": skillId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error aprendiendo habilidad");
  }

  static Future<Map<String, dynamic>> updateSkillProgress(
    String skillId,
    int progress,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/skills/$skillId/progress"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"progress": progress}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando progreso");
  }

  // Inventory methods
  static Future<Map<String, dynamic>> getInventory() async {
    final response = await http.get(
      Uri.parse("$baseUrl/inventory"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando inventario");
  }

  static Future<Map<String, dynamic>> addToInventory(
    String name, {
    int quantity = 1,
    String type = 'ingredient',
    String unit = 'unit',
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/inventory/add"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        "name": name,
        "quantity": quantity,
        "type": type,
        "unit": unit,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error añadiendo a inventario");
  }

  static Future<Map<String, dynamic>> removeFromInventory(
    String itemName, {
    int? quantity,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/inventory/remove"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        "itemName": itemName,
        if (quantity != null) "quantity": quantity,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error eliminando de inventario");
  }

  static Future<Map<String, dynamic>> checkRecipeIngredients(
    String recipeId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/inventory/$recipeId/check"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error verificando ingredientes");
  }

  static Future<Map<String, dynamic>> useIngredientsForRecipe(
    String recipeId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/inventory/use-for-recipe"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"recipeId": recipeId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error usando ingredientes");
  }

  // Admin methods
  static Future<void> createLesson(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/lessons"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return;
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando leccion");
  }

  static Future<Map<String, dynamic>> createRecipe(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/recipes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando receta");
  }

  static Future<Map<String, dynamic>> createSkill(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/skills"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando habilidad");
  }

  static Future<Map<String, dynamic>> createCountry(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/countries"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando país");
  }

  // Learning Node methods (Duolingo-style progression)
  static Future<Map<String, dynamic>> getCountryMap(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/nodes/country/$countryId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando mapa de país");
  }

  static Future<Map<String, dynamic>> getLearningNode(String nodeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando nodo");
  }

  static Future<Map<String, dynamic>> checkNodeUnlock(String nodeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/nodes/$nodeId/unlock"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error verificando desbloqueo");
  }

  // REMOVED DUPLICATE: completeNode (with score parameter)
  // Use the version in UNIFIED API section instead

  static Future<List<dynamic>> getNodesByType(
    String countryId,
    String type,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/nodes/type/$countryId/$type"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando nodos");
  }

  static Future<List<dynamic>> searchNodes(
    String countryId, {
    String? query,
    String? type,
  }) async {
    String url = "$baseUrl/nodes/search/$countryId";
    if (query != null || type != null) {
      List<String> params = [];
      if (query != null) params.add("query=$query");
      if (type != null) params.add("type=$type");
      if (params.isNotEmpty) {
        url += "?${params.join('&')}";
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error buscando nodos");
  }

  static Future<Map<String, dynamic>> createLearningNode(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando nodo");
  }

  static Future<Map<String, dynamic>> updateLearningNode(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando nodo");
  }

  static Future<void> deleteLearningNode(String nodeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando nodo");
    }
  }

  // Learning Path methods (new navigation structure)
  static Future<Map<String, dynamic>> getAllLearningPaths() async {
    final response = await http.get(
      Uri.parse("$baseUrl/learning-paths"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando caminos de aprendizaje");
  }

  // REMOVED DUPLICATE: getCountryHub()
  // Use the version in UNIFIED API section instead

  static Future<Map<String, dynamic>> getPath(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/learning-paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando camino de aprendizaje");
  }

  static Future<List<dynamic>> getPathsByType(String type) async {
    final response = await http.get(
      Uri.parse("$baseUrl/learning-paths/type/$type"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando caminos por tipo");
  }

  // REMOVED DUPLICATE: getGoalPaths()
  // Use the version in UNIFIED API section instead

  // Admin LearningPath methods
  static Future<Map<String, dynamic>> createLearningPath(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/learning-paths"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando camino");
  }

  static Future<Map<String, dynamic>> updateLearningPath(
    String pathId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/learning-paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando camino");
  }

  static Future<Map<String, dynamic>> addNodeToPath(
    String pathId,
    String nodeId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/learning-paths/$pathId/add-node"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"nodeId": nodeId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error añadiendo nodo");
  }

  static Future<Map<String, dynamic>> removeNodeFromPath(
    String pathId,
    String nodeId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/learning-paths/$pathId/remove-node"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"nodeId": nodeId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error removiendo nodo");
  }

  static Future<void> deleteLearningPath(String pathId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/learning-paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando camino");
    }
  }

  // ====================================
  // ADMIN METHODS FOR LEARNING PATHS
  // ====================================

  static Future<List<dynamic>> adminGetAllLearningPaths() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/learning-paths"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando caminos");
  }

  static Future<Map<String, dynamic>> adminCreateLearningPath(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-paths"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando camino");
  }

  static Future<Map<String, dynamic>> adminUpdateLearningPath(
    String pathId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/learning-paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando camino");
  }

  static Future<void> adminDeleteLearningPath(String pathId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/learning-paths/$pathId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando camino");
    }
  }

  // ====================================
  // ADMIN METHODS FOR LEARNING NODES
  // ====================================

  static Future<List<dynamic>> adminGetNodesByPath(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/learning-paths/$pathId/nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando nodos");
  }

  static Future<Map<String, dynamic>> adminCreateLearningNode(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando nodo");
  }

  static Future<Map<String, dynamic>> adminUpdateLearningNode(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/learning-nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando nodo");
  }

  static Future<void> adminDeleteLearningNode(String nodeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/learning-nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando nodo");
    }
  }

  static Future<Map<String, dynamic>> adminSetRequiredNodes(
    String nodeId,
    List<String> requiredNodeIds,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-nodes/$nodeId/required"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"requiredNodeIds": requiredNodeIds}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error asignando nodos requeridos");
  }

  static Future<List<dynamic>> adminReorderNodes(
    String pathId,
    List<Map<String, dynamic>> nodeOrders,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-paths/$pathId/reorder-nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"nodeOrders": nodeOrders}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error reordenando nodos");
  }

  // ======================================
  // RECIPES ADMIN METHODS
  // ======================================

  static Future<Map<String, dynamic>> adminUpdateRecipe(
    String recipeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/recipes/$recipeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando receta");
  }

  static Future<void> adminDeleteRecipe(String recipeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/recipes/$recipeId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Error eliminando receta");
    }
  }

  // ======================================
  // CULTURE ADMIN METHODS
  // ======================================

  static Future<List<dynamic>> adminGetAllCulture() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/culture"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando contenido cultural");
  }

  static Future<List<dynamic>> adminGetCultureByCountry(
    String countryId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/culture/country/$countryId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando contenido cultural");
  }

  static Future<Map<String, dynamic>> adminCreateCulture(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/culture"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando contenido cultural");
  }

  static Future<Map<String, dynamic>> adminUpdateCulture(
    String cultureId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/culture/$cultureId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando contenido cultural");
  }

  static Future<void> adminDeleteCulture(String cultureId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/culture/$cultureId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Error eliminando contenido cultural");
    }
  }

  static Future<Map<String, dynamic>> adminAddCultureStep(
    String cultureId,
    Map<String, dynamic> step,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/culture/$cultureId/steps"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(step),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error agregando paso");
  }

  static Future<Map<String, dynamic>> adminUpdateCultureStep(
    String cultureId,
    String stepId,
    Map<String, dynamic> step,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/culture/$cultureId/steps/$stepId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(step),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando paso");
  }

  static Future<void> adminDeleteCultureStep(
    String cultureId,
    String stepId,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/culture/$cultureId/steps/$stepId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Error eliminando paso");
    }
  }

  // ======================================
  // COUNTRIES
  // ======================================

  static Future<List<dynamic>> getCountries() async {
    final response = await http.get(
      Uri.parse("$baseUrl/countries"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception("Error cargando países");
  }
}
