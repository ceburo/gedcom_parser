import 'package:gedcom_parser/src/utils/gedcom_date_parser.dart';
import 'package:test/test.dart';

void main() {
  group('GedcomDateParser', () {
    test('should parse full date', () {
      final date = GedcomDateParser.parse('12 JAN 1900');
      expect(date, DateTime(1900, 1, 12));
    });

    test('should parse year only', () {
      final date = GedcomDateParser.parse('1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse month and year', () {
      final date = GedcomDateParser.parse('JAN 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with ABT prefix', () {
      final date = GedcomDateParser.parse('ABT 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with BEF prefix', () {
      final date = GedcomDateParser.parse('BEF 12 JAN 1900');
      expect(date, DateTime(1900, 1, 12));
    });

    test('should parse date with AFT prefix', () {
      final date = GedcomDateParser.parse('AFT 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with CAL prefix', () {
      final date = GedcomDateParser.parse('CAL 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with EST prefix', () {
      final date = GedcomDateParser.parse('EST 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with ABT prefix and month/year', () {
      final date = GedcomDateParser.parse('ABT JAN 1900');
      expect(date, DateTime(1900, 1, 1));
    });

    test('should parse date with ABT prefix and full date', () {
      final date = GedcomDateParser.parse('ABT 12 JAN 1900');
      expect(date, DateTime(1900, 1, 12));
    });

    test('should parse date with BET AND prefix', () {
      final date = GedcomDateParser.parse('BET 1800 AND 1810');
      expect(date, DateTime(1800, 1, 1));
    });

    test('should parse date with FROM TO prefix', () {
      final date = GedcomDateParser.parse('FROM 1800 TO 1810');
      expect(date, DateTime(1800, 1, 1));
    });

    test('should parse Republican date', () {
      // 1 Vendémiaire An I = 22 Sept 1792
      final date = GedcomDateParser.parse('@#DFRENCH R@ 1 VEND 1');
      expect(date, DateTime(1792, 9, 22));
    });

    test('should return null for invalid date', () {
      expect(GedcomDateParser.parse('INVALID'), null);
      expect(GedcomDateParser.parse(null), null);
      expect(GedcomDateParser.parse(''), null);
    });
  });
}
