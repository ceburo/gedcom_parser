import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';

/// Represents a multimedia object (OBJE) in a GEDCOM file.
class Media extends Equatable {
  final String id;
  final List<MediaFile> files;
  final String? title;
  final List<String> notes;
  final List<String> sharedNoteIds;
  final String? blobData;

  /// The raw GEDCOM nodes for this media object.
  final List<GedcomNode> nodes;

  const Media({
    required this.id,
    this.files = const [],
    this.title,
    this.notes = const [],
    this.sharedNoteIds = const [],
    this.blobData,
    this.nodes = const [],
  });

  /// Returns the first file path if available.
  String get path => files.isNotEmpty ? files.first.path : "";

  /// Returns the first file format if available.
  String? get format => files.isNotEmpty ? files.first.format : null;

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
  List<Object?> get props =>
      [id, files, title, notes, sharedNoteIds, blobData, nodes];

  Media copyWith({
    String? id,
    List<MediaFile>? files,
    String? title,
    List<String>? notes,
    List<String>? sharedNoteIds,
    String? blobData,
    List<GedcomNode>? nodes,
  }) =>
      Media(
        id: id ?? this.id,
        files: files ?? this.files,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        sharedNoteIds: sharedNoteIds ?? this.sharedNoteIds,
        blobData: blobData ?? this.blobData,
        nodes: nodes ?? this.nodes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'files': files.map((f) => f.toJson()).toList(),
        'title': title,
        'notes': notes,
        'sharedNoteIds': sharedNoteIds,
        'blobData': blobData,
      };

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'] as String,
        files: (json['files'] as List<dynamic>?)
                ?.map((f) => MediaFile.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        title: json['title'] as String?,
        notes: (json['notes'] as List<dynamic>?)?.cast<String>() ?? [],
        sharedNoteIds:
            (json['sharedNoteIds'] as List<dynamic>?)?.cast<String>() ?? [],
        blobData: json['blobData'] as String?,
      );
}

/// Represents a file reference within a [Media] object.
class MediaFile extends Equatable {
  final String path;
  final String? format;

  const MediaFile({
    required this.path,
    this.format,
  });

  @override
  List<Object?> get props => [path, format];

  Map<String, dynamic> toJson() => {
        'path': path,
        'format': format,
      };

  factory MediaFile.fromJson(Map<String, dynamic> json) => MediaFile(
        path: json['path'] as String,
        format: json['format'] as String?,
      );
}
