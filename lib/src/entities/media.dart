import 'package:equatable/equatable.dart';

/// Represents a multimedia object (OBJE) in a GEDCOM file.
class Media extends Equatable {
  final String id;
  final String path;
  final String? title;
  final String? format; // e.g., jpg, pdf
  final String? description;

  const Media({
    required this.id,
    required this.path,
    this.title,
    this.format,
    this.description,
  });

  @override
  List<Object?> get props => [id, path, title, format, description];

  Media copyWith({
    String? id,
    String? path,
    String? title,
    String? format,
    String? description,
  }) =>
      Media(
        id: id ?? this.id,
        path: path ?? this.path,
        title: title ?? this.title,
        format: format ?? this.format,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'title': title,
        'format': format,
        'description': description,
      };

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'] as String,
        path: json['path'] as String,
        title: json['title'] as String?,
        format: json['format'] as String?,
        description: json['description'] as String?,
      );
}
