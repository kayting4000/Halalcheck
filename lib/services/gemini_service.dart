import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/halal_location.dart';

class GeminiService {
  static const _apiKey = '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';
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static Future<AnalysisResult> analyzeIngredients(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    const prompt = '''Analyze the provided image of an ingredient list.
1. Identify all ingredients visible in the image.
2. Determine if the product is Halal, Haram, or Doubtful based on Islamic dietary laws.
3. Provide a brief "Purity Report" summarizing your findings.

Return ONLY a valid JSON object with this exact structure (no markdown, no extra text):
{
  "status": "halal",
  "reason": "Overall summary reasoning",
  "ingredients": [
    { "name": "Ingredient Name", "status": "halal" }
  ],
  "purityReport": "Detailed explanation of the analysis"
}

Status values must be exactly: "halal", "haram", or "doubtful"''';

    return _callGroqVision(prompt, base64Image);
  }

  static Future<AnalysisResult> analyzeProductVisual(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    const prompt = '''Analyze this image of a food product or food item.
1. Identify what the product or food is by its appearance, packaging, logo, or label.
2. List any visible ingredients or known ingredients for this type of product/food.
3. Determine if it is Halal, Haram, or Doubtful based on Islamic dietary laws.
4. Provide a "Purity Report" based on what you can see and known composition.

Return ONLY a valid JSON object with this exact structure (no markdown, no extra text):
{
  "status": "halal",
  "reason": "Overall summary reasoning including product identification",
  "ingredients": [
    { "name": "Ingredient Name", "status": "halal" }
  ],
  "purityReport": "Detailed explanation including what product was identified and why it is halal/haram/doubtful"
}

Status values must be exactly: "halal", "haram", or "doubtful"''';

    return _callGroqVision(prompt, base64Image);
  }

  static Future<AnalysisResult> analyzeBarcodeProduct(String barcode) async {
    final prompt = '''A product with barcode "$barcode" was scanned.
1. Identify the product associated with this barcode if known.
2. List its typical or known ingredients.
3. Determine if it is Halal, Haram, or Doubtful based on Islamic dietary laws.
4. Provide a "Purity Report" summarizing your findings.

Return ONLY a valid JSON object with this exact structure (no markdown, no extra text):
{
  "status": "halal",
  "reason": "Overall summary reasoning including product name if identified",
  "ingredients": [
    { "name": "Ingredient Name", "status": "halal" }
  ],
  "purityReport": "Detailed explanation of the product and its halal status"
}

Status values must be exactly: "halal", "haram", or "doubtful"''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    return _parseResponse(response.body);
  }

  static Future<AnalysisResult> _callGroqVision(String prompt, String base64Image) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    return _parseResponse(response.body);
  }

  static AnalysisResult _parseResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    String content = data['choices'][0]['message']['content'] as String;
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      return AnalysisResult.fromJsonString(content);
    } catch (e) {
      throw Exception('Failed to parse Groq response: $e\nResponse: $content');
    }
  }
}
