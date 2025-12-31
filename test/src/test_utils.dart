import 'dart:io';
import 'dart:convert';

String decodeUtf16(List<int> bytes, {required bool littleEndian}) {
  final codeUnits = <int>[];
  for (var i = 0; i < bytes.length - 1; i += 2) {
    if (littleEndian) {
      codeUnits.add(bytes[i] | (bytes[i + 1] << 8));
    } else {
      codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
    }
  }
  return String.fromCharCodes(codeUnits);
}

String decodeFile(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // UTF-16 LE
      return decodeUtf16(bytes.sublist(2), littleEndian: true);
    } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      // UTF-16 BE
      return decodeUtf16(bytes.sublist(2), littleEndian: false);
    }
  }
  // Try UTF-8
  try {
    return utf8.decode(bytes);
  } catch (e) {
    // Fallback to Latin1
    return latin1.decode(bytes);
  }
}
