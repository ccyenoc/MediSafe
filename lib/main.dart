import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/landing_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final NotificationService _notificationService = NotificationService();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications
  await _notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'LibreBaskerville',
        primarySwatch: Colors.blue,

         textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF1E3F8F),            // blinking cursor
      selectionColor: Color(0x331E3F8F),         // selected text highlight
      selectionHandleColor: Color(0xFF1E3F8F),   // draggable handles
      ),
       ),
      home: const LandingScreen(),
    );
  }
}
