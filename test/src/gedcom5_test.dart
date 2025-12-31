import 'dart:io';
import 'package:gedcom_parser/src/services/gedcom_parser.dart';
import 'package:gedcom_parser/src/services/gedcom_exporter.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'test_utils.dart';

void main() {
  final parser = GedcomParser();
  final exporter = GedcomExporter();

  final test5Dir = Directory('test/src/5');
  if (!test5Dir.existsSync()) {
    print('Warning: test/src/5 directory not found.');
    return;
  }

  final files5 = test5Dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ged'))
      .toList();

  group('GEDCOM 5.5 Compatibility Tests', () {
    for (final file in files5) {
      final fileName = p.basename(file.path);

      test('Round-trip: $fileName', () {
        final content = decodeFile(file);
        final lines = content.split(RegExp(r'\r?\n'));

        // 1. Parse
        final data = parser.parseLines(lines);

        // 2. Export (WITHOUT SYNC)
        final exported = exporter.export(data);

        // 4. Compare (ignoring trailing whitespace/newlines differences if any)
        final originalLines = content
            .split('\n')
            .map((l) => l.trimRight())
            .where((l) => l.isNotEmpty)
            .toList();
        final exportedLines = exported
            .split('\n')
            .map((l) => l.trimRight())
            .where((l) => l.isNotEmpty)
            .toList();

        expect(exportedLines.length, originalLines.length,
            reason: 'Line count mismatch in $fileName');

        for (var i = 0; i < originalLines.length; i++) {
          expect(exportedLines[i], originalLines[i],
              reason: 'Mismatch at line ${i + 1} in $fileName');
        }
      });
    }
  });
}
