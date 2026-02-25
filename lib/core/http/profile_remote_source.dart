import 'http_client.dart';

/// ============================================
/// PROFILE REMOTE SOURCE
/// ============================================
///
/// Todos los métodos relacionados con:
/// - Perfil de usuario
/// - Datos personales
/// - Preferencias
/// - Configuración
///
/// Uso:
/// ```dart
/// final profile = await ProfileRemoteSource.getProfile();
/// await ProfileRemoteSource.updateProfile(data);
/// ```

abstract class ProfileRemoteSource {
  // ====== PROFILE ======

  /// Obtener perfil actual del usuario
  static Future<Map<String, dynamic>> getProfile() async {
    return await HttpClient.get('/users/me') as Map<String, dynamic>;
  }

  /// Actualizar perfil
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/users/me', body: data)
        as Map<String, dynamic>;
  }

  /// Actualizar avatar
  static Future<Map<String, dynamic>> updateAvatar(String imageUrl) async {
    return await HttpClient.put(
          '/users/me/avatar',
          body: {'imageUrl': imageUrl},
        )
        as Map<String, dynamic>;
  }

  /// Obtener datos públicos de un usuario
  static Future<Map<String, dynamic>> getUserPublic(String userId) async {
    return await HttpClient.get('/users/$userId') as Map<String, dynamic>;
  }

  // ====== PREFERENCES ======

  /// Obtener preferencias
  static Future<Map<String, dynamic>> getPreferences() async {
    return await HttpClient.get('/users/me/preferences')
        as Map<String, dynamic>;
  }

  /// Actualizar preferencias
  static Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/users/me/preferences', body: data)
        as Map<String, dynamic>;
  }

  /// Establecer idioma preferido
  static Future<void> setLanguage(String languageCode) async {
    await HttpClient.put(
      '/users/me/preferences/language',
      body: {'language': languageCode},
    );
  }

  /// Habilitar/deshabilitar notificaciones
  static Future<void> setNotifications(bool enabled) async {
    await HttpClient.put(
      '/users/me/preferences/notifications',
      body: {'enabled': enabled},
    );
  }

  // ====== DIETARY PREFERENCES ======

  /// Obtener restricciones dietéticas
  static Future<Map<String, dynamic>> getDietaryPreferences() async {
    return await HttpClient.get('/users/me/dietary-preferences')
        as Map<String, dynamic>;
  }

  /// Actualizar restricciones dietéticas
  static Future<Map<String, dynamic>> updateDietaryPreferences(
    Map<String, dynamic> data,
  ) async {
    return await HttpClient.put('/users/me/dietary-preferences', body: data)
        as Map<String, dynamic>;
  }

  // ====== COOKING LEVEL ======

  /// Obtener nivel de cocina
  static Future<Map<String, dynamic>> getCookingLevel() async {
    return await HttpClient.get('/users/me/cooking-level')
        as Map<String, dynamic>;
  }

  /// Actualizar nivel de cocina
  static Future<Map<String, dynamic>> updateCookingLevel(String level) async {
    return await HttpClient.put(
          '/users/me/cooking-level',
          body: {'level': level},
        )
        as Map<String, dynamic>;
  }

  // ====== FOLLOWERS/FOLLOWING ======

  /// Obtener seguidores
  static Future<List<dynamic>> getFollowers(String userId) async {
    return await HttpClient.get('/users/$userId/followers') as List<dynamic>;
  }

  /// Obtener seguidos
  static Future<List<dynamic>> getFollowing(String userId) async {
    return await HttpClient.get('/users/$userId/following') as List<dynamic>;
  }

  /// Seguir a un usuario
  static Future<void> follow(String userId) async {
    await HttpClient.post('/users/$userId/follow', body: {});
  }

  /// Dejar de seguir
  static Future<void> unfollow(String userId) async {
    await HttpClient.post('/users/$userId/unfollow', body: {});
  }

  /// Bloquear usuario
  static Future<void> block(String userId) async {
    await HttpClient.post('/users/$userId/block', body: {});
  }

  /// Desbloquear usuario
  static Future<void> unblock(String userId) async {
    await HttpClient.post('/users/$userId/unblock', body: {});
  }

  // ====== BADGES/ACHIEVEMENTS ======

  /// Obtener insignias obtenidas
  static Future<List<dynamic>> getBadges() async {
    return await HttpClient.get('/users/me/badges') as List<dynamic>;
  }

  /// Obtener logros de un usuario
  static Future<List<dynamic>> getAchievements(String userId) async {
    return await HttpClient.get('/users/$userId/achievements') as List<dynamic>;
  }
}
