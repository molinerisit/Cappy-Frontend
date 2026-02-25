import 'http_client.dart';

/// ============================================
/// LEARNING REMOTE SOURCE
/// ============================================
///
/// Todos los métodos del sistema de aprendizaje:
/// - Learning Paths (Caminos)
/// - Learning Nodes (Nodos)
/// - Steps (Pasos)
/// - Cards (Tarjetas)
/// - Técnicas
/// - Recetas
///
/// Uso:
/// ```dart
/// final paths = await LearningRemoteSource.getPaths();
/// final node = await LearningRemoteSource.getNode(nodeId);
/// ```

abstract class LearningRemoteSource {
  // ====== LEARNING PATHS ======

  /// Obtener todos los caminos de aprendizaje
  static Future<List<dynamic>> getPaths() async {
    return await HttpClient.get('/learning-paths') as List<dynamic>;
  }

  /// Obtener un camino específico
  static Future<Map<String, dynamic>> getPath(String pathId) async {
    return await HttpClient.get('/learning-paths/$pathId')
        as Map<String, dynamic>;
  }

  /// Crear nuevo camino
  static Future<Map<String, dynamic>> createPath(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/learning-paths', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar camino
  static Future<Map<String, dynamic>> updatePath(
    String pathId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/learning-paths/$pathId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar camino
  static Future<void> deletePath(String pathId) async {
    await HttpClient.delete('/learning-paths/$pathId');
  }

  // ====== LEARNING NODES ======

  /// Obtener nodos de un camino
  static Future<List<dynamic>> getPathNodes(String pathId) async {
    return await HttpClient.get('/learning-paths/$pathId/nodes')
        as List<dynamic>;
  }

  /// Obtener un nodo específico
  static Future<Map<String, dynamic>> getNode(String nodeId) async {
    return await HttpClient.get('/nodes/$nodeId') as Map<String, dynamic>;
  }

  /// Crear nodo (admin)
  static Future<Map<String, dynamic>> createNode(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/nodes', body: data) as Map<String, dynamic>;
  }

  /// Actualizar nodo
  static Future<Map<String, dynamic>> updateNode(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/nodes/$nodeId', body: data)
        as Map<String, dynamic>;
  }

  /// Completar nodo (marcar como completado)
  static Future<Map<String, dynamic>> completeNode(String nodeId) async {
    return await HttpClient.post('/nodes/$nodeId/complete', body: {})
        as Map<String, dynamic>;
  }

  /// Eliminar nodo
  static Future<void> deleteNode(String nodeId) async {
    await HttpClient.delete('/nodes/$nodeId');
  }

  // ====== STEPS ======

  /// Obtener pasos de un nodo
  static Future<List<dynamic>> getNodeSteps(String nodeId) async {
    return await HttpClient.get('/nodes/$nodeId/steps') as List<dynamic>;
  }

  /// Obtener un paso específico
  static Future<Map<String, dynamic>> getStep(String stepId) async {
    return await HttpClient.get('/steps/$stepId') as Map<String, dynamic>;
  }

  /// Crear paso
  static Future<Map<String, dynamic>> createStep(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/steps', body: data) as Map<String, dynamic>;
  }

  /// Actualizar paso
  static Future<Map<String, dynamic>> updateStep(
    String stepId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/steps/$stepId', body: data)
        as Map<String, dynamic>;
  }

  /// Completar paso
  static Future<Map<String, dynamic>> completeStep(String stepId) async {
    return await HttpClient.post('/steps/$stepId/complete', body: {})
        as Map<String, dynamic>;
  }

  /// Eliminar paso
  static Future<void> deleteStep(String stepId) async {
    await HttpClient.delete('/steps/$stepId');
  }

  // ====== CARDS ======

  /// Obtener tarjetas de un paso
  static Future<List<dynamic>> getStepCards(String stepId) async {
    return await HttpClient.get('/steps/$stepId/cards') as List<dynamic>;
  }

  /// Crear tarjeta
  static Future<Map<String, dynamic>> createCard(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/cards', body: data) as Map<String, dynamic>;
  }

  /// Actualizar tarjeta
  static Future<Map<String, dynamic>> updateCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/cards/$cardId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar tarjeta
  static Future<void> deleteCard(String cardId) async {
    await HttpClient.delete('/cards/$cardId');
  }

  // ====== TECHNIQUES ======

  /// Obtener todas las técnicas
  static Future<List<dynamic>> getTechniques() async {
    return await HttpClient.get('/techniques') as List<dynamic>;
  }

  /// Obtener una técnica
  static Future<Map<String, dynamic>> getTechnique(String techniqueId) async {
    return await HttpClient.get('/techniques/$techniqueId')
        as Map<String, dynamic>;
  }

  /// Obtener técnicas de un camino
  static Future<List<dynamic>> getPathTechniques(String pathId) async {
    return await HttpClient.get('/learning-paths/$pathId/techniques')
        as List<dynamic>;
  }

  // ====== RECIPES ======

  /// Obtener todas las recetas
  static Future<List<dynamic>> getRecipes({
    String? countryId,
    String? difficulty,
  }) async {
    return await HttpClient.get(
          '/recipes',
          queryParams: {
            if (countryId != null) 'countryId': countryId,
            if (difficulty != null) 'difficulty': difficulty,
          },
        )
        as List<dynamic>;
  }

  /// Obtener una receta
  static Future<Map<String, dynamic>> getRecipe(String recipeId) async {
    return await HttpClient.get('/recipes/$recipeId') as Map<String, dynamic>;
  }

  /// Obtener recetas de un camino
  static Future<List<dynamic>> getPathRecipes(String pathId) async {
    return await HttpClient.get('/learning-paths/$pathId/recipes')
        as List<dynamic>;
  }

  // ====== PROGRESS ======

  /// Obtener progreso del usuario en un camino
  static Future<Map<String, dynamic>> getPathProgress(String pathId) async {
    return await HttpClient.get('/learning-paths/$pathId/progress')
        as Map<String, dynamic>;
  }

  /// Obtener progreso en todos los caminos
  static Future<List<dynamic>> getAllProgress() async {
    return await HttpClient.get('/progress') as List<dynamic>;
  }
}
