import 'http_client.dart';

/// ============================================
/// ADMIN REMOTE SOURCE
/// ============================================
///
/// Todos los métodos administrativos:
/// - Gestión de grupos
/// - Gestión de nodos
/// - Gestión de pasos
/// - Gestión de cards
/// - Biblioteca de nodos
/// - Importar/duplicar contenido
///
/// Uso:
/// ```dart
/// final groups = await AdminRemoteSource.getPathGroups(pathId);
/// await AdminRemoteSource.createNodeGroup(pathId, data);
/// ```

abstract class AdminRemoteSource {
  // ====== GROUPS (GRUPOS) ======

  /// Obtener grupos de un camino
  static Future<List<dynamic>> getPathGroups(String pathId) async {
    return await HttpClient.get('/admin/v2/paths/$pathId/groups')
        as List<dynamic>;
  }

  /// Obtener un grupo
  static Future<Map<String, dynamic>> getGroup(String groupId) async {
    return await HttpClient.get('/admin/v2/groups/$groupId')
        as Map<String, dynamic>;
  }

  /// Crear grupo
  static Future<Map<String, dynamic>> createNodeGroup(
    String pathId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/admin/v2/paths/$pathId/groups', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar grupo
  static Future<Map<String, dynamic>> updateGroup(
    String groupId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/admin/v2/groups/$groupId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar grupo
  static Future<void> deleteGroup(String groupId) async {
    await HttpClient.delete('/admin/v2/groups/$groupId');
  }

  /// Reordenar grupos
  static Future<List<dynamic>> reorderGroups(
    String pathId,
    List<String> groupIds,
  ) async {
    return await HttpClient.post(
          '/admin/v2/paths/$pathId/groups/reorder',
          body: {'groupIds': groupIds},
        )
        as List<dynamic>;
  }

  // ====== NODES (NODOS) ======

  /// Obtener nodos de un grupo
  static Future<List<dynamic>> getGroupNodes(String groupId) async {
    return await HttpClient.get('/admin/v2/groups/$groupId/nodes')
        as List<dynamic>;
  }

  /// Obtener un nodo (admin)
  static Future<Map<String, dynamic>> getAdminNode(String nodeId) async {
    return await HttpClient.get('/admin/v2/nodes/$nodeId')
        as Map<String, dynamic>;
  }

  /// Crear nodo
  static Future<Map<String, dynamic>> createAdminNode(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/admin/v2/nodes', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar nodo
  static Future<Map<String, dynamic>> updateAdminNode(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/admin/v2/nodes/$nodeId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar nodo
  static Future<void> deleteAdminNode(String nodeId) async {
    await HttpClient.delete('/admin/v2/nodes/$nodeId');
  }

  /// Reordenar nodos en nivel
  static Future<List<dynamic>> reorderNodes(
    String groupId,
    List<String> nodeIds,
  ) async {
    return await HttpClient.post(
          '/admin/v2/groups/$groupId/nodes/reorder',
          body: {'nodeIds': nodeIds},
        )
        as List<dynamic>;
  }

  /// Cambiar nivel de nodos
  static Future<List<dynamic>> changeNodeLevel(
    List<String> nodeIds,
    int newLevel,
  ) async {
    return await HttpClient.post(
          '/admin/v2/nodes/change-level',
          body: {'nodeIds': nodeIds, 'newLevel': newLevel},
        )
        as List<dynamic>;
  }

  // ====== STEPS (PASOS) ======

  /// Obtener pasos de un nodo
  static Future<List<dynamic>> getAdminSteps(String nodeId) async {
    return await HttpClient.get('/admin/v2/nodes/$nodeId/steps')
        as List<dynamic>;
  }

  /// Crear paso
  static Future<Map<String, dynamic>> createAdminStep(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/admin/v2/nodes/$nodeId/steps', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar paso
  static Future<Map<String, dynamic>> updateAdminStep(
    String stepId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/admin/v2/steps/$stepId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar paso
  static Future<void> deleteAdminStep(String stepId) async {
    await HttpClient.delete('/admin/v2/steps/$stepId');
  }

  // ====== CARDS (TARJETAS) ======

  /// Obtener tarjetas de un paso
  static Future<List<dynamic>> getAdminCards(String stepId) async {
    return await HttpClient.get('/admin/v2/steps/$stepId/cards')
        as List<dynamic>;
  }

  /// Crear tarjeta
  static Future<Map<String, dynamic>> createAdminCard(
    String stepId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.post('/admin/v2/steps/$stepId/cards', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar tarjeta
  static Future<Map<String, dynamic>> updateAdminCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/admin/v2/cards/$cardId', body: data)
        as Map<String, dynamic>;
  }

  /// Eliminar tarjeta
  static Future<void> deleteAdminCard(String cardId) async {
    await HttpClient.delete('/admin/v2/cards/$cardId');
  }

  // ====== NODE LIBRARY (BIBLIOTECA) ======

  /// Obtener biblioteca de nodos
  static Future<List<dynamic>> getNodeLibrary({
    String? pathId,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    return await HttpClient.get(
          '/admin/v2/library/nodes',
          queryParams: {
            if (pathId != null) 'pathId': pathId,
            if (type != null) 'type': type,
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        )
        as List<dynamic>;
  }

  /// Buscar en biblioteca
  static Future<List<dynamic>> searchLibrary(
    String query, {
    String? type,
  }) async {
    return await HttpClient.get(
          '/admin/v2/library/search',
          queryParams: {'q': query, if (type != null) 'type': type},
        )
        as List<dynamic>;
  }

  /// Obtener relaciones de un nodo
  static Future<Map<String, dynamic>> getNodeRelations(String nodeId) async {
    return await HttpClient.get('/admin/v2/nodes/$nodeId/relations')
        as Map<String, dynamic>;
  }

  // ====== IMPORT ======

  /// Importar nodo como referencia (linked)
  static Future<Map<String, dynamic>> importNodeAsLinked(
    String targetPathId,
    String sourceNodeId,
  ) async {
    return await HttpClient.post(
          '/admin/v2/nodes/import-linked',
          body: {'targetPathId': targetPathId, 'sourceNodeId': sourceNodeId},
        )
        as Map<String, dynamic>;
  }

  /// Importar nodo como copia
  static Future<Map<String, dynamic>> importNodeAsCopy(
    String targetPathId,
    String sourceNodeId,
  ) async {
    return await HttpClient.post(
          '/admin/v2/nodes/import-copy',
          body: {'targetPathId': targetPathId, 'sourceNodeId': sourceNodeId},
        )
        as Map<String, dynamic>;
  }

  /// Duplicar nodo
  static Future<Map<String, dynamic>> duplicateNode(
    String nodeId,
    String targetGroupId,
  ) async {
    return await HttpClient.post(
          '/admin/v2/nodes/$nodeId/duplicate',
          body: {'targetGroupId': targetGroupId},
        )
        as Map<String, dynamic>;
  }

  // ====== ARCHIVING ======

  /// Archivar nodo
  static Future<Map<String, dynamic>> archiveNode(String nodeId) async {
    return await HttpClient.post('/admin/v2/nodes/$nodeId/archive', body: {})
        as Map<String, dynamic>;
  }

  /// Restaurar nodo archivado
  static Future<Map<String, dynamic>> restoreNode(String nodeId) async {
    return await HttpClient.post('/admin/v2/nodes/$nodeId/restore', body: {})
        as Map<String, dynamic>;
  }

  // ====== STATISTICS ======

  /// Obtener estadísticas de contenido
  static Future<Map<String, dynamic>> getContentStats(String pathId) async {
    return await HttpClient.get('/admin/v2/paths/$pathId/stats')
        as Map<String, dynamic>;
  }

  /// Obtener estadísticas de uso de un nodo
  static Future<Map<String, dynamic>> getNodeStats(String nodeId) async {
    return await HttpClient.get('/admin/v2/nodes/$nodeId/stats')
        as Map<String, dynamic>;
  }
}
