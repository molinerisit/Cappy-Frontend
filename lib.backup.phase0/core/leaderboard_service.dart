import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardService {
  final String baseUrl;

  LeaderboardService({required this.baseUrl});

  /// Get global leaderboard (top 30 users)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      rethrow;
    }
  }

  /// Get current user's rank
  Future<Map<String, dynamic>> getMyRank(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard/my-rank'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to get user rank');
      }
    } catch (e) {
      print('Error fetching user rank: $e');
      rethrow;
    }
  }

  /// Get leaderboard around current user (10 above, user, 10 below)
  Future<List<Map<String, dynamic>>> getLeaderboardAroundMe(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard/around-me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load leaderboard around user');
      }
    } catch (e) {
      print('Error fetching leaderboard around user: $e');
      rethrow;
    }
  }
}
