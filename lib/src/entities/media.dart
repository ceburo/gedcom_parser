import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Represents a multimedia object (OBJE) in a GEDCOM file.
class Media extends Equatable {
  final String id;
  final String path;
  final String? title;
  final String? format; // e.g., jpg, pdf
  final String? description;
  final String? blobData;

  const Media({
    required this.id,
    required this.path,
    this.title,
    this.format,
    this.description,
    this.blobData,
  });

  /// Returns the decoded binary data if [blobData] is present and base64 encoded.
  Uint8List? get blobBytes {
    if (blobData == null) return null;
    try {
      // Remove newlines and spaces that might be present from CONT tags
      final cleaned = blobData!.replaceAll(RegExp(r'[\s\n\r]'), '');
      return base64Decode(cleaned);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, path, title, format, description, blobData];

  Media copyWith({
    String? id,
    String? path,
    String? title,
    String? format,
    String? description,
    String? blobData,
  }) =>
      Media(
        id: id ?? this.id,
        path: path ?? this.path,
        title: title ?? this.title,
        format: format ?? this.format,
        description: description ?? this.description,
        blobData: blobData ?? this.blobData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'title': title,
        'format': format,
        'description': description,
        'blobData': blobData,
      };

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'] as String,
        path: json['path'] as String,
        title: json['title'] as String?,
        format: json['format'] as String?,
        description: json['description'] as String?,
        blobData: json['blobData'] as String?,
      );
}
