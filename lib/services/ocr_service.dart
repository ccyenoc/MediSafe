import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  late final TextRecognizer _textRecognizer;
  
  OcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Extracts text from an image file using Google ML Kit
  /// Returns the extracted text, cleaned of extra whitespace
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Combine all text blocks
      final extractedText = recognizedText.text;

      // Clean up the text
      final cleanedText = _cleanText(extractedText);

      return cleanedText;
    } catch (e) {
      throw Exception('OCR processing failed: ${e.toString()}');
    }
  }

  /// Cleans and normalizes extracted text
  String _cleanText(String text) {
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove special characters that are unlikely in medicine names
    text = text.replaceAll(RegExp(r'[^\w\s\-.]'), ' ');
    
    // Normalize spaces again after removing special chars
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }

  /// Extracts individual words/potential medicine names from text
  /// Filters by minimum length to avoid meaningless tokens
  List<String> extractWords(String text, {int minLength = 3}) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= minLength)
        .toList();
    return words;
  }

  /// Disposes of the text recognizer to free resources
  void dispose() {
    _textRecognizer.close();
  }
}
