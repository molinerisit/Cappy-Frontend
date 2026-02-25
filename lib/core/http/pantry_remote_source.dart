import 'http_client.dart';

/// ============================================
/// PANTRY REMOTE SOURCE
/// ============================================
///
/// Todos los métodos relacionados con:
/// - Inventario de ingredientes
/// - Despensa del usuario
/// - Productos disponibles
///
/// Uso:
/// ```dart
/// final items = await PantryRemoteSource.getPantryItems();
/// await PantryRemoteSource.addItem(ingredientId);
/// ```

abstract class PantryRemoteSource {
  // ====== PANTRY ITEMS ======

  /// Obtener items de la despensa del usuario
  static Future<List<dynamic>> getPantryItems() async {
    return await HttpClient.get('/pantry/items') as List<dynamic>;
  }

  /// Obtener un item de la despensa
  static Future<Map<String, dynamic>> getPantryItem(String itemId) async {
    return await HttpClient.get('/pantry/items/$itemId')
        as Map<String, dynamic>;
  }

  /// Agregar item a la despensa
  static Future<Map<String, dynamic>> addPantryItem({
    required String ingredientId,
    required int quantity,
    String? unit,
    String? expirationDate,
  }) async {
    return await HttpClient.post(
          '/pantry/items',
          body: {
            'ingredientId': ingredientId,
            'quantity': quantity,
            if (unit != null) 'unit': unit,
            if (expirationDate != null) 'expirationDate': expirationDate,
          },
        )
        as Map<String, dynamic>;
  }

  /// Actualizar cantidad de item
  static Future<Map<String, dynamic>> updatePantryItem(
    String itemId, {
    required int quantity,
    String? unit,
    String? expirationDate,
  }) async {
    return await HttpClient.put(
          '/pantry/items/$itemId',
          body: {
            'quantity': quantity,
            if (unit != null) 'unit': unit,
            if (expirationDate != null) 'expirationDate': expirationDate,
          },
        )
        as Map<String, dynamic>;
  }

  /// Eliminar item de la despensa
  static Future<void> removePantryItem(String itemId) async {
    await HttpClient.delete('/pantry/items/$itemId');
  }

  /// Limpiar toda la despensa
  static Future<void> clearPantry() async {
    await HttpClient.post('/pantry/clear', body: {});
  }

  // ====== INGREDIENTS DATABASE ======

  /// Obtener todos los ingredientes disponibles
  static Future<List<dynamic>> getIngredients({
    String? category,
    String? search,
  }) async {
    return await HttpClient.get(
          '/ingredients',
          queryParams: {
            if (category != null) 'category': category,
            if (search != null) 'search': search,
          },
        )
        as List<dynamic>;
  }

  /// Obtener un ingrediente
  static Future<Map<String, dynamic>> getIngredient(String ingredientId) async {
    return await HttpClient.get('/ingredients/$ingredientId')
        as Map<String, dynamic>;
  }

  /// Obtener categorías de ingredientes
  static Future<List<dynamic>> getIngredientCategories() async {
    return await HttpClient.get('/ingredients/categories') as List<dynamic>;
  }

  /// Buscar ingredientes por nombre
  static Future<List<dynamic>> searchIngredients(String query) async {
    return await HttpClient.get(
          '/ingredients/search',
          queryParams: {'q': query},
        )
        as List<dynamic>;
  }

  // ====== ALLERGENS/DIETARY ======

  /// Obtener alérgenos de la pantalla
  static Future<List<dynamic>> getPantryAllergens() async {
    return await HttpClient.get('/pantry/allergens') as List<dynamic>;
  }

  /// Obtener resumen nutricional de la pantalla
  static Future<Map<String, dynamic>> getPantryNutrition() async {
    return await HttpClient.get('/pantry/nutrition') as Map<String, dynamic>;
  }

  /// Obtener items próximos a vencer
  static Future<List<dynamic>> getExpiringItems({
    int daysUntilExpiration = 7,
  }) async {
    return await HttpClient.get(
          '/pantry/expiring',
          queryParams: {'daysUntilExpiration': daysUntilExpiration.toString()},
        )
        as List<dynamic>;
  }

  // ====== SHOPPING LIST ======

  /// Obtener lista de compras
  static Future<Map<String, dynamic>> getShoppingList() async {
    return await HttpClient.get('/shopping-list') as Map<String, dynamic>;
  }

  /// Agregar item a lista de compras
  static Future<Map<String, dynamic>> addToShoppingList({
    required String ingredientId,
    required int quantity,
    String? unit,
  }) async {
    return await HttpClient.post(
          '/shopping-list/items',
          body: {
            'ingredientId': ingredientId,
            'quantity': quantity,
            if (unit != null) 'unit': unit,
          },
        )
        as Map<String, dynamic>;
  }

  /// Marcar como completado en compras
  static Future<void> completeShoppingItem(String itemId) async {
    await HttpClient.post('/shopping-list/items/$itemId/complete', body: {});
  }

  /// Generar lista automática basada en recetas
  static Future<Map<String, dynamic>> generateShoppingList(
    List<String> recipeIds,
  ) async {
    return await HttpClient.post(
          '/shopping-list/generate',
          body: {'recipeIds': recipeIds},
        )
        as Map<String, dynamic>;
  }
}
