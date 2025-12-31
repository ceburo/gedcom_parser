import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';
import "package:equatable/equatable.dart";

/// Represents an individual in a genealogical tree.
class Person extends Equatable {
  /// Unique identifier for the person (usually from the GEDCOM file).
  final String id;

  /// The person's first name(s).
  final String firstName;

  /// The person's other names (middle names).
  final String? middleNames;

  /// The person's last name (surname).
  final String lastName;

  /// The person's full name as it appears in the GEDCOM file.
  final String? rawName;

  /// The person's nickname.
  final String? nickname;

  /// The person's alias.
  final String? alias;

  /// Date of birth as a string.
  final String? birthDate;

  /// Place of birth.
  final String? birthPlace;

  /// Date of death as a string.
  final String? deathDate;

  /// Place of death.
  final String? deathPlace;

  /// Date of burial.
  final String? burialDate;

  /// Place of burial.
  final String? burialPlace;

  /// The person's occupation or profession.
  final String? occupation;

  /// The person's name suffix (e.g., Jr., III).
  final String? suffix;

  /// Biological sex: "M" (Male), "F" (Female), or "U" (Unknown).
  final String sex;

  /// List of notes associated with this person.
  final List<String> notes;

  /// List of shared note IDs associated with this person.
  final List<String> sharedNoteIds;

  /// List of source citations for the birth event.
  final List<SourceCitation> birthSources;

  /// List of source citations for the death event.
  final List<SourceCitation> deathSources;

  /// List of source citations for the burial event.
  final List<SourceCitation> burialSources;

  /// List of media IDs associated with this person.
  final List<String> mediaIds;

  /// All GEDCOM nodes associated with this person for lossless export.
  final List<GedcomNode> nodes;

  /// Returns true if at least one source is cited for the birth.
  bool get hasBirthSource => birthSources.isNotEmpty;

  /// Returns true if at least one source is cited for the death.
  bool get hasDeathSource => deathSources.isNotEmpty;

  /// Creates a new [Person] instance.
  const Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.rawName,
    this.middleNames,
    this.nickname,
    this.alias,
    this.birthDate,
    this.birthPlace,
    this.deathDate,
    this.deathPlace,
    this.burialDate,
    this.burialPlace,
    this.occupation,
    this.suffix,
    this.sex = "U",
    this.notes = const [],
    this.sharedNoteIds = const [],
    this.birthSources = const [],
    this.deathSources = const [],
    this.burialSources = const [],
    this.mediaIds = const [],
    this.nodes = const [],
  });

  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? rawName,
    String? middleNames,
    String? nickname,
    String? alias,
    String? birthDate,
    String? birthPlace,
    String? deathDate,
    String? deathPlace,
    String? burialDate,
    String? burialPlace,
    String? occupation,
    String? suffix,
    String? sex,
    List<String>? notes,
    List<String>? sharedNoteIds,
    List<SourceCitation>? birthSources,
    List<SourceCitation>? deathSources,
    List<SourceCitation>? burialSources,
    List<String>? mediaIds,
    List<GedcomNode>? nodes,
  }) =>
      Person(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        rawName: rawName ?? this.rawName,
        middleNames: middleNames ?? this.middleNames,
        nickname: nickname ?? this.nickname,
        alias: alias ?? this.alias,
        birthDate: birthDate ?? this.birthDate,
        birthPlace: birthPlace ?? this.birthPlace,
        deathDate: deathDate ?? this.deathDate,
        deathPlace: deathPlace ?? this.deathPlace,
        burialDate: burialDate ?? this.burialDate,
        burialPlace: burialPlace ?? this.burialPlace,
        occupation: occupation ?? this.occupation,
        suffix: suffix ?? this.suffix,
        sex: sex ?? this.sex,
        notes: notes ?? this.notes,
        sharedNoteIds: sharedNoteIds ?? this.sharedNoteIds,
        birthSources: birthSources ?? this.birthSources,
        deathSources: deathSources ?? this.deathSources,
        burialSources: burialSources ?? this.burialSources,
        mediaIds: mediaIds ?? this.mediaIds,
        nodes: nodes ?? this.nodes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'middleNames': middleNames,
        'lastName': lastName,
        'rawName': rawName,
        'nickname': nickname,
        'alias': alias,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'deathDate': deathDate,
        'deathPlace': deathPlace,
        'burialDate': burialDate,
        'burialPlace': burialPlace,
        'occupation': occupation,
        'suffix': suffix,
        'sex': sex,
        'notes': notes,
        'birthSources': birthSources.map((s) => s.toJson()).toList(),
        'deathSources': deathSources.map((s) => s.toJson()).toList(),
        'burialSources': burialSources.map((s) => s.toJson()).toList(),
        'mediaIds': mediaIds,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        middleNames: json['middleNames'] as String?,
        lastName: json['lastName'] as String,
        rawName: json['rawName'] as String?,
        nickname: json['nickname'] as String?,
        alias: json['alias'] as String?,
        birthDate: json['birthDate'] as String?,
        birthPlace: json['birthPlace'] as String?,
        deathDate: json['deathDate'] as String?,
        deathPlace: json['deathPlace'] as String?,
        burialDate: json['burialDate'] as String?,
        burialPlace: json['burialPlace'] as String?,
        occupation: json['occupation'] as String?,
        suffix: json['suffix'] as String?,
        sex: json['sex'] as String? ?? "U",
        notes: List<String>.from(json['notes'] as List),
        birthSources: (json['birthSources'] as List)
            .map((s) => SourceCitation.fromJson(s as Map<String, dynamic>))
            .toList(),
        deathSources: (json['deathSources'] as List)
            .map((s) => SourceCitation.fromJson(s as Map<String, dynamic>))
            .toList(),
        burialSources: (json['burialSources'] as List)
            .map((s) => SourceCitation.fromJson(s as Map<String, dynamic>))
            .toList(),
        mediaIds: List<String>.from(json['mediaIds'] as List),
        nodes: (json['nodes'] as List)
            .map((n) => GedcomNode.fromJson(n as Map<String, dynamic>))
            .toList(),
      );

  String get fullName => "$firstName $lastName";

  /// Returns a new [Person] with an updated CHAN (change date) node.
  Person withUpdatedChangeDate() {
    final now = DateTime.now();
    final months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC"
    ];
    final dateStr = "${now.day} ${months[now.month - 1]} ${now.year}";
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final newNodes = List<GedcomNode>.from(nodes);
    final chanIndex = newNodes.indexWhere((n) => n.tag == "CHAN");

    final dateNode = GedcomNode(level: 2, tag: "DATE", value: dateStr);
    final timeNode = GedcomNode(level: 2, tag: "TIME", value: timeStr);
    final chanNode = GedcomNode(
      level: 1,
      tag: "CHAN",
      children: [dateNode, timeNode],
    );

    if (chanIndex != -1) {
      newNodes[chanIndex] = chanNode;
    } else {
      newNodes.add(chanNode);
    }

    return copyWith(nodes: newNodes);
  }

  /// Returns the value of the first node with the given tag.
  String? getTagValue(String tag) {
    for (final node in nodes) {
      if (node.tag == tag) {
        return node.valueWithChildren;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        rawName,
        middleNames,
        nickname,
        alias,
        birthDate,
        birthPlace,
        deathDate,
        deathPlace,
        burialDate,
        burialPlace,
        occupation,
        suffix,
        sex,
        notes,
        birthSources,
        deathSources,
        burialSources,
        mediaIds,
        nodes,
      ];
}
