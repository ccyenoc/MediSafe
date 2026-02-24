import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 8192,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MEDICINE IDENTIFICATION (Vision + OCR)
  // ─────────────────────────────────────────────

  Future<MedicineModel> identifyMedicine(String ocrText,
      {String? imagePath}) async {
    // Fetch user profile for personalization
    UserProfileModel? profile;
    try {
      final profileData = await FirestoreService().getUserProfileOnce();
      if (profileData != null) {
        profile = UserProfileModel.fromFirestore(profileData);
      }
    } catch (_) {}

    final userContext = profile != null ? profile.toAiContext() : '';
    final hasUserContext = userContext.trim().isNotEmpty;

    // Deduplicate repeated OCR lines (blister packs repeat the same line many times)
    final dedupedOcr = ocrText.split('\n').toSet().toList().join('\n').trim();

    // Feature 5: Age-aware prompt modifiers
    final ageHint = profile != null && profile.age > 0
        ? (profile.age < 12
            ? '\nIMPORTANT: This is a CHILD patient (age ${profile.age}). Adjust dosage guidance for children.'
            : profile.age >= 65
                ? '\nIMPORTANT: This is an ELDERLY patient (age ${profile.age}). Flag any medicines that require reduced dosage for elderly.'
                : '')
        : '';

    final promptText = '''You are a medicine expert AI. Your job is to give clear, specific, accurate information to someone who has zero medical knowledge.

${hasUserContext ? userContext : ''}$ageHint
STEP 1 — IDENTIFY the medicine from the image and OCR text below.
CRITICAL VALIDATION: If the image and text clearly show something that is NOT a medicine, supplement, or health product (e.g., a phone case, food, toy, screen protector), you MUST STOP. Return exactly this JSON:
{ "name": "Unknown Medicine", "shortDescription": "", "function": "", "dosage": "", "sideEffects": [], "recipients": [], "contraindications": [], "allergies": [], "personalizedWarning": "" }
Do NOT hallucinate a medicine. Only proceed to STEP 2 if it is actually a health product.

STEP 2 — FILL IN ALL FIELDS from your pharmaceutical knowledge database. Pretend the user can only see the medicine box front — give them everything else they need to know.

FIELD-BY-FIELD RULES (follow strictly):

"shortDescription": Max 12 words. Ultra-brief. What this medicine is for, in the simplest words. E.g. "Helps with gout pain and bladder discomfort." or "Antibiotic tablet that fights bacterial infections."

"function": 1 short sentence. Use simple everyday words and an analogy if possible. Imagine explaining to a 10-year-old. BAD: "It makes the urine less acidic which prevents calcium oxalate crystallization." GOOD: "It makes your pee less sour so crystals can't form and hurt your joints."

"dosage": Format as EXACTLY 3 short lines, each on a new line, like this:\nAmount: 1 sachet (4g)\nHow often: 3 times a day\nWhen: After meals. Keep each line under 6 words. Do NOT write a paragraph.

"sideEffects": List real known side effects with plain descriptions. Max 4 items. E.g. "Bloating or gassy feeling", "Stomach cramps", "Nausea if taken on empty stomach". BAD: "Gastrointestinal discomfort".

"recipients": State exactly who benefits. E.g. "Adults with gout flare-ups", "People with frequent urinary tract infections", "Anyone told by a doctor their urine is too acidic".

"contraindications": State exactly who must NOT take it and why in simple words. E.g. "People with high blood pressure (it contains sodium)", "Anyone with kidney failure", "Pregnant women — ask doctor first".

"allergies": List the actual chemical ingredients that could cause allergic reactions. Name them. E.g. "Sodium Citrate", "Citric Acid", "Tartaric Acid", "Sodium Bicarbonate". Do NOT say "allergic to any ingredient" — that is useless.

"personalizedWarning": Look closely at the image AND the OCR text. If you can clearly see an Expiry Date (e.g. "EXP", "Expiry", "Use By"), warn the user. E.g. "⚠️ The packaging says this medicine expires on [Date]." If it is obviously expired compared to today (${DateTime.now().year}), specifically say "⚠️ DO NOT TAKE: This medicine expired on [Date]." 
If there is NO expiry date visible, check if the medicine conflicts with the user profile context. E.g. "⚠️ Warning: You have an allergy to [Ingredient]." 
If neither applies, leave as empty string "".

GENERAL RULES:
- Plain English only. No medical jargon. Replace: "renal"→"kidney", "hypersensitivity"→"allergy", "dysuria"→"pain when peeing", "alkalinizer"→"makes urine less acidic".
- Every field must have REAL, SPECIFIC content from your training data. Never say "not listed", "not on packet", "see a doctor for details", or leave generic filler text.
- Lists: max 4 items, each max 10 words.
- Text fields: max 2 sentences.
- Return ONLY valid JSON. No markdown. No text outside the JSON.

OCR text (to identify the medicine only):
"""
$dedupedOcr
"""

{
  "name": "<brand name + strength>",
  "shortDescription": "<1 sentence, specific>",
  "function": "<1 sentence, specific mechanism>",
  "dosage": "<specific amount, timing, method>",
  "sideEffects": ["<specific>", "<specific>", "<specific>"],
  "recipients": ["<specific group>", "<specific group>"],
  "contraindications": ["<specific + reason>", "<specific + reason>"],
  "allergies": ["<actual ingredient name>", "<actual ingredient name>"],
  "personalizedWarning": "<Expiry warning OR allergy warning OR empty string>"
}''';

    // Build content parts: always include text, add image if available
    final List<Part> parts = [];
    if (imagePath != null) {
      try {
        final imageFile = File(imagePath);
        final bytes = await imageFile.readAsBytes();
        // Detect mime type from file extension
        final ext = imagePath.toLowerCase().split('.').last;
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        parts.add(DataPart(mime, bytes));
      } catch (e) {
        debugPrint('Could not read image file: $e');
      }
    }
    parts.add(TextPart(promptText));

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _model
            .generateContent([Content.multi(parts)]);
        final raw = response.text ?? '';
        debugPrint('GEMINI RAW RESPONSE: $raw');

        // Strip markdown fences if present
        final clean = raw
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        // Extract the JSON object
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
        if (jsonMatch == null) {
          debugPrint('No JSON found in response, attempt $attempt');
          if (attempt == 0) continue;
          throw Exception('AI did not return valid JSON. Response: $raw');
        }

        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        final model = MedicineModel.fromJson(json);
        debugPrint('Identified: ${model.name}');
        return model;
      } catch (e) {
        debugPrint('GEMINI ERROR attempt $attempt: $e');
        if (attempt == 1) {
          throw Exception('Gemini API Error: $e');
        }
      }
    }
    throw Exception('Failed to identify medicine after retries.');
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

  // ─────────────────────────────────────────────
  // SMART SCHEDULE SUGGESTION (Feature 3)
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getScheduleSuggestion(
      MedicineModel medicine, int? userAge) async {
    final ageStr = userAge != null
        ? 'User Age: $userAge.${userAge < 12 ? " Adjust for child." : ""}${userAge >= 65 ? " Prefer max twice daily for elderly." : ""}'
        : '';

    final prompt = '''Given this medicine: ${medicine.name}
Dosage info: ${medicine.dosage}
$ageStr

Return a JSON schedule suggestion:
{"timesPerDay": 3, "durationDays": 7, "suggestedTimes": ["08:00","14:00","20:00"], "notes": "Take with food"}
Rules:
- timesPerDay: integer 1-4 only.
- durationDays: integer 1-90 only.
- Return ONLY valid JSON, nothing else.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      final clean = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Schedule AI error: $e');
    }
    // Fallback defaults
    return {
      'timesPerDay': 1,
      'durationDays': 7,
      'suggestedTimes': ['08:00'],
      'notes': '',
    };
  }
}
