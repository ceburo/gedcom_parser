import 'package:equatable/equatable.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';

/// Represents a shared note (SNOTE) in a GEDCOM file.
class SharedNote extends Equatable {
  /// Unique identifier for the shared note.
  final String id;

  /// The text content of the note.
  final String text;

  /// All GEDCOM nodes associated with this note for lossless export.
  final List<GedcomNode> nodes;

  const SharedNote({
    required this.id,
    required this.text,
    this.nodes = const [],
  });

  @override
  List<Object?> get props => [id, text, nodes];

  SharedNote copyWith({
    String? id,
    String? text,
    List<GedcomNode>? nodes,
  }) =>
      SharedNote(
        id: id ?? this.id,
        text: text ?? this.text,
        nodes: nodes ?? this.nodes,
      );
}
