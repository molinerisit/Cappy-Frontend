import 'http_client.dart';

/// ============================================
/// AUTH REMOTE SOURCE
/// ============================================
///
/// Todos los métodos de autenticación y login
/// Separado del resto de funcionalidades
///
/// Uso:
/// ```dart
/// final response = await AuthRemoteSource.register(...);
/// final data = await AuthRemoteSource.login(...);
/// ```

abstract class AuthRemoteSource {
  // ====== Auth Endpoints ======

  /// Registrar nuevo usuario
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await HttpClient.post(
          '/auth/register',
          body: {'email': email, 'password': password, 'name': name},
        )
        as Map<String, dynamic>;
  }

  /// Login con email + password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await HttpClient.post(
          '/auth/login',
          body: {'email': email, 'password': password},
        )
        as Map<String, dynamic>;
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await HttpClient.post('/auth/logout', body: {});
    } finally {
      // Siempre limpiar token localmente, aunque falle el servidor
      HttpClient.clearToken();
    }
  }

  /// Verificar si token es válido
  static Future<Map<String, dynamic>> verifyToken() async {
    return await HttpClient.get('/auth/verify') as Map<String, dynamic>;
  }

  /// Refresh token
  static Future<Map<String, dynamic>> refreshToken() async {
    return await HttpClient.post('/auth/refresh', body: {})
        as Map<String, dynamic>;
  }

  /// Solicitar reset de password
  static Future<void> requestPasswordReset({required String email}) async {
    await HttpClient.post('/auth/forgot-password', body: {'email': email});
  }

  /// Reset password con token
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await HttpClient.post(
      '/auth/reset-password',
      body: {'token': token, 'newPassword': newPassword},
    );
  }

  /// Cambiar contraseña (usuario autenticado)
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await HttpClient.put(
      '/auth/change-password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }
}
