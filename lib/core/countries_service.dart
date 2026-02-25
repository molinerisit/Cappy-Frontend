import 'package:http/http.dart' as http;
import 'dart:convert';

class CountriesService {
  final String baseUrl;

  CountriesService({required this.baseUrl});

  /// Mark a country as visited
  Future<Map<String, dynamic>> markCountryVisited(
    String token,
    String countryId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/countries/mark-visited'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'countryId': countryId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to mark country visited');
      }
    } catch (e) {
      print('Error marking country visited: $e');
      rethrow;
    }
  }

  /// Get all visited countries
  Future<Map<String, dynamic>> getMyVisitedCountries(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/countries/my-visited'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to fetch visited countries');
      }
    } catch (e) {
      print('Error fetching visited countries: $e');
      rethrow;
    }
  }
}
