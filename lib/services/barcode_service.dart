import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/halal_location.dart';
import 'halal_engine.dart';

/// Barcode lookup via the [Open Food Facts] public API.
///
/// Free to use, **no API key required**, ~2.9M+ products worldwide. Once the
/// product is found we read its ingredient text and pass it to the offline
/// [HalalEngine] for the halal verdict.
///
/// [Open Food Facts]: https://world.openfoodfacts.org
class BarcodeService {
  const BarcodeService._();

  /// Public User-Agent, as recommended by Open Food Facts so requests are not
  /// blocked. Replace the contact URL with your own if you have one.
  static const _userAgent =
      'HalalScanner/1.0.0 (https://github.com/kayting4000/Halalcheck)';

  /// Fetches a product by [barcode] and returns an [AnalysisResult].
  ///
  /// Throws a descriptive [Exception] when the product is not found or has no
  /// ingredient data, so the UI can guide the user to scan the label instead.
  static Future<AnalysisResult> lookupBarcode(String barcode) async {
    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$barcode', {
      'fields': 'product_name,generic_name,ingredients_text,brands',
    });

    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Could not reach the product database (HTTP ${response.statusCode}). '
          'Please try again or scan the ingredient label.');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    // status: 1 => product found, 0 => not found.
    if (data['status'] != 1 || data['product'] == null) {
      throw Exception(
          'Product not found in the open database. Please scan the ingredient '
          'label instead for an offline analysis.');
    }

    final product = data['product'] as Map<String, dynamic>;
    final name = (product['product_name'] as String?)?.trim() ?? '';
    final ingredients = (product['ingredients_text'] as String?)?.trim() ?? '';

    if (ingredients.isEmpty) {
      throw Exception(
          'Product "${name.isEmpty ? barcode : name}" was found but has no '
          'ingredient list in the database. Please scan the label instead.');
    }

    return HalalEngine.analyze(ingredients, productName: name);
  }
}
