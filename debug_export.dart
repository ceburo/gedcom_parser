import 'dart:io';
import 'package:gedcom_parser/src/services/gedcom_parser.dart';
import 'package:gedcom_parser/src/services/gedcom_exporter.dart';

void main() {
  final file = File('test/src/5/555SAMPLE.ged');
  final lines = file.readAsLinesSync();

  final parser = GedcomParser();
  final data = parser.parseLines(lines);

  final exporter = GedcomExporter();
  final exported = exporter.export(data);

  final exportedLines = exported.split('\n');
  // Remove trailing empty line if any
  if (exportedLines.isNotEmpty && exportedLines.last.isEmpty) {
    exportedLines.removeLast();
  }

  print('Original lines: ${lines.length}');
  print('Exported lines: ${exportedLines.length}');

  print('\n--- Comparison ---');
  final maxLength =
      lines.length > exportedLines.length ? lines.length : exportedLines.length;

  for (var i = 0; i < maxLength; i++) {
    final original = i < lines.length ? lines[i] : 'MISSING';
    final exported = i < exportedLines.length ? exportedLines[i] : 'MISSING';

    if (original != exported) {
      print('Line ${i + 1}:');
      print('  Original: "$original"');
      print('  Exported: "$exported"');
    }
  }
}
