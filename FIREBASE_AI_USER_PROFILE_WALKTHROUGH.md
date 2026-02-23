# MediSafe — Firebase User Profile + AI Integration Walkthrough

> **Goal:** Store user's allergies, medical history, age, and location in Firestore so the AI agent can fetch and use this data to give personalized, safe medicine advice.

---

## 🔍 What Already Exists (Firebase Analysis)

### ✅ What's Working
| What | Where | Firestore path |
|---|---|---|
| User document created on registration | `auth_service.dart` | `users/{uid}` with `email`, `username`, `created_at` |
| Allergies saved on signup | `optional_info_page.dart` | `users/{uid}.allergies` (array) |
| Medical history saved on signup | `optional_info_page.dart` | `users/{uid}.medicalHistory` (array of strings) |
| Schedule sub-collection | `firestore_service.dart` | `users/{uid}/schedules/{docId}` |
| `getUserProfile()` stream | `firestore_service.dart` | Reads `users/{uid}` live |

### ❌ What's Broken / Missing
| Problem | Where | Impact |
|---|---|---|
| **Field name inconsistency** | `optional_info_page.dart` saves `medicalHistory`; `firestore_service.dart` reads/writes `medical_history` | AI will read empty data |
| **Settings page** allergies/history are **local state only** — never synced to Firestore | `settings_page.dart` | User edits in Settings are lost on restart |
| **No `age` field** ever saved to Firestore | `auth_service.dart`, `settings_page.dart` | Age shown in settings is local only |
| **No `location` field** in Firestore | Anywhere | AI has no location context |
| **AI never reads Firestore** | All AI stubs are hardcoded | AI gives generic advice, ignores user health profile |

---

## 🗺️ Target Firestore Data Structure

After following this walkthrough, each user document will look like this:

```
users/
  {uid}/
    email:           "user@email.com"
    username:        "Brayden"
    age:             25
    created_at:      Timestamp
    allergies:       ["Penicillin", "Peanuts"]
    medical_history: ["Hypertension", "Diabetes"]   ← unified field name
    location: {
      city:    "Kuala Lumpur"
      country: "Malaysia"
      lat:     3.1390
      lng:     101.6869
    }
    
    schedules/        ← subcollection (already exists)
      {docId}/
        medicine_name, dose, date, time ...
```

---

## 📋 Step-by-Step Implementation

---

### STEP 1 — Fix Field Name Inconsistency (`medical_history` vs `medicalHistory`)

**Problem:** `optional_info_page.dart` line 33 saves as `medicalHistory` but `firestore_service.dart` lines 74–83 read/write `medical_history`. These are two different Firestore fields.

**Fix:** Standardize everything to `medical_history` (snake_case, matching the schedule field style).

**File:** `lib/screens/optional_info_page.dart`

Find line 33:
```dart
// BEFORE
'medicalHistory': _hasNoHistory ? [] : _medicalHistory,

// AFTER
'medical_history': _hasNoHistory ? [] : _medicalHistory,
```

---

### STEP 2 — Add `age` and `location` to User Registration

**File:** `lib/services/auth_service.dart`

Update `registerUser` to include `age` and default `location`:

```dart
await _firestore.collection('users').doc(uid).set({
  'email': email,
  'username': username,
  'age': 0,                      // ← ADD: default, updated later in Settings
  'created_at': Timestamp.now(),
  'allergies': [],               // ← ADD: initialize empty arrays
  'medical_history': [],         // ← ADD: initialize empty arrays
  'location': {                  // ← ADD: default empty location
    'city': '',
    'country': '',
    'lat': null,
    'lng': null,
  },
});
```

> **Why initialize arrays here?** Firestore's `arrayUnion` fails silently if the field doesn't exist. Initializing here prevents that.

---

### STEP 3 — Add Location & Age Methods to `FirestoreService`

**File:** `lib/services/firestore_service.dart`

Add these new methods at the bottom of the class:

```dart
/// ==========================
/// AGE METHOD
/// ==========================

Future<void> updateAge(int age) async {
  await _firestore.collection('users').doc(uid).update({'age': age});
}

/// ==========================
/// LOCATION METHOD
/// ==========================

Future<void> updateLocation({
  required String city,
  required String country,
  required double lat,
  required double lng,
}) async {
  await _firestore.collection('users').doc(uid).update({
    'location': {
      'city': city,
      'country': country,
      'lat': lat,
      'lng': lng,
    }
  });
}

/// ==========================
/// FULL PROFILE FETCH (for AI)
/// ==========================

Future<Map<String, dynamic>?> getUserProfileOnce() async {
  final doc = await _firestore.collection('users').doc(uid).get();
  return doc.data();
}
```

---

### STEP 4 — Sync Settings Page to Firestore

**File:** `lib/screens/settings_page.dart`

#### 4a. Add imports and service
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

// Inside _SettingsPageState:
final _firestoreService = FirestoreService();
```

#### 4b. Load profile data from Firestore on init
```dart
@override
void initState() {
  super.initState();
  _loadProfile();
}

Future<void> _loadProfile() async {
  final data = await _firestoreService.getUserProfileOnce();
  if (data != null) {
    setState(() {
      _username = data['username'] ?? 'New User';
      _age = (data['age'] ?? 0).toString();
      allergies = List<String>.from(data['allergies'] ?? []);
      // medical history needs name extraction
      medicalHistory = (data['medical_history'] as List<dynamic>? ?? [])
          .map((e) => {'name': e.toString(), 'date': ''})
          .toList();
    });
  }
}
```

#### 4c. Save age when user edits profile
```dart
// In _showEditProfileDialog, inside the Save button onPressed:
await _firestoreService.updateAge(int.tryParse(ageCtrl.text) ?? 0);
```

#### 4d. Sync allergy add/remove to Firestore
```dart
// Add allergy:
await _firestoreService.addAllergy(addCtrl.text);

// Remove allergy:
await _firestoreService.removeAllergy(a);
```

#### 4e. Sync medical history add to Firestore
```dart
// Add history:
await _firestoreService.addMedicalHistory(diseaseCtrl.text);

// Remove history:
await _firestoreService.removeMedicalHistory(h['name']!);
```

---

### STEP 5 — Capture User Location

Use the device's GPS to get city/country when the user opens the app or visits the Near Me page.

#### 5a. Add `geolocator` package to `pubspec.yaml`
```yaml
dependencies:
  geolocator: ^12.0.0
  geocoding: ^3.0.0     # converts lat/lng → city name
```

#### 5b. Add permissions

**Android** (`android/app/src/main/AndroidManifest.xml`) — already has location for Maps, but confirm:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** (`ios/Runner/Info.plist`) — already has for Maps, confirm:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MediSafe uses your location to find nearby pharmacies and personalise AI recommendations.</string>
```

#### 5c. Create location capture utility

**New file:** `lib/services/location_service.dart`
```dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'firestore_service.dart';

class LocationService {
  final _firestoreService = FirestoreService();

  Future<void> captureAndSaveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      await _firestoreService.updateLocation(
        city: place.locality ?? '',
        country: place.country ?? '',
        lat: position.latitude,
        lng: position.longitude,
      );
    }
  }
}
```

#### 5d. Call it on app start or after login

In `lib/screens/home_page.dart`, add in `initState`:
```dart
@override
void initState() {
  super.initState();
  LocationService().captureAndSaveLocation(); // non-blocking
}
```

---

### STEP 6 — Create a `UserProfileModel`

**New file:** `lib/models/user_profile_model.dart`

```dart
class UserProfileModel {
  final String username;
  final int age;
  final List<String> allergies;
  final List<String> medicalHistory;
  final String city;
  final String country;

  const UserProfileModel({
    required this.username,
    required this.age,
    required this.allergies,
    required this.medicalHistory,
    required this.city,
    required this.country,
  });

  factory UserProfileModel.fromFirestore(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>? ?? {};
    return UserProfileModel(
      username: data['username'] ?? '',
      age: data['age'] ?? 0,
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalHistory: List<String>.from(data['medical_history'] ?? []),
      city: location['city'] ?? '',
      country: location['country'] ?? '',
    );
  }
}
```

---

### STEP 7 — Feed User Profile to AI (GeminiService)

This is the key step — when the AI identifies a medicine or starts a chat, it reads the user's Firestore profile first and includes it in the prompt.

**File:** `lib/services/gemini_service.dart`

```dart
Future<MedicineModel> identifyMedicine(String ocrText) async {
  // 1. Fetch user profile from Firestore
  final profileData = await FirestoreService().getUserProfileOnce();
  final profile = profileData != null
      ? UserProfileModel.fromFirestore(profileData)
      : null;

  // 2. Build personalized prompt
  final userContext = profile != null ? """
User Health Profile:
- Age: ${profile.age}
- Known allergies: ${profile.allergies.isEmpty ? 'None' : profile.allergies.join(', ')}
- Medical history: ${profile.medicalHistory.isEmpty ? 'None' : profile.medicalHistory.join(', ')}
- Location: ${profile.city}, ${profile.country}

Given this user's profile, flag any WARNINGS if this medicine interacts with their allergies or conditions.
""" : "";

  final prompt = """
You are a pharmaceutical assistant AI. $userContext

Given the following OCR-extracted text from a medicine label, identify the medicine and return ONLY this JSON:

{
  "name": "...",
  "shortDescription": "...",
  "function": "...",
  "dosage": "...",
  "sideEffects": ["...", "..."],
  "recipients": ["...", "..."],
  "contraindications": ["...", "..."],
  "allergies": ["...", "..."],
  "personalizedWarning": "..."   // empty string if no risk for this user
}

OCR Text:
\"\"\"
$ocrText
\"\"\"
""";

  final response = await _model.generateContent([Content.text(prompt)]);
  // parse JSON → MedicineModel
}
```

**Update `startChatSession` to include user profile:**

```dart
void startChatSession(MedicineModel? medicine, UserProfileModel? profile) {
  final profileContext = profile != null ? """
You also know the following about this user:
- Age: ${profile.age}
- Allergies: ${profile.allergies.isEmpty ? 'None' : profile.allergies.join(', ')}
- Medical history: ${profile.medicalHistory.isEmpty ? 'None' : profile.medicalHistory.join(', ')}
- Location: ${profile.city}, ${profile.country}

Always warn the user if their question involves something that conflicts with their known allergies or medical history.
""" : "";
  
  // Add to system history...
}
```

---

### STEP 8 — Update `MedicineInfoPage` to Show Personalized Warning

Add a new UI section to `medicine_information_page.dart` that shows a red alert banner if the AI returned a `personalizedWarning`:

```dart
// In MedicineModel, add:
final String personalizedWarning; // e.g. "⚠️ You are allergic to Penicillin, which is an ingredient of this medicine."

// In MedicineInfoPage, add this widget between function and side effects:
if (medicine.personalizedWarning.isNotEmpty)
  Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            medicine.personalizedWarning,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  ),
```

---

## ✅ Summary of All Changes

| # | File | Change |
|---|---|---|
| 1 | `optional_info_page.dart` | Fix field name: `medicalHistory` → `medical_history` |
| 2 | `auth_service.dart` | Initialize `age`, `allergies`, `medical_history`, `location` on register |
| 3 | `firestore_service.dart` | Add `updateAge()`, `updateLocation()`, `getUserProfileOnce()` |
| 4 | `settings_page.dart` | Load profile from Firestore on init; sync edits back to Firestore |
| 5 | `pubspec.yaml` | Add `geolocator`, `geocoding` |
| 6 | `lib/services/location_service.dart` | **NEW** — GPS capture + reverse geocoding + Firestore save |
| 7 | `lib/models/user_profile_model.dart` | **NEW** — typed model for user profile |
| 8 | `lib/services/gemini_service.dart` | Fetch user profile before every AI call; include in prompt |
| 9 | `lib/screens/medicine_information_page.dart` | Show personalized allergy/condition warning banner |
| 10 | `lib/screens/home_page.dart` | Call `LocationService().captureAndSaveLocation()` on init |

---

## ⚠️ Important Notes

- **Never send raw Firestore data to Gemini** — always map it through `UserProfileModel` first so you control what is shared.
- **Location is optional** — if the user denies GPS permission, the AI still works without location context. Never crash or block on it.
- **Field name `medical_history`** (snake_case) is the standard. After Step 1, any old `medicalHistory` documents in Firestore from existing users will need a one-time migration or just treated as empty.
- **Gemini API costs** — every scan call now includes more tokens (user profile). Keep prompt concise.
