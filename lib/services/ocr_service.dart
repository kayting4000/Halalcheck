import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (OCR) using Google ML Kit.
///
/// This runs entirely on the device — **no API key, no network, no free-tier
/// limits**. It replaces the cloud vision-LLM used to read ingredient labels.
class OcrService {
  const OcrService._();

  /// Recognizes text from an image file path and returns the raw recognized
  /// text (used as input for [HalalEngine]).
  ///
  /// Throws a descriptive [Exception] if no text could be read, so the UI can
  /// prompt the user to retake a clearer photo.
  static Future<String> readText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized =
          await recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      if (text.isEmpty) {
        throw Exception(
            'No text detected. Please align the ingredient label clearly and '
            'ensure good lighting, then try again.');
      }
      return text;
    } finally {
      await recognizer.close();
    }
  }
}
