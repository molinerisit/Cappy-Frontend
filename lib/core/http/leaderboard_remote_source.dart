import 'http_client.dart';

/// ============================================
/// LEADERBOARD REMOTE SOURCE
/// ============================================
///
/// Todos los métodos relacionados con:
/// - Rankings
/// - Competiciones
/// - Estadísticas de usuarios
///
/// Uso:
/// ```dart
/// final ranking = await LeaderboardRemoteSource.getGlobalRanking();
/// final friends = await LeaderboardRemoteSource.getFriendsRanking();
/// ```

abstract class LeaderboardRemoteSource {
  // ====== GLOBAL RANKING ======

  /// Obtener ranking global
  static Future<List<dynamic>> getGlobalRanking({
    int limit = 100,
    int offset = 0,
  }) async {
    return await HttpClient.get(
          '/leaderboard/global',
          queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener posición del usuario en ranking global
  static Future<Map<String, dynamic>> getGlobalRankingPosition() async {
    return await HttpClient.get('/leaderboard/global/me')
        as Map<String, dynamic>;
  }

  // ====== FRIENDS RANKING ======

  /// Obtener ranking de amigos
  static Future<List<dynamic>> getFriendsRanking({int limit = 50}) async {
    return await HttpClient.get(
          '/leaderboard/friends',
          queryParams: {'limit': limit.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener posición entre amigos
  static Future<Map<String, dynamic>> getFriendsRankingPosition() async {
    return await HttpClient.get('/leaderboard/friends/me')
        as Map<String, dynamic>;
  }

  // ====== COUNTRY RANKING ======

  /// Obtener ranking por país
  static Future<List<dynamic>> getCountryRanking(
    String countryId, {
    int limit = 100,
  }) async {
    return await HttpClient.get(
          '/leaderboard/country/$countryId',
          queryParams: {'limit': limit.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener posición en ranking del país
  static Future<Map<String, dynamic>> getCountryRankingPosition(
    String countryId,
  ) async {
    return await HttpClient.get('/leaderboard/country/$countryId/me')
        as Map<String, dynamic>;
  }

  // ====== PATH RANKING ======

  /// Obtener ranking en un camino específico
  static Future<List<dynamic>> getPathRanking(
    String pathId, {
    int limit = 100,
  }) async {
    return await HttpClient.get(
          '/leaderboard/path/$pathId',
          queryParams: {'limit': limit.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener posición en ranking del camino
  static Future<Map<String, dynamic>> getPathRankingPosition(
    String pathId,
  ) async {
    return await HttpClient.get('/leaderboard/path/$pathId/me')
        as Map<String, dynamic>;
  }

  // ====== TIME-BASED RANKING ======

  /// Obtener ranking de esta semana
  static Future<List<dynamic>> getWeeklyRanking({int limit = 100}) async {
    return await HttpClient.get(
          '/leaderboard/weekly',
          queryParams: {'limit': limit.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener ranking del mes
  static Future<List<dynamic>> getMonthlyRanking({int limit = 100}) async {
    return await HttpClient.get(
          '/leaderboard/monthly',
          queryParams: {'limit': limit.toString()},
        )
        as List<dynamic>;
  }

  /// Obtener posición en ranking semanal
  static Future<Map<String, dynamic>> getWeeklyRankingPosition() async {
    return await HttpClient.get('/leaderboard/weekly/me')
        as Map<String, dynamic>;
  }

  /// Obtener posición en ranking mensual
  static Future<Map<String, dynamic>> getMonthlyRankingPosition() async {
    return await HttpClient.get('/leaderboard/monthly/me')
        as Map<String, dynamic>;
  }

  // ====== USER STATS ======

  /// Obtener estadísticas del usuario actual
  static Future<Map<String, dynamic>> getMyStats() async {
    return await HttpClient.get('/users/me/stats') as Map<String, dynamic>;
  }

  /// Obtener estadísticas de un usuario
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await HttpClient.get('/users/$userId/stats') as Map<String, dynamic>;
  }

  // ====== ACHIEVEMENTS ======

  /// Obtener logros conseguidos
  static Future<List<dynamic>> getMyAchievements() async {
    return await HttpClient.get('/achievements/me') as List<dynamic>;
  }

  /// Obtener logros disponibles
  static Future<List<dynamic>> getAllAchievements() async {
    return await HttpClient.get('/achievements') as List<dynamic>;
  }

  /// Obtener progreso hacia un logro
  static Future<Map<String, dynamic>> getAchievementProgress(
    String achievementId,
  ) async {
    return await HttpClient.get('/achievements/$achievementId/progress')
        as Map<String, dynamic>;
  }

  // ====== CHALLENGES ======

  /// Obtener retos activos
  static Future<List<dynamic>> getActiveChallenges() async {
    return await HttpClient.get('/challenges') as List<dynamic>;
  }

  /// Obtener un reto
  static Future<Map<String, dynamic>> getChallenge(String challengeId) async {
    return await HttpClient.get('/challenges/$challengeId')
        as Map<String, dynamic>;
  }

  /// Aceptar un reto
  static Future<Map<String, dynamic>> acceptChallenge(
    String challengeId,
  ) async {
    return await HttpClient.post('/challenges/$challengeId/accept', body: {})
        as Map<String, dynamic>;
  }

  /// Completar un reto
  static Future<Map<String, dynamic>> completeChallenge(
    String challengeId,
  ) async {
    return await HttpClient.post('/challenges/$challengeId/complete', body: {})
        as Map<String, dynamic>;
  }

  /// Obtener retos completados
  static Future<List<dynamic>> getCompletedChallenges() async {
    return await HttpClient.get('/challenges/completed') as List<dynamic>;
  }
}
