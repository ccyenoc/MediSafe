import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR using Google ML Kit — no network call required.
class OcrService {
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText result = await textRecognizer.processImage(inputImage);
      return result.text;
    } finally {
      await textRecognizer.close();
    }
  }
}
