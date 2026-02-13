import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  /// Searches for nearby places of a specific type (e.g., pharmacy, hospital).
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type, // 'pharmacy', 'hospital', 'doctor'
    double radius = 5000, // 5km radius
  }) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env');
    }

    final url = '$_baseUrl?location=$latitude,$longitude&radius=$radius&type=$type&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          return results.map((place) {
            return {
              'name': place['name'],
              'vicinity': place['vicinity'],
              'geometry': place['geometry']['location'],
              'rating': place['rating'],
              'user_ratings_total': place['user_ratings_total'],
              'place_id': place['place_id'],
              'icon': place['icon'],
            };
          }).toList();
        } else {
          throw Exception('Places API Error: ${data['status']} - ${data['error_message'] ?? ''}');
        }
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in PlacesService: $e');
      return [];
    }
  }
}
