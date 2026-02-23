import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/medicine_model.dart';
import '../models/user_profile_model.dart';
import 'firestore_service.dart';

class GeminiService {
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MEDICINE IDENTIFICATION
  // ─────────────────────────────────────────────

  Future<MedicineModel> identifyMedicine(String ocrText) async {
    // Fetch user profile to personalise the AI response
    UserProfileModel? profile;
    try {
      final profileData = await FirestoreService().getUserProfileOnce();
      if (profileData != null) {
        profile = UserProfileModel.fromFirestore(profileData);
      }
    } catch (_) {
      // Profile fetch failed — proceed without it
    }

    final userContext = profile != null ? profile.toAiContext() : '';
    final hasUserContext = userContext.trim().isNotEmpty;

    final prompt = '''
You are a pharmaceutical assistant AI.
${hasUserContext ? userContext : ''}

Given the following OCR-extracted text from a medicine packaging label, identify the medicine and return ONLY a valid JSON object with this exact structure (no markdown, no explanation, no extra text):

{
  "name": "...",
  "shortDescription": "...",
  "function": "...",
  "dosage": "...",
  "sideEffects": ["...", "..."],
  "recipients": ["...", "..."],
  "contraindications": ["...", "..."],
  "allergies": ["...", "..."],
  "personalizedWarning": "${hasUserContext ? 'Write a short warning if the medicine conflicts with the user profile above, else empty string' : ''}"
}

Rules:
- If you cannot identify the medicine confidently, use "Unknown Medicine" for name and reasonable placeholder values.
- Return ONLY valid JSON. No markdown fences. No explanation before or after.
- Base your answer on known pharmaceutical knowledge combined with the label text.

OCR Text:
"""
$ocrText
"""
''';

    // Try up to 2 times
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        
        // Strip any accidental markdown fences
        final clean = text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        // Extract JSON even if there's text around it
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
        if (jsonMatch == null) {
          if (attempt == 0) continue;
          return MedicineModel.unknown(ocrText);
        }

        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MedicineModel.fromJson(json);
      } catch (e) {
        if (attempt == 1) {
          print("GEMINI API ERROR: $e");
          throw Exception("Gemini API Error: $e");
        }
      }
    }
    throw Exception("Failed to identify medicine after retries.");
  }

  // ─────────────────────────────────────────────
  // CHAT SESSION
  // ─────────────────────────────────────────────

  void startChatSession({MedicineModel? medicine, UserProfileModel? profile}) {
    final medicinePart = medicine != null ? '''
The user has just scanned the following medicine:
- Name: ${medicine.name}
- Description: ${medicine.shortDescription}
- Function: ${medicine.function}
- Dosage: ${medicine.dosage}
- Side Effects: ${medicine.sideEffects.join(', ')}
- Suitable for: ${medicine.recipients.join(', ')}
- NOT suitable for: ${medicine.contraindications.join(', ')}
- Allergy warnings: ${medicine.allergies.join(', ')}
''' : '';

    final userPart = profile != null ? profile.toAiContext() : '';

    final systemPrompt = '''
You are MediSafe, a friendly and knowledgeable medicine companion AI.
$medicinePart
$userPart
Answer the user's questions accurately and in plain, easy-to-understand language.
Keep responses concise and helpful.
Always recommend consulting a licensed doctor for personalised medical advice.
If the user asks about something that may conflict with their known allergies or medical history, warn them clearly.
''';

    try {
      _chatSession = _model.startChat(history: [
        Content.text(systemPrompt),
        Content.model([TextPart('Hello! I\'m MediSafe, your medicine companion. How can I help you today?')]),
      ]);
    } catch (_) {
      _chatSession = null;
    }
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      if (_chatSession == null) {
        startChatSession(); // fallback: general chat
      }
      if (_chatSession == null) {
        return 'Sorry, the AI service is not available right now. Please check your internet connection.';
      }
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );
      return response.text ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      // Reset session on error
      _chatSession = null;
      if (e.toString().contains('API key')) {
        return 'Error: Invalid API key. Please check your configuration.';
      }
      if (e.toString().contains('network') || e.toString().contains('socket')) {
        return 'Network error. Please check your internet connection.';
      }
      return 'Sorry, something went wrong. Please try again.';
    }
  }
}
