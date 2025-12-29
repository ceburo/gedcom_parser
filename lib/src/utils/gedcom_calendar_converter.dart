import 'package:intl/intl.dart';

/// Supported GEDCOM calendars.
enum GedcomCalendar { gregorian, julian, republican, unknown }

/// Utility for converting between different GEDCOM calendars.
class GedcomCalendarConverter {
  static const republicanMonths = [
    'VEND',
    'BRUM',
    'FRIM',
    'NIVO',
    'PLUV',
    'VENT',
    'GERM',
    'FLOR',
    'PRAI',
    'MESS',
    'THER',
    'FRUC',
    'COMP',
  ];

  static const republicanMonthsFull = [
    'Vendémiaire',
    'Brumaire',
    'Frimaire',
    'Nivôse',
    'Pluviôse',
    'Ventôse',
    'Germinal',
    'Floréal',
    'Prairial',
    'Messidor',
    'Thermidor',
    'Fructidor',
    'Sans-culottides',
  ];

  /// Detects the calendar used in a GEDCOM date string.
  static GedcomCalendar detectCalendar(String date) {
    if (date.contains('@#DFRENCH R@')) {
      return GedcomCalendar.republican;
    }
    if (date.contains('@#DJULIAN@')) {
      return GedcomCalendar.julian;
    }
    if (date.contains('@#DGREGORIAN@')) {
      return GedcomCalendar.gregorian;
    }
    return GedcomCalendar.gregorian; // Default
  }

  /// Converts a Republican date to Gregorian.
  /// Format: "@#DFRENCH R@ DD MONTH YEAR"
  /// Example: "@#DFRENCH R@ 14 VEND 1" -> 1792-10-05
  static DateTime? republicanToGregorian(int day, String month, int year) {
    // The Republican calendar started on Sept 22, 1792.
    // This is a simplified conversion. For a real app, we'd need a more precise algorithm.
    // But for the scope of this task, we can use a known start date and add days.

    final startOfRepublic = DateTime(1792, 9, 22);

    final monthIndex = republicanMonths.indexOf(month.toUpperCase());
    if (monthIndex == -1) {
      return null;
    }

    // Approximate calculation: each month has 30 days.
    var totalDays = (year - 1) * 365;

    // Add leap years (Years 3, 7, 11)
    totalDays += (year > 3 ? 1 : 0);
    totalDays += (year > 7 ? 1 : 0);
    totalDays += (year > 11 ? 1 : 0);

    totalDays += monthIndex * 30;
    totalDays += day - 1;

    return startOfRepublic.add(Duration(days: totalDays));
  }

  /// Converts a Julian date to Gregorian.
  /// Julian is usually 10-13 days behind Gregorian depending on the century.
  static DateTime? julianToGregorian(int day, int month, int year) {
    // Simplified conversion
    var offset = 0;
    if (year >= 1700 && year < 1800) {
      offset = 11;
    } else if (year >= 1800 && year < 1900) {
      offset = 12;
    } else if (year >= 1900 && year < 2100) {
      offset = 13;
    } else if (year < 1700) {
      offset = 10;
    }

    return DateTime(year, month, day).add(Duration(days: offset));
  }

  /// Formats a Republican date for display.
  static String formatRepublican(String date, String locale) {
    final isFr = locale.startsWith('fr');
    final cleanDate = date.replaceAll('@#DFRENCH R@', '').trim();
    final parts = cleanDate.split(' ');

    if (parts.length == 3) {
      final day = parts[0];
      final month = parts[1].toUpperCase();
      final year = parts[2];

      final monthIndex = republicanMonths.indexOf(month);
      if (monthIndex != -1) {
        final monthName = isFr ? republicanMonthsFull[monthIndex] : month;
        final formatted = "$day $monthName An $year";

        // Add Gregorian equivalent in parenthesis
        final greg = republicanToGregorian(
          int.parse(day),
          month,
          int.parse(year),
        );
        if (greg != null) {
          final gregFormatted = DateFormat.yMMMMd(locale).format(greg);
          return "$formatted ($gregFormatted)";
        }
        return formatted;
      }
    }
    return date;
  }
}
