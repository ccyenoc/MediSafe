import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  /// Analyzes extracted text to identify medicine and provide details.
  Future<Map<String, dynamic>> analyzeMedicineText(String extractedText) async {
    final prompt = '''
    Analyze the following text extracted from a medicine package:
    "$extractedText"

    Identify the medicine name. Provide the following details in JSON format only (no markdown, no extra text):
    {
      "name": "Medicine Name",
      "description": "Simple language explanation of what it does",
      "dosage": "General dosage guidelines (e.g., Adults: 1-2 tablets)",
      "side_effects": ["Side effect 1", "Side effect 2"],
      "allergies": ["Warning 1", "Warning 2"],
      "recipient_population": ["Adults", "Children"],
      "not_for": ["Group A", "Group B"],
      "is_dangerous": false,
      "advice": "General advice"
    }
    If the text does not look like a medicine, return {"error": "Could not identify medicine"}.
    If it is a controlled substance or dangerous, set "is_dangerous" to true.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return {'error': 'No response from AI'};

      // Clean up markdown code blocks if present
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(cleanedText);
    } catch (e) {
      print('Error in GeminiService: $e');
      return {'error': 'Failed to analyze medicine'};
    }
  }

  /// Chat with the AI Companion.
  Future<String> chatWithCompanion(String userMessage, {List<String>? history}) async {
    // Note: In a real app, we would manage full chat history here.
    // For now, we just send the user message with a persona context.
    
    final prompt = '''
    You are MediSafe, a helpful medication companion AI. You are NOT a doctor.
    User asks: "$userMessage"
    
    Answer in simple, easy-to-understand language. 
    If the user asks for medical diagnosis, kindly suggest they visit a doctor.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "I'm sorry, I couldn't understand that.";
    } catch (e) {
      return "I'm having trouble connecting right now. Please try again.";
    }
  }
}
