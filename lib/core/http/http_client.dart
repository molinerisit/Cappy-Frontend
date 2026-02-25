import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ============================================
/// HTTP CLIENT BASE
/// ============================================
///
/// Centraliza toda la lógica HTTP común:
/// - URLs base
/// - Headers
/// - Manejo de tokens
/// - Manejo de errores
/// - Logging
///
/// Todas las remote sources heredan de esta clase.

abstract class HttpClient {
  static const String baseUrl = "http://localhost:3000/api";
  static String? _token;

  // ====== Token Management ======

  /// Establecer token (después de login)
  static void setToken(String? token) {
    _token = token;
    if (kDebugMode) {
      print('🔐 HttpClient: Token set');
    }
  }

  /// Obtener token actual
  static String? getToken() => _token;

  /// Limpiar token (logout)
  static void clearToken() {
    _token = null;
    if (kDebugMode) {
      print('🔐 HttpClient: Token cleared');
    }
  }

  // ====== Common Headers ======

  /// Headers estándar para todas las requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ====== HTTP Methods ======

  /// GET request con error handling
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('📡 GET: $endpoint');
      }

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw HttpException('GET $endpoint failed: $e');
    }
  }

  /// POST request con error handling
  static Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('📡 POST: $endpoint');
      }

      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw HttpException('POST $endpoint failed: $e');
    }
  }

  /// PUT request con error handling
  static Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('📡 PUT: $endpoint');
      }

      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw HttpException('PUT $endpoint failed: $e');
    }
  }

  /// DELETE request con error handling
  static Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      if (kDebugMode) {
        print('📡 DELETE: $endpoint');
      }

      final response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw HttpException('DELETE $endpoint failed: $e');
    }
  }

  // ====== Response Handling ======

  /// Procesar respuesta HTTP con manejo centralizado de errores
  static dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('📊 Response [${response.statusCode}]');
    }

    // Success (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw HttpException('Failed to parse response: $e');
      }
    }

    // Unauthorized (401) - Token expirado/inválido
    if (response.statusCode == 401) {
      clearToken(); // Limpiar token inválido
      throw UnauthorizedException('Unauthorized. Please login again.');
    }

    // Forbidden (403)
    if (response.statusCode == 403) {
      throw ForbiddenException('Access denied.');
    }

    // Not Found (404)
    if (response.statusCode == 404) {
      throw NotFoundException('Resource not found.');
    }

    // Validation Error (422)
    if (response.statusCode == 422) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Validation error';
        throw ValidationException(message);
      } catch (e) {
        throw ValidationException('Validation error');
      }
    }

    // Server Error (5xx)
    if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.statusCode}');
    }

    // Generic error
    try {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? 'Unknown error';
      throw HttpException(message);
    } catch (e) {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

// ============================================
// CUSTOM EXCEPTIONS
// ============================================

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}
