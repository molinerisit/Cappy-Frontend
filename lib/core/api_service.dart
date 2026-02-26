import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/path.dart';
import '../models/lesson.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000/api";
  static String? _token;

  // CRUD Nodos
  static Future<Map<String, dynamic>> createNode(
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
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(
      jsonDecode(response.body)['message'] ?? "Error creando nodo",
    );
  }

  static Future<Map<String, dynamic>> updateNode(
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
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(
      jsonDecode(response.body)['message'] ?? "Error actualizando nodo",
    );
  }

  static Future<void> deleteNode(String nodeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? "Error eliminando nodo",
      );
    }
  }

  // Importar nodos/recetas
  static Future<List<dynamic>> importContent({
    required String targetPathId,
    List<String>? nodeIds,
    List<String>? recipeIds,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/nodes/import"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        "targetPathId": targetPathId,
        "nodeIds": nodeIds ?? [],
        "recipeIds": recipeIds ?? [],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imported'] ?? [];
    }
    throw Exception(
      jsonDecode(response.body)['message'] ?? "Error importando contenido",
    );
  }
  // Removed duplicate baseUrl and _token declarations

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

  static String? get token {
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

  static Future<Map<String, dynamic>> changeCurrentPath(String pathId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/change-path"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"pathId": pathId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final body = jsonDecode(response.body);
    throw Exception(
      body['message'] ?? body['error'] ?? "Error cambiando camino",
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

  static Future<List<dynamic>> getCultureByCountry(String countryId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/culture/country/$countryId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando artículos culturales");
  }

  static Future<Map<String, dynamic>> getCulture(String cultureId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/culture/$cultureId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando artículo cultural");
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
      Uri.parse("$baseUrl/admin/paths/$pathId/nodes"),
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

  static Future<List<dynamic>> adminGetAllNodes() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/learning-nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando todos los nodos");
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

  // ====================================
  // ADMIN CONTENT V2 (Groups + Nodes)
  // ====================================

  static Future<List<dynamic>> adminGetGroupsByPath(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/v2/paths/$pathId/groups"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
    }

    throw Exception("Error cargando grupos");
  }

  static Future<Map<String, dynamic>> adminCreateGroup(
    String pathId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/v2/paths/$pathId/groups"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando grupo");
  }

  static Future<Map<String, dynamic>> adminUpdateGroup(
    String groupId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/v2/groups/$groupId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando grupo");
  }

  static Future<void> adminDeleteGroup(String groupId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/v2/groups/$groupId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando grupo");
    }
  }

  static Future<List<dynamic>> adminGetContentNodesByPath(String pathId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/v2/paths/$pathId/nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
    }

    throw Exception("Error cargando nodos");
  }

  static Future<Map<String, dynamic>> adminCreateContentNode(
    Map<String, dynamic> data,
  ) async {
    final pathId = data['pathId']?.toString();
    if (pathId == null || pathId.isEmpty) {
      throw Exception('pathId es requerido para crear nodo');
    }

    final payload = Map<String, dynamic>.from(data)..remove('pathId');

    final response = await http.post(
      Uri.parse("$baseUrl/admin/v2/paths/$pathId/nodes"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando nodo");
  }

  static Future<Map<String, dynamic>> adminUpdateContentNode(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando nodo");
  }

  static Future<void> adminDeleteContentNode(String nodeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando nodo");
    }
  }

  static Future<List<dynamic>> adminReorderContentNodes(
    String pathId,
    List<Map<String, dynamic>> updates,
  ) async {
    final updatesByLevel = <int, List<Map<String, dynamic>>>{};
    for (final update in updates) {
      final levelRaw = update['level'];
      final level = levelRaw is num ? levelRaw.toInt() : 1;
      final nodeId = update['nodeId']?.toString();
      final posRaw = update['positionIndex'];
      final positionIndex = posRaw is num ? posRaw.toInt() : 1;

      if (nodeId == null || nodeId.isEmpty) continue;

      updatesByLevel.putIfAbsent(level, () => []).add({
        'nodeId': nodeId,
        'positionIndex': positionIndex,
      });
    }

    for (final entry in updatesByLevel.entries) {
      final response = await http.post(
        Uri.parse("$baseUrl/admin/v2/paths/$pathId/nodes/reorder-by-level"),
        headers: {
          "Content-Type": "application/json",
          if (_token != null) "Authorization": "Bearer $_token",
        },
        body: jsonEncode({'level': entry.key, 'nodeOrders': entry.value}),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? "Error reordenando nodos");
      }
    }

    return adminGetContentNodesByPath(pathId);
  }

  static Future<Map<String, dynamic>> adminImportNode(
    Map<String, dynamic> data,
  ) async {
    final targetPathId = data['targetPathId']?.toString();
    final sourceNodeId = (data['sourceNodeId'] ?? data['nodeId'])?.toString();
    final mode = (data['mode'] ?? 'linked').toString();

    if (targetPathId == null || targetPathId.isEmpty) {
      throw Exception('targetPathId es requerido para importar nodo');
    }
    if (sourceNodeId == null || sourceNodeId.isEmpty) {
      throw Exception('sourceNodeId/nodeId es requerido para importar nodo');
    }

    final isCopy = mode.toLowerCase() == 'copy';
    final endpoint = isCopy
        ? "$baseUrl/admin/v2/nodes/import/copy"
        : "$baseUrl/admin/v2/nodes/import/linked";

    final payload = <String, dynamic>{
      'sourceNodeId': sourceNodeId,
      'targetPathId': targetPathId,
      if (data['title'] != null) 'title': data['title'],
      if (data['groupId'] != null) 'groupId': data['groupId'],
      if (data['level'] != null) 'level': data['level'],
      if (data['positionIndex'] != null) 'positionIndex': data['positionIndex'],
      if (data['status'] != null) 'status': data['status'],
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error importando nodo");
  }

  static Future<Map<String, dynamic>> adminArchiveNode(String nodeId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({'status': 'archived'}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error archivando nodo");
  }

  static Future<Map<String, dynamic>> adminDuplicateNode(
    String nodeId, {
    String? targetPathId,
  }) async {
    String? resolvedTargetPathId = targetPathId;

    if (resolvedTargetPathId == null || resolvedTargetPathId.isEmpty) {
      final nodeResponse = await http.get(
        Uri.parse("$baseUrl/admin/v2/nodes/$nodeId"),
        headers: {
          "Content-Type": "application/json",
          if (_token != null) "Authorization": "Bearer $_token",
        },
      );

      if (nodeResponse.statusCode != 200) {
        final body = jsonDecode(nodeResponse.body);
        throw Exception(body['message'] ?? 'Error obteniendo nodo original');
      }

      final decodedNode = jsonDecode(nodeResponse.body);
      final nodeData = decodedNode is Map<String, dynamic>
          ? (decodedNode['data'] is Map ? decodedNode['data'] : decodedNode)
          : <String, dynamic>{};
      final rawPathId = nodeData['pathId'];
      resolvedTargetPathId = rawPathId is Map
          ? (rawPathId['_id']?.toString() ?? rawPathId['id']?.toString())
          : rawPathId?.toString();
    }

    if (resolvedTargetPathId == null || resolvedTargetPathId.isEmpty) {
      throw Exception('No se pudo determinar targetPathId para duplicar nodo');
    }

    final response = await http.post(
      Uri.parse("$baseUrl/admin/v2/nodes/import/copy"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        'sourceNodeId': nodeId,
        'targetPathId': resolvedTargetPathId,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error duplicando nodo");
  }

  static Future<Map<String, dynamic>> adminGetNodeRelations(
    String nodeId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId/relations"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error cargando relaciones");
  }

  static Future<List<dynamic>> adminGetNodeLibrary({
    String? pathId,
    String? groupId,
    String? type,
    String? status,
    String? search,
  }) async {
    final query = <String, String>{'page': '1', 'limit': '200'};
    if (pathId != null) query['pathId'] = pathId;
    if (groupId != null) query['groupId'] = groupId;
    if (type != null) query['type'] = type;
    if (status != null) query['status'] = status;
    if (search != null && search.trim().isNotEmpty) {
      query['q'] = search.trim();
    }

    final endpoint = query.containsKey('q')
        ? "$baseUrl/admin/v2/library/search"
        : "$baseUrl/admin/v2/library/nodes";

    final uri = Uri.parse(
      endpoint,
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
    }

    throw Exception("Error cargando biblioteca");
  }

  static Future<Map<String, dynamic>> adminAddNodeStep(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId/steps"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error agregando paso");
  }

  static Future<Map<String, dynamic>> adminUpdateNodeStep(
    String nodeId,
    String stepId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/v2/steps/$stepId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando paso");
  }

  static Future<void> adminDeleteNodeStep(String nodeId, String stepId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/v2/steps/$stepId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando paso");
    }
  }

  static Future<void> adminDeleteNode(String nodeId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/v2/nodes/$nodeId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Error eliminando nodo: ${response.statusCode} - ${response.body}",
      );
    }
  }

  static Future<Map<String, dynamic>> adminAddStepCard(
    String nodeId,
    String stepId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/v2/steps/$stepId/cards"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error agregando card");
  }

  static Future<Map<String, dynamic>> adminUpdateStepCard(
    String nodeId,
    String stepId,
    String cardId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/v2/cards/$cardId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return Map<String, dynamic>.from(decoded);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error actualizando card");
  }

  static Future<void> adminDeleteStepCard(
    String nodeId,
    String stepId,
    String cardId,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/v2/cards/$cardId"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error eliminando card");
    }
  }

  static Future<Map<String, dynamic>> adminImportModuleToNode(
    String nodeId,
    String type,
    String referenceId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-nodes/$nodeId/import-module"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"type": type, "referenceId": referenceId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error importando módulo");
  }

  static Future<Map<String, dynamic>> adminRemoveModuleFromNode(
    String nodeId,
    String type,
    String referenceId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/learning-nodes/$nodeId/remove-module"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"type": type, "referenceId": referenceId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error desvinculando módulo");
  }

  // ======================================
  // RECIPES ADMIN METHODS
  // ======================================

  static Future<List<dynamic>> adminGetAllRecipes() async {
    final response = await http.get(
      Uri.parse("$baseUrl/recipes"),
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

  static Future<List<dynamic>> adminGetRecipesByCountry(
    String countryId,
  ) async {
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

    throw Exception("Error cargando recetas del país");
  }

  static Future<Map<String, dynamic>> adminCreateRecipe(
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

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error creando receta");
  }

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

  static Future<Map<String, dynamic>> adminCreateCountry(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/countries"),
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
    throw Exception(body['message'] ?? "Error creando país");
  }

  static Future<Map<String, dynamic>> adminUpdateCountry(
    String countryId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/countries/$countryId"),
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
    throw Exception(body['message'] ?? "Error actualizando país");
  }

  static Future<void> adminDeleteCountry(String countryId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/admin/countries/$countryId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Error eliminando país");
    }
  }

  // =====================================================
  // NEW: Recipes & Culture by Country (for PathContentScreen)
  // =====================================================

  static Future<List<dynamic>> adminListRecipesByCountry(
    String countryId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/countries/$countryId/recipes"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception("Error cargando recetas");
  }

  static Future<Map<String, dynamic>> adminGetRecipeDetails(
    String recipeId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/recipes/$recipeId"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Error cargando detalles de receta");
  }

  static Future<List<dynamic>> adminListCultureNodesByCountry(
    String countryId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/countries/$countryId/culture-nodes"),
      headers: {if (_token != null) "Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception("Error cargando cultura");
  }
}
