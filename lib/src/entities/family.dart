import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';
import "package:equatable/equatable.dart";

/// Represents a family unit in a GEDCOM dataset.
class Family extends Equatable {
  /// Unique identifier for the family (e.g., "@F1@").
  final String id;

  /// ID of the husband/father in the family.
  final String? husbandId;

  /// ID of the wife/mother in the family.
  final String? wifeId;

  /// List of IDs of children belonging to this family.
  final List<String> childrenIds;

  /// Date of the marriage or union.
  final String? marriageDate;

  /// Place where the marriage or union occurred.
  final String? marriagePlace;

  /// Additional notes or comments about the family.
  final List<String> notes;

  /// List of source citations for the marriage event.
  final List<SourceCitation> marriageSources;

  /// List of media IDs associated with this family.
  final List<String> mediaIds;

  /// All GEDCOM nodes associated with this family for lossless export.
  final List<GedcomNode> nodes;

  const Family({
    required this.id,
    this.husbandId,
    this.wifeId,
    this.childrenIds = const [],
    this.marriageDate,
    this.marriagePlace,
    this.notes = const [],
    this.marriageSources = const [],
    this.mediaIds = const [],
    this.nodes = const [],
  });

  @override
  List<Object?> get props => [
        id,
        husbandId,
        wifeId,
        childrenIds,
        marriageDate,
        marriagePlace,
        notes,
        marriageSources,
        mediaIds,
        nodes,
      ];

  Family copyWith({
    String? id,
    String? husbandId,
    String? wifeId,
    List<String>? childrenIds,
    String? marriageDate,
    String? marriagePlace,
    List<String>? notes,
    List<SourceCitation>? marriageSources,
    List<String>? mediaIds,
    List<GedcomNode>? nodes,
  }) =>
      Family(
        id: id ?? this.id,
        husbandId: husbandId ?? this.husbandId,
        wifeId: wifeId ?? this.wifeId,
        childrenIds: childrenIds ?? this.childrenIds,
        marriageDate: marriageDate ?? this.marriageDate,
        marriagePlace: marriagePlace ?? this.marriagePlace,
        notes: notes ?? this.notes,
        marriageSources: marriageSources ?? this.marriageSources,
        mediaIds: mediaIds ?? this.mediaIds,
        nodes: nodes ?? this.nodes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'husbandId': husbandId,
        'wifeId': wifeId,
        'childrenIds': childrenIds,
        'marriageDate': marriageDate,
        'marriagePlace': marriagePlace,
        'notes': notes,
        'marriageSources': marriageSources.map((s) => s.toJson()).toList(),
        'mediaIds': mediaIds,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        husbandId: json['husbandId'] as String?,
        wifeId: json['wifeId'] as String?,
        childrenIds: List<String>.from(json['childrenIds'] as List),
        marriageDate: json['marriageDate'] as String?,
        marriagePlace: json['marriagePlace'] as String?,
        notes: List<String>.from(json['notes'] as List),
        marriageSources: (json['marriageSources'] as List)
            .map((s) => SourceCitation.fromJson(s as Map<String, dynamic>))
            .toList(),
        mediaIds: List<String>.from(json['mediaIds'] as List),
        nodes: (json['nodes'] as List)
            .map((n) => GedcomNode.fromJson(n as Map<String, dynamic>))
            .toList(),
      );

  /// Returns the value of the first node with the given tag.
  String? getTagValue(String tag) {
    for (final node in nodes) {
      if (node.tag == tag) {
        return node.valueWithChildren;
      }
    }
    return null;
  }
}
