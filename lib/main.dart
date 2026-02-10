import 'package:flutter/material.dart';
import 'screens/landing_page.dart';

void main() {
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
        fontFamily: 'LibreBaskerville', // default font
        primarySwatch: Colors.blue,
      ),
      home: const LandingScreen(), // set landing page here
    );
  }
}

