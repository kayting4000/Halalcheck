import '../models/halal_location.dart';

/// Offline, deterministic halal analysis engine.
///
/// Works with **no API keys**, **no free-tier limits**, and **offline**.
/// Evaluates ingredient keywords against an extensive Islamic dietary database.
class HalalEngine {
  const HalalEngine._();

  // ------------------------------------------------------------------ rules --

  static const List<_Rule> _rules = [
    // ---- HARAM (prohibited) -----------------------------------------------
    _Rule(_Status.haram, 'Contains pork / pig-derived ingredient', [
      'pork', 'lard', 'swine', 'porcine', 'bacon', 'boar', 'ham', 'prosciutto',
      'pork fat', 'pork gelatin', 'pork gelatine', 'pork belly',
    ]),
    _Rule(_Status.haram, 'Contains alcohol / intoxicant', [
      'alcohol', 'ethanol', 'ethyl alcohol', 'wine', 'rum', 'beer', 'liquor',
      'spirits', 'whisky', 'whiskey', 'vodka', 'brandy', 'liqueur', 'ale',
      'stout', 'sake', 'marsala', 'mirin', 'cooking wine', 'wine vinegar',
      'cognac', 'gin', 'bourbon', 'champagne',
    ]),
    _Rule(_Status.haram, 'Contains blood / blood-derived ingredient', [
      'blood', 'blood plasma', 'hemoglobin', 'blood meal', 'black pudding',
    ]),
    _Rule(_Status.haram, 'Contains carmine / cochineal (insect-derived dye, E120)', [
      'carmine', 'cochineal', 'carminic acid', 'natural red 4', 'e120', 'crimson lake',
    ]),

    // ---- DOUBTFUL (mashbooh - source must be verified) --------------------
    _Rule(_Status.doubtful, 'Gelatin - animal source (halal/bovine vs porcine) must be verified', [
      'gelatin', 'gelatine', 'e441',
    ]),
    _Rule(_Status.doubtful, 'Emulsifier may be animal fat or plant derived', [
      'mono and diglycerides', 'mono- and diglycerides', 'monoglycerides',
      'diglycerides', 'e471', 'e472', 'e472a', 'e472b', 'e472c', 'e472d',
      'e472e', 'e472f', 'e473', 'e474', 'e475', 'e476', 'e477', 'e478',
      'e481', 'e482', 'e483', 'e491', 'e492', 'e493', 'e494', 'e495',
      'polysorbate', 'polysorbate 60', 'polysorbate 65', 'polysorbate 80',
      'e430', 'e431', 'e432', 'e433', 'e434', 'e435', 'e436',
    ]),
    _Rule(_Status.doubtful, 'Enzyme/rennet may be animal derived', [
      'rennet', 'pepsin', 'lipase', 'enzyme', 'enzymes', 'cheese culture',
      'animal rennet',
    ]),
    _Rule(_Status.doubtful, 'Amino acid may be derived from animal or human hair', [
      'l-cysteine', 'cysteine', 'e920', 'l-cystine', 'e921',
    ]),
    _Rule(_Status.doubtful, 'Dairy processing enzyme status must be verified', [
      'whey', 'whey powder', 'casein', 'caseinate', 'sodium caseinate',
    ]),
    _Rule(_Status.doubtful, 'Flavouring carrier may contain alcohol extract', [
      'natural flavor', 'natural flavoring', 'natural flavour',
      'natural flavouring', 'artificial flavor', 'vanilla extract',
    ]),
    _Rule(_Status.doubtful, 'Glycerin source (plant vs animal tallow) must be verified', [
      'glycerin', 'glycerine', 'glycerol', 'e422',
    ]),
    _Rule(_Status.doubtful, 'Animal fat / shortening - slaughter and source must be verified', [
      'shortening', 'tallow', 'suet', 'animal fat', 'stearic acid',
      'magnesium stearate', 'calcium stearate', 'e570', 'e572',
    ]),
    _Rule(_Status.doubtful, 'Flavour enhancer may be animal or plant derived', [
      'e631', 'e627', 'e635', 'disodium inosinate', 'disodium guanylate',
      'disodium 5-ribonucleotides',
    ]),
    _Rule(_Status.doubtful, 'Shellac / insect-derived confectionery glaze', [
      'shellac', 'e904', 'confectioner glaze', 'resinous glaze',
    ]),
    _Rule(_Status.doubtful, 'Bone phosphate - animal bone origin', [
      'e542', 'bone phosphate', 'edible bone',
    ]),
    _Rule(_Status.doubtful, 'Generic additive - source must be verified', [
      'emulsifier', 'emulsifiers', 'stabiliser', 'stabilizer',
    ]),

    // ---- HALAL (permissible) ---------------------------------------------
    _Rule(_Status.halal, 'Common halal / plant-derived ingredient', [
      'sugar', 'brown sugar', 'cane sugar', 'glucose', 'fructose', 'dextrose',
      'sucrose', 'maltose', 'lactose', 'water', 'salt', 'sea salt',
      'wheat flour', 'flour', 'wheat', 'rice', 'corn', 'maize', 'starch',
      'potato starch', 'tapioca', 'cornstarch', 'milk', 'butter', 'cream',
      'vegetable oil', 'palm oil', 'sunflower oil', 'olive oil', 'rapeseed oil',
      'canola oil', 'coconut oil', 'soybean oil', 'sesame oil', 'cocoa',
      'cocoa butter', 'cocoa mass', 'cocoa powder', 'chocolate', 'soy lecithin',
      'lecithin', 'citric acid', 'ascorbic acid', 'yeast', 'baking powder',
      'baking soda', 'sodium bicarbonate', 'honey', 'dates', 'vanilla',
      'tomato', 'onion', 'garlic', 'ginger', 'spice', 'spices', 'pepper',
      'turmeric', 'cumin', 'cinnamon', 'pectin', 'agar', 'agar-agar',
      'carrageenan', 'xanthan gum', 'guar gum', 'locust bean gum', 'gum arabic',
      'e100', 'e101', 'e140', 'e141', 'e150', 'e150a', 'e160a', 'e160c',
      'e162', 'e163', 'e170', 'e200', 'e202', 'e211', 'e260', 'e270', 'e300',
      'e306', 'e307', 'e322', 'e330', 'e407', 'e410', 'e412', 'e415', 'e440',
      'vitamin c', 'beta carotene', 'beta-carotene', 'curcumin', 'riboflavin',
      'oats', 'barley', 'almonds', 'peanuts', 'hazelnuts', 'soy', 'soya',
    ]),
  ];

  static final List<_CompiledRule> _compiled = _rules.map((r) {
    return _CompiledRule(r.status, r.reason, [
      for (final kw in r.keywords) _pattern(kw),
    ]);
  }).toList();

  static RegExp _pattern(String keyword) {
    final escaped = RegExp.escape(keyword).replaceAll(' ', r'\s+');
    return RegExp(r'\b' + escaped + r'\b', caseSensitive: false);
  }

  // --------------------------------------------------------------- analyze --

  /// Analyze an ingredient string and return a structured [AnalysisResult].
  static AnalysisResult analyze(
    String input, {
    String? productName,
    String? brand,
    String? imageUrl,
    bool isCertifiedHalal = false,
  }) {
    final text = _normalize(input);
    if (text.isEmpty && !isCertifiedHalal) {
      throw Exception('No ingredient text was found to analyze.');
    }

    final tokens = <_Ingredient>[];
    if (text.isNotEmpty) {
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
    }

    final hasHaram = tokens.any((t) => t.status == _Status.haram);
    final hasDoubtful = tokens.any((t) => t.status == _Status.doubtful);
    final hasHalal = tokens.any((t) => t.status == _Status.halal);

    String overall;
    String reason;

    if (hasHaram) {
      overall = 'haram';
      reason = 'Contains one or more ingredients that are not permissible (haram).';
    } else if (isCertifiedHalal) {
      overall = 'halal';
      reason = 'Officially certified Halal on product packaging.';
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
      ..writeln('Analyzed ${tokens.length} ingredient(s) on-device.');
    if (productName != null && productName.trim().isNotEmpty) {
      report.writeln('Product: ${productName.trim()}');
    }
    if (brand != null && brand.trim().isNotEmpty) {
      report.writeln('Brand: ${brand.trim()}');
    }
    if (isCertifiedHalal) {
      report.writeln('Certification: Officially Certified Halal');
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

    return AnalysisResult(
      status: overall,
      reason: reason,
      ingredients: [
        for (final t in tokens)
          IngredientResult(name: t.name, status: _statusToString(t.status)),
      ],
      purityReport: report.toString().trim(),
      productName: productName,
      brand: brand,
      imageUrl: imageUrl,
      isCertifiedHalal: isCertifiedHalal,
    );
  }

  // -------------------------------------------------------------- helpers --

  static String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAllMapped(
      RegExp(r'\be[\s\-]?(\d{3,4}[a-z]?)\b'),
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
