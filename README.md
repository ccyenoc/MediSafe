<!-- App Logo -->
<div align="center">
  <img src="assets/images/logo2.jpg" alt="MediSafe Logo" width="120"/>
</div>

<div align="center">

# MediSafe

**AI-driven medicine understanding, smart scheduling, and personalized health safety.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](#)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=google-gemini&logoColor=white)](#)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](#)

Your intelligent companion for safe medication understanding and daily adherence.

</div>

* * * 

## 🧩 Overview

MediSafe is a mobile AI-powered medication companion designed to **reduce medication misuse** and **improve treatment adherence**.  
By combining on-device OCR with cloud-based AI reasoning, MediSafe helps users understand medicines in simple language, receive personalized safety warnings, and follow correct dosing schedules.

---    

## 🛠 Technical Architecture

MediSafe is built with a privacy-conscious, modular architecture optimized for mobile performance and safety-critical use cases.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio or Android SDK
- Physical Android device (camera required)
- Active internet connection
  
### 1. Clone Repository
```bash
git clone https://github.com/ccyenoc/MediSafe.git
cd MediSafe
```

### 2. Install dependencies:
```bash
flutter pub get
```

### 3. Configure Environment
Create a .env file in the project root:
```bash
GEMINI_API_KEY=your_api_key
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE  
```  
Make sure Firebase is configured:  
google-services.json (Android)  
firebase_options.dart generated via FlutterFire CLI  

### 4. Run Application  
Connect a physical Android device and run:  
```bash  
flutter run  
```

---

### 1. Technology Stack

| Layer | Technology |
|------|-----------|
| **📱 Frontend** | Flutter (Dart) |
| **☁️ Backend / BaaS** | Firebase (Authentication, Firestore Database) |
| **🧠 AI / LLM** | Google Gemini 2.5 Flash (`google_generative_ai`) |
| **🔍 On-device OCR** | Google ML Kit (`google_mlkit_text_recognition`) via custom `OcrService` |
| **🗺️ Maps** | Google Maps SDK (iOS via GoogleMaps pod, Android via `google_maps_flutter`) |
| **⚙️ Environment Management** | `flutter_dotenv` (secure `.env` loading at startup) |
| **📍 Geolocation** | `geolocator` + `geocoding` via `LocationService` |

---  

### 2. Core Architecture Patterns

#### 🔹 Service Layer Pattern
All external integrations are encapsulated into dedicated services to ensure clean separation of concerns:

- **GeminiService** — Handles medicine identification, structured AI responses, and stateful chat sessions
- **OcrService** — Thin wrapper around ML Kit OCR, fully on-device
- **FirestoreService** — Centralized access for user profiles, schedules, scan history, and chat persistence
- **LocationService** — Manages GPS capture, reverse geocoding, and location storage

#### 🔹 Model Layer
- **MedicineModel** — Represents validated AI-parsed medicine data (name, purpose, dosage, warnings, tips)
- **UserProfileModel** — Represents user health context and exposes `toAiContext()` for prompt injection

#### 🔹 State Management
- Flutter native `StatefulWidget` + `setState()`
- Real-time updates using Firestore `StreamBuilder` for schedules, profiles, and chat history

---

## 🚀 Core System Implementations

### 📷 AI Medicine Scan Pipeline
The primary feature of MediSafe follows a **tightly controlled pipeline**:  

**Image Capture**   

→ On-device OCR (ML Kit)  

→ Gemini AI Reasoning (text + image)  

→ Strict JSON Parsing  

→ Safety Validation  

→ UI Rendering  

→ Firestore Persistence

**Safety Controls**
- Low-temperature (0.2) deterministic generation
- Strict JSON schema enforcement
- “Unknown Medicine” sentinel blocking unsafe navigation
- Dual-input validation using both OCR text and raw image

---

### 🤖 AI Chat Agent
MediSafe includes a persistent AI chat assistant that supports:
- General medication questions
- Medicine-specific follow-up discussions

Chat sessions are:
- Initialized with user health context
- Persisted in Firestore
- Shared across full-screen chat and floating assistant UI

The AI is explicitly restricted from diagnosing diseases.

---

### 📅 Smart Scheduling & Notifications
- Gemini analyzes dosage instructions and suggests dosing frequency and duration
- Users can customize reminder times before saving
- Notifications are scheduled locally using `flutter_local_notifications`
- Timezone-aware scheduling ensures accuracy when users travel

---

### 🔐 Authentication & Access Control
- Firebase Authentication (Email/Password + Google Sign-In)
- Mandatory email verification before app access
- Secure per-user Firestore data isolation

---

### 📍 Find Healthcare Nearby & Privacy
**Locate Pharmacies, Clinics, and Hospitals**
Location awareness is a core feature of MediSafe, designed to connect you with essential healthcare services exactly when you need them. We use your location data to help you:
- **Instantly Find Nearby Care**: Quickly route to the closest pharmacies, clinics, and hospitals in your area.
- **Enhance Contextual Awareness**: Improve the accuracy of region-specific health insights and medicine guidance.

---

### 🧯 Error Handling Strategy  
MediSafe implements defensive error handling across all safety-critical flows:

- **Camera permission denied** — Prompts user to enable access via system settings  
- **OCR returns no text** — Displays a clear “unable to read image” dialog  
- **Malformed AI response** — Regex-based JSON recovery with fallback to `"Unknown Medicine"`  
- **Gemini API failure / quota exceeded** — Retryable snackbar with graceful degradation  
- **Low-confidence or unknown medicine** — Navigation blocked to prevent unsafe information  
- **Chat message failure** — Inline error feedback instead of silent failure

---

## 🔒 Security & Configuration

- API keys loaded via environment variables and platform-specific configs
- Firestore Security Rules enforce user-level access:
  allow read, write: if request.auth.uid == userId;
- Gemini safety filters enabled with conservative thresholds
- Platform-specific configuration for Android and iOS

---

## ⚠️ Challenges & Solutions

### 🔍 OCR & AI Misidentification
**Challenge**
- Glare, curved packaging, low lighting, motion blur
- Risk of unsafe AI misidentification

**Solution**
- Camera flash toggle and scanner overlay
- OCR result validation before AI submission
- Cross-validation using image + text
- Blocking navigation on low-confidence results

---

### 🗄️ Firestore Data Privacy
**Challenge**
- NoSQL denormalization
- Sensitive medical and location data

**Solution**
- Modular per-user subcollections
- Strict Firestore rules preventing cross-user access

---

### ✉️ Authentication & Email Verification

Handling authentication securely is critical when dealing with personal health data.

**Challenges**
- Secure user registration and login  
- Preventing duplicate accounts  
- Ensuring email verification before system access  
- Blocking unauthenticated access to medical data  

**Solution**  

- Firebase Authentication was integrated with **Email & Password** support.  
- The system checks for existing emails during registration and enforces an **email verification flow** using `sendEmailVerification()`. Users are restricted from accessing the app until verification is complete, and user profiles are stored securely in Firestore only after successful registration.

---

### 🔔 Reliable Medication Reminders
**Challenge**
- Android Doze Mode
- Cross-platform scheduling inconsistencies

**Solution**
- Exact scheduling using `zonedSchedule`
- High-priority notification channels
- Dynamic permission handling on Android 13+ 

---

## 🗺 Future Roadmap

### 🔬 Advanced Drug Safety
- Drug–drug interaction detection across active medications


### ♿ Accessibility
- Multi-language support
- Large-text UI mode for elderly users
- Voice-guided medication instructions

### 🧠 AI Intelligence
- Confidence scoring for AI-generated outputs
- Offline OCR fallback with limited functionality
- Learning from scan history to improve identification accuracy

### 🏥 Healthcare Integration
- Exportable medication reports (PDF) for doctors or pharmacists
- Pharmacist-verified medicine database integration

### 🔐 Compliance & Privacy
- Enhanced user consent flows
- Preparation for healthcare-grade privacy standards (HIPAA-style)

<br>

## 👥 Development Team

| Name | Contribution |
|------|--------------|
| **Brayden Chong Jie Rui** | Led overall project planning and system architecture. Designed and implemented backend logic using Firebase (Authentication & Firestore), integrated Google Gemini 2.5 Flash for AI reasoning and chat and implemented the OCR-to-AI pipeline using Google ML Kit and handled personalization logic based on user health profiles. 
| **Chin Yiu Ern** | Developed core frontend features using Flutter (Dart), including the Home, Scan Medicine, and Results pages. Focused on user flow design, camera integration, and clear presentation of AI-generated medicine information. Designed and implemented backend logic using Firebase (Authentication & Firestore)|
| **Lim Wan Yee** | Contributed to frontend development with Flutter, assisted in building the Schedule and Chatbot pages, refined UI components, implemented the LocationService with Geolocator, Geocoding, and Google Maps SDK, built the Near Me page for locating nearby pharmacies, clinics, and hospitals, and ensured consistent layout, usability, and responsiveness across the app. |
| **One Yean** | Performed quality assurance and testing across Android devices, validated OCR accuracy, AI responses, and reminder flows, identified edge cases, and provided feedback to improve stability and overall user experience. |

<div align="center">
<b>Built with ❤️ to make medication safer, clearer, and smarter.</b>
</div>

