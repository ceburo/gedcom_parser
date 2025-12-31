# GEDCOM Parser

A standalone Dart package for parsing, manipulating, and exporting GEDCOM files. This package is designed to be fast, reliable, and compliant with GEDCOM standards.

## Features

- **Standard Support**: Full support for GEDCOM 5.5.1 and 7.0.
- **Embedded BLOB Support**: Support for embedded binary data (BLOB) in GEDCOM 5.5.
- **Lossless Export**: Synchronize structured entities with raw GEDCOM nodes for lossless export.
- **Rich Data Model**: Support for individuals, families, sources, repositories, and media.
- **Advanced Date Parsing**: GEDCOM date parsing and formatting, including support for Gregorian, Julian, and French Republican calendars.
- **Standalone**: No dependencies on Flutter, making it suitable for CLI, server-side, or web applications.

## Usage

```dart
import 'package:gedcom_parser/gedcom_parser.dart';

void main() {
  final parser = GedcomParser();
  final lines = [
    '0 HEAD',
    '0 @I1@ INDI',
    '1 NAME John /Doe/',
    '1 SEX M',
    '0 TRLR',
  ];
  
  final data = parser.parseLines(lines);
  print(data.persons['I1']?.firstName); // John
  
  final exporter = GedcomExporter();
  final output = exporter.export(data);
  print(output);
}
```

## Installation

Add `gedcom_parser` to your `pubspec.yaml`:

```yaml
dependencies:
  gedcom_parser: ^0.0.1
```

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
