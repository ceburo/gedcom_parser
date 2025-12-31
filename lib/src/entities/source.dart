import 'package:equatable/equatable.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';

/// Represents a source (SOUR) of information.
class Source extends Equatable {
  final String id;
  final String title;
  final String? author;
  final String? publicationInfo;
  final String? repositoryId;
  final String? text; // Transcription
  final List<String> notes;
  final List<String> sharedNoteIds;

  /// The raw GEDCOM nodes for this source.
  final List<GedcomNode> nodes;

  const Source({
    required this.id,
    required this.title,
    this.author,
    this.publicationInfo,
    this.repositoryId,
    this.text,
    this.notes = const [],
    this.sharedNoteIds = const [],
    this.nodes = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        publicationInfo,
        repositoryId,
        text,
        notes,
        sharedNoteIds,
        nodes,
      ];

  Source copyWith({
    String? id,
    String? title,
    String? author,
    String? publicationInfo,
    String? repositoryId,
    String? text,
    List<String>? notes,
    List<String>? sharedNoteIds,
    List<GedcomNode>? nodes,
  }) =>
      Source(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        publicationInfo: publicationInfo ?? this.publicationInfo,
        repositoryId: repositoryId ?? this.repositoryId,
        text: text ?? this.text,
        notes: notes ?? this.notes,
        sharedNoteIds: sharedNoteIds ?? this.sharedNoteIds,
        nodes: nodes ?? this.nodes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publicationInfo': publicationInfo,
        'repositoryId': repositoryId,
        'text': text,
        'notes': notes,
        'sharedNoteIds': sharedNoteIds,
      };

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        publicationInfo: json['publicationInfo'] as String?,
        repositoryId: json['repositoryId'] as String?,
        text: json['text'] as String?,
        notes: (json['notes'] as List<dynamic>?)?.cast<String>() ?? [],
        sharedNoteIds:
            (json['sharedNoteIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
