import 'package:flutter_test/flutter_test.dart';
import 'package:halal_scanner/services/halal_engine.dart';

void main() {
  group('HalalEngine', () {
    test('flags obvious haram ingredients (pork)', () {
      final r = HalalEngine.analyze('Water, Sugar, Pork Gelatin, Flavour');
      expect(r.status, 'haram');
      expect(r.ingredients.any((i) => i.status == 'haram'), isTrue);
    });

    test('flags alcohol as haram', () {
      final r = HalalEngine.analyze('Ethanol, Water, Natural Flavour');
      expect(r.status, 'haram');
    });

    test('flags carmine / E120 as haram', () {
      final r = HalalEngine.analyze('Sugar, E 120, Citric Acid');
      expect(r.status, 'haram');
    });

    test('marks gelatin-only product as doubtful (mashbooh)', () {
      final r = HalalEngine.analyze('Water, Gelatin, Sugar');
      expect(r.status, 'doubtful');
      expect(
        r.ingredients.firstWhere((i) => i.name == 'gelatin').status,
        'doubtful',
      );
    });

    test('marks a common halal product as halal', () {
      final r = HalalEngine.analyze(
        'Sugar, Wheat Flour, Cocoa Butter, Soy Lecithin, Salt',
      );
      expect(r.status, 'halal');
      expect(r.ingredients.every((i) => i.status == 'halal'), isTrue);
    });

    test('unknown ingredients are doubtful (safe default)', () {
      final r = HalalEngine.analyze('Zorbaxine, Unobtainide');
      expect(r.status, 'doubtful');
    });

    test('normalizes E-numbers with a space (E 471)', () {
      final r = HalalEngine.analyze('Palm Oil, E 471, Salt');
      expect(r.status, 'doubtful');
    });

    test('overall status is the worst of the ingredients', () {
      // Halal + doubtful => doubtful
      final r1 = HalalEngine.analyze('Sugar, Whey');
      expect(r1.status, 'doubtful');
      // Halal + haram => haram
      final r2 = HalalEngine.analyze('Sugar, Lard');
      expect(r2.status, 'haram');
    });

    test('includes product name in the purity report when provided', () {
      final r = HalalEngine.analyze('Sugar, Cocoa', productName: 'Test Bar');
      expect(r.purityReport, contains('Test Bar'));
    });

    test('throws on empty input', () {
      expect(() => HalalEngine.analyze('   '), throwsA(isA<Exception>()));
    });
  });
}
