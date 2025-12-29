import 'package:equatable/equatable.dart';

/// Represents a single line and its children in a GEDCOM file.
/// This allows for lossless storage of all GEDCOM data, including
/// tags not explicitly mapped to domain properties.
class GedcomNode extends Equatable {
  /// The level of the node (0, 1, 2, etc.).
  final int level;

  /// The tag of the node (e.g., INDI, NAME, BIRT).
  final String tag;

  /// The value associated with the node, if any.
  final String? value;

  /// The cross-reference identifier, if any (e.g., @I1@).
  final String? xref;

  /// The children nodes of this node.
  final List<GedcomNode> children;

  const GedcomNode({
    required this.level,
    required this.tag,
    this.value,
    this.xref,
    this.children = const [],
  });

  @override
  List<Object?> get props => [level, tag, value, xref, children];

  /// Returns the value of this node, including any CONT/CONC children.
  String get valueWithChildren {
    var result = value ?? "";
    for (final child in children) {
      if (child.tag == "CONT") {
        result += "\n${child.value ?? ""}";
      } else if (child.tag == "CONC") {
        result += child.value ?? "";
      }
    }
    return result;
  }

  /// Returns a copy of this node with the given fields replaced.
  GedcomNode copyWith({
    int? level,
    String? tag,
    String? value,
    String? xref,
    List<GedcomNode>? children,
  }) =>
      GedcomNode(
        level: level ?? this.level,
        tag: tag ?? this.tag,
        value: value ?? this.value,
        xref: xref ?? this.xref,
        children: children ?? this.children,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'tag': tag,
        'value': value,
        'xref': xref,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory GedcomNode.fromJson(Map<String, dynamic> json) => GedcomNode(
        level: json['level'] as int,
        tag: json['tag'] as String,
        value: json['value'] as String?,
        xref: json['xref'] as String?,
        children: (json['children'] as List<dynamic>)
            .map((c) => GedcomNode.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
