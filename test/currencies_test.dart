import 'package:flutter_test/flutter_test.dart';
import 'package:splitllm/core/constants/currencies.dart';

void main() {
  group('Currencies catalogue', () {
    test('defaultCode is a real entry in the list', () {
      expect(Currencies.all.any((c) => c.code == Currencies.defaultCode), isTrue);
    });

    test('codes are unique', () {
      final codes = Currencies.all.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('every entry has a 3-letter code and non-empty symbol/name', () {
      for (final c in Currencies.all) {
        expect(c.code, matches(RegExp(r'^[A-Z]{3}$')), reason: 'bad code: ${c.code}');
        expect(c.symbol.trim(), isNotEmpty, reason: 'empty symbol for ${c.code}');
        expect(c.name.trim(), isNotEmpty, reason: 'empty name for ${c.code}');
      }
    });

    test('stays in sync with the backend SUPPORTED_CURRENCIES set', () {
      // Mirror of app/services/fx_service.py SUPPORTED_CURRENCIES. If this
      // fails, the Flutter and backend currency lists have drifted — update
      // both together (see the note atop currencies.dart).
      const expected = {
        'INR', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'AED', 'SGD', 'AUD', 'CAD',
        'CHF', 'THB', 'MYR', 'LKR', 'NPR', 'BDT', 'IDR', 'VND', 'KRW', 'SAR',
        'QAR', 'KWD', 'NZD', 'ZAR', 'HKD', 'TWD', 'PHP', 'EGP', 'TRY', 'BRL',
        'MXN',
      };
      expect(Currencies.all.map((c) => c.code).toSet(), expected);
    });
  });

  group('Currencies.byCode', () {
    test('resolves an exact code', () {
      expect(Currencies.byCode('USD').name, 'US Dollar');
    });

    test('normalises case and surrounding whitespace', () {
      expect(Currencies.byCode('  usd ').code, 'USD');
    });

    test('falls back to the first entry (INR) for unknown/null/empty input', () {
      expect(Currencies.byCode('ZZZ').code, Currencies.defaultCode);
      expect(Currencies.byCode(null).code, Currencies.defaultCode);
      expect(Currencies.byCode('').code, Currencies.defaultCode);
    });
  });

  group('Currencies.symbolFor', () {
    test('returns the matching symbol', () {
      expect(Currencies.symbolFor('INR'), '₹');
      expect(Currencies.symbolFor('gbp'), '£');
    });

    test('falls back to the default currency symbol for unknown codes', () {
      expect(Currencies.symbolFor('ZZZ'), Currencies.byCode(null).symbol);
    });
  });
}
