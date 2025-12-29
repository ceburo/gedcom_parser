import 'package:gedcom_parser/src/utils/gedcom_calendar_converter.dart';

/// Utility for parsing GEDCOM date strings into [DateTime] objects.
class GedcomDateParser {
  /// Parses a GEDCOM date string.
  ///
  /// Supports Gregorian, Julian, and French Republican calendars.
  /// Returns null if the date cannot be parsed.
  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }

    try {
      final calendar = GedcomCalendarConverter.detectCalendar(dateStr);
      var datePart = dateStr.toUpperCase();

      // Remove calendar tags
      datePart = datePart
          .replaceAll('@#DFRENCH R@', '')
          .replaceAll('@#DJULIAN@', '')
          .replaceAll('@#DGREGORIAN@', '')
          .trim();

      // Remove common GEDCOM date prefixes
      datePart = datePart
          .replaceAll(RegExp(r'^(ABT|EST|CAL|BEF|AFT|FROM|TO|BET)\s+'), '')
          .trim();

      // Handle BET ... AND ... or FROM ... TO ... by taking the first part
      if (datePart.contains(' AND ')) {
        datePart = datePart.split(' AND ')[0].trim();
      }
      if (datePart.contains(' TO ')) {
        datePart = datePart.split(' TO ')[0].trim();
      }

      if (calendar == GedcomCalendar.republican) {
        final parts = datePart.split(' ');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final year = int.tryParse(parts[2]);
          if (day != null && year != null) {
            return GedcomCalendarConverter.republicanToGregorian(
              day,
              parts[1],
              year,
            );
          }
        }
        return null;
      }

      final parts = datePart.split(" ");
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final monthStr = parts[1];
        final year = int.tryParse(parts[2]);

        if (day != null && year != null) {
          final months = {
            "JAN": 1,
            "FEB": 2,
            "MAR": 3,
            "APR": 4,
            "MAY": 5,
            "JUN": 6,
            "JUL": 7,
            "AUG": 8,
            "SEP": 9,
            "OCT": 10,
            "NOV": 11,
            "DEC": 12,
          };

          final month = months[monthStr];
          if (month != null) {
            if (calendar == GedcomCalendar.julian) {
              return GedcomCalendarConverter.julianToGregorian(
                  day, month, year);
            }
            return DateTime(year, month, day);
          }
        }
      }

      // Fallback: try to find at least a year (4 digits)
      final yearMatch = RegExp(r'\b(\d{4})\b').firstMatch(datePart);
      if (yearMatch != null) {
        final year = int.parse(yearMatch.group(1)!);

        // Try to find a month
        final months = {
          "JAN": 1,
          "FEB": 2,
          "MAR": 3,
          "APR": 4,
          "MAY": 5,
          "JUN": 6,
          "JUL": 7,
          "AUG": 8,
          "SEP": 9,
          "OCT": 10,
          "NOV": 11,
          "DEC": 12,
        };

        var month = 1;
        for (final entry in months.entries) {
          if (datePart.contains(entry.key)) {
            month = entry.value;
            break;
          }
        }

        // Try to find a day
        var day = 1;
        final dayMatch = RegExp(r'\b(\d{1,2})\b')
            .allMatches(datePart)
            .where((m) => m.group(1) != yearMatch.group(1))
            .firstOrNull;
        if (dayMatch != null) {
          day = int.parse(dayMatch.group(1)!);
        }

        if (calendar == GedcomCalendar.julian) {
          return GedcomCalendarConverter.julianToGregorian(day, month, year);
        }
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return null;
  }
}
