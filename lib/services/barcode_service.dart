import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/halal_location.dart';
import 'halal_engine.dart';

/// Barcode lookup via [Open Food Facts] public API.
///
/// Free, open-source worldwide food database with ~3M+ products.
/// Queries product metadata, checks official halal labels, and analyzes ingredients.
class BarcodeService {
  const BarcodeService._();

  static const _userAgent =
      'HalalScanner/1.0.0 (https://github.com/kayting4000/Halalcheck)';

  /// Fetches a product by [barcode] and returns an [AnalysisResult].
  static Future<AnalysisResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleanBarcode.isEmpty) {
      throw Exception('Please enter a valid barcode number.');
    }

    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$cleanBarcode', {
      'fields':
          'product_name,generic_name,ingredients_text,ingredients_text_en,brands,labels_tags,image_front_url,image_url',
    });

    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Could not reach Open Food Facts server (HTTP ${response.statusCode}). '
          'Please check your internet or scan the ingredient text instead.');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['status'] != 1 || data['product'] == null) {
      throw Exception(
          'Product "$cleanBarcode" was not found in the global open database.\n\n'
          'Tip: Switch to "Ingredients" mode above to scan the text directly from the packaging!');
    }

    final product = data['product'] as Map<String, dynamic>;
    final name = (product['product_name'] as String?)?.trim() ??
        (product['generic_name'] as String?)?.trim() ??
        '';
    final brand = (product['brands'] as String?)?.trim();
    final imageUrl = (product['image_front_url'] as String?) ??
        (product['image_url'] as String?);

    final labels = (product['labels_tags'] as List<dynamic>? ?? [])
        .map((l) => l.toString().toLowerCase())
        .toList();

    final isCertifiedHalal = labels.any((l) =>
        l.contains('halal') ||
        l.contains('islamic') ||
        l.contains('jakim') ||
        l.contains('mui') ||
        l.contains('bpjph'));

    final ingredients = (product['ingredients_text'] as String?)?.trim() ??
        (product['ingredients_text_en'] as String?)?.trim() ??
        '';

    if (ingredients.isEmpty) {
      if (isCertifiedHalal) {
        return AnalysisResult(
          status: 'halal',
          reason: 'Product is officially certified Halal on packaging label.',
          ingredients: [],
          purityReport:
              'Product: ${name.isNotEmpty ? name : cleanBarcode}\nBrand: ${brand ?? "Unknown"}\nCertification: Certified Halal by accredited packaging label.',
          productName: name.isNotEmpty ? name : 'Barcode: $cleanBarcode',
          brand: brand,
          imageUrl: imageUrl,
          isCertifiedHalal: true,
        );
      }
      throw Exception(
          'Product "${name.isEmpty ? cleanBarcode : name}" was found, but has no ingredient '
          'text registered. Please switch to "Ingredients" mode to scan the label.');
    }

    return HalalEngine.analyze(
      ingredients,
      productName: name.isNotEmpty ? name : cleanBarcode,
      brand: brand,
      imageUrl: imageUrl,
      isCertifiedHalal: isCertifiedHalal,
    );
  }
}
