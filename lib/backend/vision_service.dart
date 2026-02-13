import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VisionService {
  static const _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  Future<String?> extractTextFromImage(File imageFile) async {
    final apiKey = dotenv.env['VISION_API_KEY'];
    if (apiKey == null) {
      throw Exception('VISION_API_KEY not found in .env');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final body = jsonEncode({
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              }
            ],
          }
        ]
      });

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final annotations = jsonResponse['responses'][0]['textAnnotations'];
        if (annotations != null && annotations.isNotEmpty) {
          return annotations[0]['description'];
        }
        return null; // No text found
      } else {
        throw Exception('Failed to extract text: ${response.body}');
      }
    } catch (e) {
      print('Error in VisionService: $e');
      return null;
    }
  }
}
