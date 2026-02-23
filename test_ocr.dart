import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  final folder = Directory('/Users/braydencjr/MediSafe-1/ocr-photos-sample');
  final photos = folder.listSync().whereType<File>().toList();
  
  for (var photo in photos) {
    if (!photo.path.toUpperCase().endsWith('.JPG')) continue;
    print('\n======================================================');
    print('📷 ' + photo.path.split('/').last);
    print('======================================================');
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final result = await recognizer.processImage(inputImage);
      print(result.text.isEmpty ? "(No text found)" : result.text);
    } catch (e) {
      print('ERROR: \$e');
    }
  }
  
  await recognizer.close();
  print('\n=== Done ===');
  exit(0);
}
