[![Pub Version](https://img.shields.io/pub/v/gedcom_parser?color=blue)](https://pub.dev/packages/gedcom_parser)
[![Pub Likes](https://img.shields.io/pub/likes/gedcom_parser?color=red)](https://pub.dev/packages/gedcom_parser)
[![Pub Points](https://img.shields.io/pub/points/gedcom_parser?label=pub%20points&logo=dart)](https://pub.dev/packages/gedcom_parser)

# GEDCOM Parser

A standalone Dart package for parsing, manipulating, and exporting GEDCOM files. This package is designed to be fast, reliable, and compliant with GEDCOM standards.

## Features

- **Standard Support**: Full support for GEDCOM 5.5.1 and 7.0 (100% pass rate on official test suite).
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
  gedcom_parser: ^0.0.8
```

## Publishing

This package uses GitHub Actions for automated publishing. To publish a new version:
1. Update the version in `pubspec.yaml` and `CHANGELOG.md`.
2. Push a tag starting with `v` (e.g., `v0.0.8`).
3. The GitHub Action will automatically run tests and publish to pub.dev using OIDC.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Please make sure to update tests as appropriate and follow the Dart style guide.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
