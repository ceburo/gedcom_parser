import 'package:gedcom_parser/src/utils/gedcom_date_formatter.dart';
import 'package:test/test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
    await initializeDateFormatting('en', null);
  });

  group('GedcomDateFormatter', () {
    test('should format full date in French', () {
      expect(
        GedcomDateFormatter.format('12 JAN 1900', 'fr'),
        '12 janvier 1900',
      );
    });

    test('should format full date in English', () {
      expect(
        GedcomDateFormatter.format('12 JAN 1900', 'en'),
        'January 12, 1900',
      );
    });

    test('should format month and year in French', () {
      expect(GedcomDateFormatter.format('JAN 1900', 'fr'), 'janvier 1900');
    });

    test('should format year only', () {
      expect(GedcomDateFormatter.format('1900', 'fr'), '1900');
    });

    test('should handle ABT prefix in French', () {
      expect(GedcomDateFormatter.format('ABT 1900', 'fr'), 'v. 1900');
    });

    test('should handle BEF prefix in French', () {
      expect(GedcomDateFormatter.format('BEF 1900', 'fr'), 'av. 1900');
    });

    test('should handle AFT prefix in French', () {
      expect(GedcomDateFormatter.format('AFT 1900', 'fr'), 'ap. 1900');
    });

    test('should handle ABT prefix in English', () {
      expect(GedcomDateFormatter.format('ABT 1900', 'en'), 'abt 1900');
    });

    test('should return empty string for null or invalid date', () {
      expect(GedcomDateFormatter.format(null, 'fr'), '');
      expect(GedcomDateFormatter.format('', 'fr'), '');
      expect(GedcomDateFormatter.format('INVALID', 'fr'), 'INVALID');
    });

    test('should format Republican date in French', () {
      expect(
        GedcomDateFormatter.format('@#DFRENCH R@ 14 VEND 1', 'fr'),
        '14 Vendémiaire An 1 (5 octobre 1792)',
      );
    });

    test('should format Julian date in French', () {
      expect(
        GedcomDateFormatter.format('@#DJULIAN@ 12 JAN 1750', 'fr'),
        '(Julien) 12 janvier 1750 (23 janvier 1750)',
      );
    });
  });
}
