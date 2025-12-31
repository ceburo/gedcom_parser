/// Utilities for handling GEDCOM strings, including escaping and unescaping.
class GedcomStringUtils {
  /// Unescapes a GEDCOM text value.
  ///
  /// In GEDCOM 7.0, a value starting with '@' is escaped by doubling it ('@@').
  static String? unescapeText(String? value) {
    if (value == null) return null;
    if (value.startsWith('@@')) return value.substring(1);
    return value;
  }

  /// Unescapes a GEDCOM pointer (e.g., '@I1@' -> 'I1').
  static String? unescapePointer(String? value) {
    if (value == null) return null;
    if (value.startsWith('@') && value.endsWith('@')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  /// Escapes a GEDCOM text value.
  static String escapeText(String value) {
    if (value.startsWith('@')) return '@$value';
    return value;
  }

  /// Escapes a GEDCOM pointer (e.g., 'I1' -> '@I1@').
  static String escapePointer(String value) {
    if (value.startsWith('@') && value.endsWith('@')) return value;
    return '@$value@';
  }
}
