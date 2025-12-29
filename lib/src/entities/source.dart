import 'package:equatable/equatable.dart';

/// Represents a source (SOUR) of information.
class Source extends Equatable {
  final String id;
  final String title;
  final String? author;
  final String? publicationInfo;
  final String? repositoryId;
  final String? text; // Transcription

  const Source({
    required this.id,
    required this.title,
    this.author,
    this.publicationInfo,
    this.repositoryId,
    this.text,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        publicationInfo,
        repositoryId,
        text,
      ];

  Source copyWith({
    String? id,
    String? title,
    String? author,
    String? publicationInfo,
    String? repositoryId,
    String? text,
  }) =>
      Source(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        publicationInfo: publicationInfo ?? this.publicationInfo,
        repositoryId: repositoryId ?? this.repositoryId,
        text: text ?? this.text,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publicationInfo': publicationInfo,
        'repositoryId': repositoryId,
        'text': text,
      };

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        publicationInfo: json['publicationInfo'] as String?,
        repositoryId: json['repositoryId'] as String?,
        text: json['text'] as String?,
      );
}
