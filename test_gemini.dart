import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medisafe/services/gemini_service.dart';
import 'package:medisafe/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  // This will trigger the backend logic and print the debug logs
  try {
    final service = GeminiService();
    // Simulate catching a cold medicine with decongestant/NSAID
    await service.identifyMedicine("Sudafed PE Sinus Congestion\nActive Ingredient: Phenylephrine HCl");
    print("Done");
  } catch (e) {
    print("Error: $e");
  }
}
