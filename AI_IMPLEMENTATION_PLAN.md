# MediSafe — AI Backend Implementation Plan

> **Date:** 2026-02-23  
> **Goal:** Wire up real AI intelligence to the medicine scanner flow and the chatbot, replacing all hardcoded/stub values with live Gemini AI responses.

---

## 1. Frontend Analysis Summary

### 1.1 Current State of Each Key File

| File | What it does today | What's missing |
|---|---|---|
| `lib/screens/scan_page.dart` | Shows live camera preview, flash toggle, gallery picker | Capture button is a **TODO stub** — no OCR, no navigation to result page |
| `lib/screens/medicine_information_page.dart` | Renders a static result page with hardcoded "Panadol" data | All fields are hardcoded strings; no data model; page doesn't accept any parameters |
| `lib/screens/chatbot_page.dart` | Full chat UI (bubbles, drawer, history header, send field) | `_handleSend` returns a fake `"I am analyzing your query..."` after 1-second delay |
| `lib/widgets/floating_chatbot.dart` | Floating chat dialog, used from `home_page.dart` | `onSend` callback hardcodes `"Analyzing your medical query..."` — no AI call |
| `lib/screens/home_page.dart` | Displays allergies, medical history, active medicine, upcoming dose, floating chatbot FAB | Chatbot is purely decorative; floating chat doesn't call any AI |
| `pubspec.yaml` | Has `camera`, `image_picker`, Firebase stack | **Missing:** `google_generative_ai`, `google_mlkit_text_recognition` (OCR) |

### 1.2 Data Fields Rendered in `medicine_information_page.dart`

These are the UI sections that need real AI-generated content:

| UI Section | Widget | Field Name (proposed) |
|---|---|---|
| Medicine name | `_titleSection` → `Text("Panadol")` | `name` |
| Short description | `_titleSection` → `Text("short description")` | `shortDescription` |
| Medicine image / avatar | `CircleAvatar` (blank) | `imageUrl` (optional) |
| Function / Usage | `_functionSection` → `Text("Pain relief...")` | `function` |
| Side Effects | `_sideEffectDosage` → `Text("Nausea, rash")` | `sideEffects` (List\<String\>) |
| Dosage | `_sideEffectDosage` → `Text("500mg – 1000mg")` | `dosage` |
| Recipient Population | `_recipientSection` → pills (Adults, Children) | `recipients` (List\<String\>) |
| Not For These People | `_recipientSection` → pills (Liver disease…) | `contraindications` (List\<String\>) |
| Add To Schedule → medicine name | `TextEditingController(text: "Panadol")` | pre-filled from `name` |

### 1.3 Chatbot Context Requirement

- `chatbot_page.dart` — standalone chat, no medicine context passed  
- `floating_chatbot.dart` — opened from `home_page.dart`, also no context  
- **After scanning**, the chat should be **pre-seeded** with the scanned medicine's context so the AI agent can answer questions about it accurately

---

## 2. Packages to Add

```yaml
# pubspec.yaml additions
dependencies:
  google_generative_ai: ^0.4.3          # Gemini AI SDK (Dart)
  google_mlkit_text_recognition: ^0.13.1 # On-device OCR
  flutter_dotenv: ^5.1.0                # Secure API key loading from .env
```

> **Why on-device OCR?** `google_mlkit_text_recognition` runs entirely on-device, no network call needed for text extraction. This is fast and privacy-safe. The extracted raw text is then sent to Gemini.

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        USER FLOW                            │
│                                                             │
│  ScanPage ──[capture]──► OcrService                        │
│                              │                             │
│                              ▼                             │
│                         raw OCR text                       │
│                              │                             │
│                              ▼                             │
│                       GeminiService                        │
│                    identifyMedicine(ocrText)               │
│                              │                             │
│                              ▼                             │
│                      MedicineModel (JSON)                  │
│                              │                             │
│                              ▼                             │
│               MedicineInfoPage(medicine: model)            │
│                    (dynamic, no more hardcode)             │
│                              │                             │
│              [Chat button on result page]                  │
│                              ▼                             │
│          ChatbotPage(medicineContext: model)               │
│               GeminiService.chatSession(context)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. New Files to Create

### 4.1 `lib/models/medicine_model.dart`

A strongly-typed Dart model that represents the AI-parsed medicine:

```dart
class MedicineModel {
  final String name;
  final String shortDescription;
  final String function;
  final String dosage;
  final List<String> sideEffects;
  final List<String> recipients;        // who can take it
  final List<String> contraindications; // who should NOT take it
  final List<String> allergies;         // allergy warnings
  final String rawOcrText;              // stored for chatbot context

  const MedicineModel({ ... });

  factory MedicineModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### 4.2 `lib/services/ocr_service.dart`

Wraps `google_mlkit_text_recognition`:

```dart
class OcrService {
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer();
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();
    return result.text; // raw OCR string
  }
}
```

**API:** `OcrService.extractText(String imagePath) → Future<String>`

### 4.3 `lib/services/gemini_service.dart`

Two responsibilities — medicine identification and chat:

```dart
class GeminiService {
  final GenerativeModel _model;
  ChatSession? _chatSession;

  GeminiService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  // ── Medicine Identification ──────────────────────────────────
  Future<MedicineModel> identifyMedicine(String ocrText) async {
    // Sends structured prompt, requests JSON response
    // Parses JSON → MedicineModel
  }

  // ── Chat Session ────────────────────────────────────────────
  void startChatSession(MedicineModel? medicine) {
    // Primes the session with medicine context as system context
    _chatSession = _model.startChat(history: [...]);
  }

  Future<String> sendMessage(String userMessage) async {
    // Sends message to _chatSession, returns response text
  }
}
```

**APIs:**
- `GeminiService.identifyMedicine(String ocrText) → Future<MedicineModel>`
- `GeminiService.startChatSession(MedicineModel? medicine)`
- `GeminiService.sendMessage(String message) → Future<String>`

---

## 5. Gemini Prompt Design

### 5.1 Medicine Identification Prompt

```
You are a pharmaceutical assistant AI. Given the following OCR-extracted text from a medicine packaging label, identify the medicine and return a JSON object with this exact structure:

{
  "name": "...",
  "shortDescription": "...",
  "function": "...",
  "dosage": "...",
  "sideEffects": ["...", "..."],
  "recipients": ["...", "..."],
  "contraindications": ["...", "..."],
  "allergies": ["...", "..."]
}

Rules:
- If you cannot identify the medicine, set name to "Unknown Medicine" and fill other fields with "N/A" or [].
- Return ONLY valid JSON, no markdown, no explanation.
- Base your answer on known pharmaceutical knowledge, not just the label text.

OCR Text:
"""
{ocrText}
"""
```

### 5.2 Chat System Prompt (with medicine context)

```
You are MediSafe, a friendly and knowledgeable medicine companion AI.
The user has just scanned the following medicine:

Medicine Name: {medicine.name}
Function: {medicine.function}
Dosage: {medicine.dosage}
Side Effects: {medicine.sideEffects.join(', ')}
Who can use it: {medicine.recipients.join(', ')}
Who should NOT use it: {medicine.contraindications.join(', ')}
Allergy warnings: {medicine.allergies.join(', ')}

Answer the user's questions about this medicine accurately and in plain language.
Always recommend consulting a doctor for personalized medical advice.
```

### 5.3 Generic Chat System Prompt (no medicine scanned)

```
You are MediSafe, a friendly and knowledgeable medicine companion AI.
You help users understand medicines, dosages, side effects, and general health queries.
Always recommend consulting a licensed doctor for personalized medical advice.
```

---

## 6. Files to Modify

### 6.1 `lib/screens/scan_page.dart`

**Changes:**
1. Implement the capture button (`onPressed` — currently `// TODO: implement capture`)
2. Call `OcrService.extractText(imagePath)` on the captured image
3. Show a loading indicator while processing
4. Call `GeminiService.identifyMedicine(ocrText)`
5. Navigate to `MedicineInfoPage(medicine: result)` on success
6. Show an error dialog if OCR or AI fails

**Key code change:**
```dart
// In the camera capture button's onPressed:
onPressed: () async {
  final XFile photo = await _controller!.takePicture();
  setState(() => _isProcessing = true);
  try {
    final ocrText = await OcrService().extractText(photo.path);
    final medicine = await GeminiService().identifyMedicine(ocrText);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MedicineInfoPage(medicine: medicine),
    ));
  } catch (e) {
    // show error snackbar
  } finally {
    setState(() => _isProcessing = false);
  }
},
```

Also: apply same flow when user picks from **gallery** (`_openGallery`).

### 6.2 `lib/screens/medicine_information_page.dart`

**Changes:**
1. Convert from `StatelessWidget` to accept a `MedicineModel` parameter
2. Replace all hardcoded strings with `widget.medicine.*` references
3. Pre-fill `TextEditingController(text: medicine.name)` in `_showAddScheduleDialog`
4. Add a **"Chat about this medicine"** button that opens `ChatbotPage` with the medicine context

```dart
class MedicineInfoPage extends StatelessWidget {
  final MedicineModel medicine; // ← ADD THIS
  const MedicineInfoPage({super.key, required this.medicine});
  ...
}
```

**UI fields to wire up:**

| Hardcoded value | Replace with |
|---|---|
| `"Panadol"` | `medicine.name` |
| `"short description"` | `medicine.shortDescription` |
| `"Pain relief and fever reduction"` | `medicine.function` |
| `"Nausea, rash"` | `medicine.sideEffects.join(', ')` |
| `"500mg – 1000mg"` | `medicine.dosage` |
| `["Adults", "Children"]` pills | `medicine.recipients` list |
| `["Liver disease", "Alcohol abuse"]` pills | `medicine.contraindications` list |
| `TextEditingController(text: "Panadol")` | `TextEditingController(text: medicine.name)` |

### 6.3 `lib/screens/chatbot_page.dart`

**Changes:**
1. Accept an optional `MedicineModel? medicine` constructor parameter
2. On `initState`, call `GeminiService().startChatSession(medicine)`
3. Replace the mock `_handleSend` with a real async call to `GeminiService().sendMessage(text)`
4. Show a typing indicator while waiting for the AI response
5. Persist chat history in the `_messages` list (already exists)
6. (Optional) Save/load history from Firestore for the drawer "Chat History" section

```dart
class ChatbotPage extends StatefulWidget {
  final MedicineModel? medicine; // ← ADD THIS (nullable = general chat)
  const ChatbotPage({super.key, this.medicine});
  ...
}
```

**Updated `_handleSend`:**
```dart
void _handleSend() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;
  setState(() {
    _messages.add(Message(text: text, isUser: true));
    _isTyping = true;         // show typing indicator
    _messageController.clear();
  });
  try {
    final reply = await _geminiService.sendMessage(text);
    setState(() => _messages.add(Message(text: reply, isUser: false)));
  } catch (e) {
    setState(() => _messages.add(Message(text: "Sorry, I couldn't process that.", isUser: false)));
  } finally {
    setState(() => _isTyping = false);
  }
}
```

### 6.4 `lib/widgets/floating_chatbot.dart`

**Changes:**
1. Accept optional `MedicineModel? medicine` parameter
2. Pass it through the `onSend` callback chain to `GeminiService`
3. OR refactor: move AI logic into the widget itself with its own `GeminiService` instance

### 6.5 `.env` / `.env.example`

Add:
```
GEMINI_API_KEY=your_gemini_api_key_here
```

### 6.6 `pubspec.yaml`

Add the three new packages listed in Section 2.

### 6.7 `lib/main.dart`

Load `.env` at startup:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
...
await dotenv.load(fileName: ".env");
```

---

## 7. Full User Flow (End-to-End)

```
1. User taps the 📷 scanner button in MedicalBottomNav
2. ScanPage opens — camera preview is live
3. User frames medicine packaging in the scan box
4. User taps the round capture button (or picks from gallery)
5. ScanPage captures image → shows loading spinner
6. OcrService.extractText() runs on-device OCR → raw text string
7. GeminiService.identifyMedicine(ocrText) sends text to Gemini API
8. Gemini returns structured JSON → parsed into MedicineModel
9. Navigate to MedicineInfoPage(medicine: model)
   ├─ Name, description, function, dosage, side effects
   ├─ Recipient population pills
   ├─ Contraindications pills (allergy warnings)
   └─ "Add To Schedule" dialog pre-filled with medicine name
10. User taps "Chat about this medicine" button on result page
11. ChatbotPage(medicine: model) opens
    ├─ GeminiService session primed with full medicine context
    ├─ AI responds accurately to medicine-specific questions
    └─ Typing indicator shows while AI generates response
```

---

## 8. API Keys & Security

| Key | Where stored | How loaded |
|---|---|---|
| `GEMINI_API_KEY` | `.env` (git-ignored) | `flutter_dotenv` at app start |
| Firebase keys | `google-services.json` / `GoogleService-Info.plist` | Firebase SDK (already working) |
| Google Maps key | Already in `.env` / build config | Already working |

> ⚠️ **Never** hardcode the Gemini API key in Dart source. Always load via `dotenv.env['GEMINI_API_KEY']`.

---

## 9. Error Handling Plan

| Scenario | Handling |
|---|---|
| Camera permission denied | Already handled in `_initCamera` — extend to show settings prompt |
| OCR finds no text | Show dialog: "Could not read text from image. Try again with better lighting." |
| Gemini returns malformed JSON | Retry once, then show: "Could not identify medicine. Please try again." |
| Gemini API error (network, quota) | Show error snackbar with retry button |
| Unknown medicine | Render `MedicineInfoPage` with `"Unknown Medicine"` and partial data |
| Chat message fails | Show inline error bubble: "Sorry, I couldn't process that." |

---

## 10. Implementation Order (Step-by-Step)

| Step | Task | Files |
|---|---|---|
| 1 | Add packages to `pubspec.yaml`, run `flutter pub get` | `pubspec.yaml` |
| 2 | Add `GEMINI_API_KEY` to `.env`, load in `main.dart` | `.env`, `main.dart` |
| 3 | Create `MedicineModel` data class | `lib/models/medicine_model.dart` |
| 4 | Create `OcrService` (on-device OCR) | `lib/services/ocr_service.dart` |
| 5 | Create `GeminiService` (identify + chat) | `lib/services/gemini_service.dart` |
| 6 | Update `ScanPage` — implement capture + pipeline | `lib/screens/scan_page.dart` |
| 7 | Update `MedicineInfoPage` — accept model, wire all fields | `lib/screens/medicine_information_page.dart` |
| 8 | Update `ChatbotPage` — real AI chat + optional medicine context | `lib/screens/chatbot_page.dart` |
| 9 | Update `FloatingChatbot` — wire to GeminiService | `lib/widgets/floating_chatbot.dart` |
| 10 | Add "Chat about this medicine" button to result page | `lib/screens/medicine_information_page.dart` |
| 11 | Manual QA + edge case testing | All |

---

## 11. Verification Plan

### 11.1 Unit / Integration Tests
- `OcrService` — test with a known image file, assert non-empty text returned
- `GeminiService.identifyMedicine` — test with known drug label OCR text, assert `MedicineModel` fields are populated
- `MedicineModel.fromJson` — test JSON parsing with a fixture JSON

### 11.2 Manual QA Checklist

**Scan Flow:**
- [ ] Open app → tap scanner in bottom nav
- [ ] Point at any medicine box → tap capture → spinner visible
- [ ] Result page shows **real** medicine name (not "Panadol")
- [ ] All fields (function, dosage, side effects, recipients, contraindications) populated
- [ ] "Add To Schedule" dialog pre-fills the correct medicine name
- [ ] Test with gallery image (a photo of a medicine box)
- [ ] Test with blurry/bad image → error dialog shown

**Chat Flow (from result page):**
- [ ] On result page, tap "Chat about this medicine"
- [ ] ChatbotPage opens; AI responds contextually to medicine-specific questions
- [ ] Ask "What are the side effects?" → AI responds accurately for the scanned medicine
- [ ] Ask unrelated question → AI still responds helpfully

**General Chatbot:**
- [ ] Tap Chatbot in bottom nav (no medicine scanned)
- [ ] AI responds as a general medicine assistant
- [ ] Floating chatbot on Home page → also responds via AI

**Floating Chatbot (Home Page):**
- [ ] Tap FAB chatbot icon on Home
- [ ] Send a message → AI responds (no hardcoded text)
