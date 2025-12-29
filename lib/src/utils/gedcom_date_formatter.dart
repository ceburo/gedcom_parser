import 'package:gedcom_parser/src/utils/gedcom_calendar_converter.dart';
import 'package:intl/intl.dart';

/// Utility for formatting GEDCOM date strings into localized human-readable strings.
class GedcomDateFormatter {
  static final _months = <String, int>{
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };

  /// Formats a GEDCOM date string (e.g., "12 JAN 1900", "JAN 1900", "1900")
  /// into a localized string (e.g., "12 janvier 1900").
  /// Returns the original string if it cannot be parsed.
  static String format(String? gedcomDate, String locale) {
    if (gedcomDate == null || gedcomDate.isEmpty) {
      return '';
    }

    // Handle prefixes like ABT, BEF, AFT
    var prefix = '';
    var datePart = gedcomDate;
    final isFr = locale.startsWith('fr');

    if (gedcomDate.startsWith('ABT ')) {
      prefix = isFr ? 'v. ' : 'abt ';
      datePart = gedcomDate.substring(4);
    } else if (gedcomDate.startsWith('BEF ')) {
      prefix = isFr ? 'av. ' : 'bef ';
      datePart = gedcomDate.substring(4);
    } else if (gedcomDate.startsWith('AFT ')) {
      prefix = isFr ? 'ap. ' : 'aft ';
      datePart = gedcomDate.substring(4);
    }

    // Handle Calendars
    final calendar = GedcomCalendarConverter.detectCalendar(datePart);
    if (calendar == GedcomCalendar.republican) {
      return '$prefix${GedcomCalendarConverter.formatRepublican(datePart, locale)}';
    }

    if (calendar == GedcomCalendar.julian) {
      datePart = datePart.replaceAll('@#DJULIAN@', '').trim();
      prefix += isFr ? '(Julien) ' : '(Julian) ';
    } else if (calendar == GedcomCalendar.gregorian) {
      datePart = datePart.replaceAll('@#DGREGORIAN@', '').trim();
    }

    final parts = datePart.split(' ');

    try {
      if (parts.length == 3) {
        // DD MMM YYYY
        final day = int.tryParse(parts[0]);
        final month = _months[parts[1].toUpperCase()];
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          final date = DateTime(year, month, day);
          if (calendar == GedcomCalendar.julian) {
            final greg = GedcomCalendarConverter.julianToGregorian(
              day,
              month,
              year,
            );
            if (greg != null) {
              return '$prefix${DateFormat.yMMMMd(locale).format(date)} (${DateFormat.yMMMMd(locale).format(greg)})';
            }
          }
          return '$prefix${DateFormat.yMMMMd(locale).format(date)}';
        }
      } else if (parts.length == 2) {
        // MMM YYYY
        final month = _months[parts[0].toUpperCase()];
        final year = int.tryParse(parts[1]);

        if (month != null && year != null) {
          final date = DateTime(year, month);
          return '$prefix${DateFormat.yMMMM(locale).format(date)}';
        }
      } else if (parts.length == 1) {
        // YYYY
        final year = int.tryParse(parts[0]);
        if (year != null) {
          return '$prefix$year';
        }
      }
    } catch (e) {
      // Fallback to original if parsing fails
    }

    return gedcomDate;
  }
}
