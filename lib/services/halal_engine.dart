import '../models/halal_location.dart';

/// Offline, deterministic halal analysis engine.
///
/// This replaces the previous cloud vision-LLM (Groq/Gemini) approach so that
/// scanning works with **no API keys**, **no free-tier limits**, and even
/// **offline**. The verdict is produced purely from a curated, editable rules
/// database of haram / doubtful / halal markers.
///
/// NOTE: This is guidance based on common Islamic dietary rules, not a formal
/// religious ruling. Ambiguous ("doubtful") items should be verified with a
/// qualified halal authority.
class HalalEngine {
  const HalalEngine._();

  // ------------------------------------------------------------------ rules --

  /// A group of related keywords that share the same ruling.
  static const List<_Rule> _rules = [
    // ---- HARAM (prohibited) -----------------------------------------------
    _Rule(_Status.haram, 'Contains pork / pig-derived ingredient', [
      'pork', 'lard', 'swine', 'porcine', 'bacon', 'boar',
      'pork fat', 'pork gelatin', 'pork gelatine',
    ]),
    _Rule(_Status.haram, 'Contains alcohol / intoxicant', [
      'alcohol', 'ethanol', 'ethyl alcohol', 'wine', 'rum', 'beer', 'liquor',
      'spirits', 'whisky', 'whiskey', 'vodka', 'brandy', 'liqueur', 'ale',
      'stout', 'sake', 'marsala', 'mirin', 'cooking wine', 'wine vinegar',
    ]),
    _Rule(_Status.haram, 'Contains blood / blood-derived ingredient', [
      'blood', 'blood plasma', 'hemoglobin', 'blood meal',
    ]),
    _Rule(_Status.haram, 'Contains carmine / cochineal (insect-derived, E120)', [
      'carmine', 'cochineal', 'carminic acid', 'natural red 4', 'e120',
    ]),

    // ---- DOUBTFUL (mashbooh - needs verification) -------------------------
    _Rule(_Status.doubtful, 'Gelatin - source (halal/non-halal) must be verified', [
      'gelatin', 'gelatine',
    ]),
    _Rule(_Status.doubtful, 'Emulsifier may be animal or plant derived', [
      'mono and diglycerides', 'mono- and diglycerides', 'monoglycerides',
      'diglycerides', 'e471', 'e472', 'e473', 'e474', 'e475', 'e476', 'e477',
      'e478', 'polysorbate',
    ]),
    _Rule(_Status.doubtful, 'Enzyme/rennet may be animal derived', [
      'rennet', 'pepsin', 'lipase', 'enzyme', 'enzymes', 'cheese',
    ]),
    _Rule(_Status.doubtful, 'Amino acid may be derived from animal/human sources', [
      'l-cysteine', 'cysteine', 'e920',
    ]),
    _Rule(_Status.doubtful, 'Dairy enzyme/rennet status must be verified', [
      'whey', 'casein', 'caseinate',
    ]),
    _Rule(_Status.doubtful, 'Flavouring carrier may contain alcohol', [
      'natural flavor', 'natural flavoring', 'natural flavour',
      'natural flavouring', 'artificial flavor', 'vanilla extract',
    ]),
    _Rule(_Status.doubtful, 'Glycerin source (plant/animal/synthetic) must be verified', [
      'glycerin', 'glycerine', 'glycerol', 'e422',
    ]),
    _Rule(_Status.doubtful, 'Animal fat / shortening - source must be verified', [
      'shortening', 'tallow', 'suet', 'animal fat', 'stearic acid',
      'magnesium stearate', 'e570',
    ]),
    _Rule(_Status.doubtful, 'Flavour enhancer may be animal or plant derived', [
      'e631', 'e627', 'e635', 'disodium',
    ]),
    _Rule(_Status.doubtful, 'Lac / insect-derived glaze', [
      'shellac', 'e904', 'confectioner glaze', 'resinous glaze',
    ]),
    _Rule(_Status.doubtful, 'Bone phosphate - animal derived', [
      'e542', 'bone phosphate', 'edible bone',
    ]),
    _Rule(_Status.doubtful, 'Generic additive - source must be verified', [
      'emulsifier', 'emulsifiers', 'stabiliser', 'stabilizer', 'colour',
    ]),

    // ---- HALAL (permissible) ---------------------------------------------
    _Rule(_Status.halal, 'Common halal ingredient', [
      'sugar', 'brown sugar', 'cane sugar', 'glucose', 'fructose', 'dextrose',
      'sucrose', 'maltose', 'lactose', 'water', 'salt', 'sea salt',
      'wheat flour', 'flour', 'wheat', 'rice', 'corn', 'maize', 'starch',
      'potato starch', 'tapioca', 'cornstarch', 'milk', 'butter', 'cream',
      'vegetable oil', 'palm oil', 'sunflower oil', 'olive oil', 'rapeseed oil',
      'canola oil', 'coconut oil', 'soybean oil', 'cocoa', 'cocoa butter',
      'cocoa mass', 'cocoa powder', 'chocolate', 'soy lecithin', 'lecithin',
      'citric acid', 'ascorbic acid', 'yeast', 'baking powder', 'baking soda',
      'sodium bicarbonate', 'honey', 'dates', 'vanilla', 'tomato', 'onion',
      'garlic', 'ginger', 'spice', 'spices', 'pepper', 'turmeric', 'cumin',
      'cinnamon', 'pectin', 'agar', 'carrageenan', 'xanthan gum', 'guar gum',
      'e100', 'e101', 'e160a', 'e300', 'e306', 'e307', 'e322', 'e330', 'e170',
      'vitamin c', 'beta carotene', 'beta-carotene', 'curcumin', 'riboflavin',
    ]),
  ];

  static late final List<_CompiledRule> _compiled = _rules.map((r) {
    return _CompiledRule(r.status, r.reason, [
      for (final kw in r.keywords) _pattern(kw),
    ]);
  }).toList();

  static RegExp _pattern(String keyword) {
    // Word-boundary match, case-insensitive; spaces become flexible \s+ so
    // multi-word phrases still match after whitespace normalization.
    final escaped = RegExp.escape(keyword).replaceAll(' ', r'\s+');
    return RegExp(r'\b' + escaped + r'\b', caseSensitive: false);
  }

  // --------------------------------------------------------------- analyze --

  /// Analyze an ingredient string (from OCR text or a product database) and
  /// return a structured [AnalysisResult] compatible with the existing UI.
  static AnalysisResult analyze(String input, {String? productName}) {
    final text = _normalize(input);
    if (text.isEmpty) {
      throw Exception('No ingredient text was found to analyze.');
    }

    final tokens = <_Ingredient>[];
    for (final raw in text.split(RegExp(r'[,;\n.]'))) {
      var name = raw.trim();
      if (name.isEmpty) continue;
      name = name.replaceFirst(RegExp(r'^[\*\u2022\d\.\s]+'), '').trim();
      name = name.replaceAll(RegExp(r'\d{1,3}\s?%'), '').trim();
      name = name.replaceAll(RegExp(r'[\.\*]+$'), '').trim();
      if (name.length < 2) continue;
      final verdict = _classify(name);
      tokens.add(_Ingredient(name, verdict.status, verdict.reason));
    }

    if (tokens.isEmpty) {
      throw Exception('Could not detect any readable ingredients.');
    }

    final hasHaram = tokens.any((t) => t.status == _Status.haram);
    final hasDoubtful = tokens.any((t) => t.status == _Status.doubtful);
    final hasHalal = tokens.any((t) => t.status == _Status.halal);

    String overall;
    String reason;
    if (hasHaram) {
      overall = 'haram';
      reason = 'Contains one or more ingredients that are not permissible (haram).';
    } else if (hasDoubtful) {
      overall = 'doubtful';
      reason = 'Contains ingredients that require verification (doubtful / mashbooh).';
    } else if (hasHalal) {
      overall = 'halal';
      reason = 'No haram or doubtful ingredients detected in the local database.';
    } else {
      overall = 'doubtful';
      reason = 'Ingredients could not be matched to the local database.';
    }

    final haramItems = tokens
        .where((t) => t.status == _Status.haram)
        .map((t) => '${t.name} - ${t.reason}')
        .toList();
    final doubtfulItems = tokens
        .where((t) => t.status == _Status.doubtful)
        .map((t) => '${t.name} - ${t.reason}')
        .toList();

    final report = StringBuffer()
      ..writeln('Analyzed ${tokens.length} ingredient(s) on-device (offline, '
          'no external API).');
    if (productName != null && productName.trim().isNotEmpty) {
      report.writeln('Product: ${productName.trim()}');
    }
    if (haramItems.isNotEmpty) {
      report.writeln('\nNot permissible: ${haramItems.join('; ')}.');
    }
    if (doubtfulItems.isNotEmpty) {
      report.writeln('\nNeeds verification: ${doubtfulItems.join('; ')}.');
    }
    if (haramItems.isEmpty && doubtfulItems.isEmpty) {
      report.writeln('\nAll detected ingredients are known halal.');
    }
    report.writeln('\nThis is an offline rules-based estimate, not a religious '
        'ruling. For ambiguous items, consult a qualified halal authority.');

    return AnalysisResult(
      status: overall,
      reason: reason,
      ingredients: [
        for (final t in tokens)
          IngredientResult(name: t.name, status: _statusToString(t.status)),
      ],
      purityReport: report.toString().trim(),
    );
  }

  // -------------------------------------------------------------- helpers --

  static String _normalize(String input) {
    var s = input.toLowerCase();
    // Normalize E-numbers: "E 471" / "e-471" -> "e471"
    s = s.replaceAllMapped(
      RegExp(r'\be[\s\-]?(\d{3}[a-z]?)\b'),
      (m) => 'e${m[1]}',
    );
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static _Verdict _classify(String token) {
    for (final rule in _compiled) {
      for (final p in rule.patterns) {
        if (p.hasMatch(token)) {
          return _Verdict(rule.status, rule.reason);
        }
      }
    }
    return _Verdict(
      _Status.doubtful,
      'Not in local database - please verify manually',
    );
  }

  static String _statusToString(_Status s) {
    switch (s) {
      case _Status.halal:
        return 'halal';
      case _Status.haram:
        return 'haram';
      case _Status.doubtful:
        return 'doubtful';
    }
  }
}

// ------------------------------------------------------------- data types --

enum _Status { halal, haram, doubtful }

class _Rule {
  final _Status status;
  final String reason;
  final List<String> keywords;
  const _Rule(this.status, this.reason, this.keywords);
}

class _CompiledRule {
  final _Status status;
  final String reason;
  final List<RegExp> patterns;
  const _CompiledRule(this.status, this.reason, this.patterns);
}

class _Verdict {
  final _Status status;
  final String reason;
  const _Verdict(this.status, this.reason);
}

class _Ingredient {
  final String name;
  final _Status status;
  final String reason;
  const _Ingredient(this.name, this.status, this.reason);
}
