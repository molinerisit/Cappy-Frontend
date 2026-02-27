import 'package:http/http.dart' as http;
import 'dart:convert';

class LivesService {
  final String baseUrl;

  LivesService({required this.baseUrl});

  Uri _buildUri(String endpointPath) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final hasApiSuffix = normalizedBase.endsWith('/api');
    final normalizedPath = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';
    final resolvedPath = hasApiSuffix ? normalizedPath : '/api$normalizedPath';
    return Uri.parse('$normalizedBase$resolvedPath');
  }

  /// Get current lives status
  Future<Map<String, dynamic>> getLivesStatus(String token) async {
    try {
      final response = await http.get(
        _buildUri('/lives/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to get lives status');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lose one life (called when user fails a question)
  Future<Map<String, dynamic>> loseLive(String token) async {
    try {
      final response = await http.post(
        _buildUri('/lives/lose'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to lose life');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user can start a lesson
  Future<bool> canStartLesson(String token) async {
    try {
      final response = await http.get(
        _buildUri('/lives/can-start-lesson'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['canStart'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get time until next life refill (in milliseconds)
  Future<int> getTimeUntilNextLife(String token) async {
    try {
      final response = await http.get(
        _buildUri('/lives/time-until-next'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['timeRemainingMs'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Check and refill lives if available
  Future<Map<String, dynamic>> checkRefill(String token) async {
    try {
      final response = await http.put(
        _buildUri('/lives/check-refill'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to check refill');
      }
    } catch (e) {
      rethrow;
    }
  }
}
