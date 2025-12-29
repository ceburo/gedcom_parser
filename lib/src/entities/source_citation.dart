import 'package:equatable/equatable.dart';

/// Represents a citation of a source (SOUR) within an event or person.
class SourceCitation extends Equatable {
  final String sourceId;
  final String? page; // Cote, reference, page
  final String? quality; // Quality of data (0-3)
  final String? text; // Specific transcription for this citation
  final List<String> mediaIds; // Linked media (OBJE)

  const SourceCitation({
    required this.sourceId,
    this.page,
    this.quality,
    this.text,
    this.mediaIds = const [],
  });

  @override
  List<Object?> get props => [sourceId, page, quality, text, mediaIds];

  SourceCitation copyWith({
    String? sourceId,
    String? page,
    String? quality,
    String? text,
    List<String>? mediaIds,
  }) =>
      SourceCitation(
        sourceId: sourceId ?? this.sourceId,
        page: page ?? this.page,
        quality: quality ?? this.quality,
        text: text ?? this.text,
        mediaIds: mediaIds ?? this.mediaIds,
      );

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'page': page,
        'quality': quality,
        'text': text,
        'mediaIds': mediaIds,
      };

  factory SourceCitation.fromJson(Map<String, dynamic> json) => SourceCitation(
        sourceId: json['sourceId'] as String,
        page: json['page'] as String?,
        quality: json['quality'] as String?,
        text: json['text'] as String?,
        mediaIds: List<String>.from(json['mediaIds'] as List),
      );
}
