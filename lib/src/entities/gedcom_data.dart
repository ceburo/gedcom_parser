import 'package:gedcom_parser/src/entities/shared_note.dart';
import 'package:gedcom_parser/src/utils/gedcom_date_parser.dart';
import 'package:gedcom_parser/src/entities/family.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/media.dart';
import 'package:gedcom_parser/src/entities/person.dart';
import 'package:gedcom_parser/src/entities/repository.dart';
import 'package:gedcom_parser/src/entities/source.dart';
import "package:equatable/equatable.dart";

/// Container for all genealogical data parsed from a GEDCOM file.
class GedcomData extends Equatable {
  /// Map of person IDs to [Person] objects.
  final Map<String, Person> persons;

  /// Map of family IDs to [Family] objects.
  final Map<String, Family> families;

  /// Map of source IDs to [Source] objects.
  final Map<String, Source> sources;

  /// Map of repository IDs to [Repository] objects.
  final Map<String, Repository> repositories;

  /// Map of media IDs to [Media] objects.
  final Map<String, Media> media;

  /// Map of shared note IDs to [SharedNote] objects.
  final Map<String, SharedNote> sharedNotes;

  /// The ID of the person designated as SOSA 1 (the root of the tree).
  final String? sosa1Id;

  /// Map of person IDs to their calculated SOSA number.
  final Map<String, int> sosaNumbers;

  /// Map of child person IDs to their parent family ID.
  final Map<String, String> childToFamilyId;

  /// The raw GEDCOM nodes for lossless export.
  final List<GedcomNode> nodes;

  /// Returns the person who was last modified (based on CHAN tag).
  Person? get lastModifiedPerson {
    if (persons.isEmpty) {
      return null;
    }

    Person? lastModified;
    DateTime? maxDate;

    for (final person in persons.values) {
      final date = _getChangeDate(person);
      if (date != null) {
        if (maxDate == null || date.isAfter(maxDate)) {
          maxDate = date;
          lastModified = person;
        }
      }
    }

    return lastModified;
  }

  DateTime? _getChangeDate(Person person) {
    for (final node in person.nodes) {
      if (node.tag == "CHAN") {
        for (final sub in node.children) {
          if (sub.tag == "DATE") {
            return GedcomDateParser.parse(sub.value);
          }
        }
      }
    }
    return null;
  }

  /// Creates a new [GedcomData] instance.
  const GedcomData({
    required this.persons,
    required this.families,
    this.sources = const {},
    this.repositories = const {},
    this.media = const {},
    this.sharedNotes = const {},
    this.sosa1Id,
    this.sosaNumbers = const {},
    this.childToFamilyId = const {},
    this.nodes = const [],
  });

  GedcomData copyWith({
    Map<String, Person>? persons,
    Map<String, Family>? families,
    Map<String, Source>? sources,
    Map<String, Repository>? repositories,
    Map<String, Media>? media,
    Map<String, SharedNote>? sharedNotes,
    String? sosa1Id,
    Map<String, int>? sosaNumbers,
    Map<String, String>? childToFamilyId,
    List<GedcomNode>? nodes,
  }) =>
      GedcomData(
        persons: persons ?? this.persons,
        families: families ?? this.families,
        sources: sources ?? this.sources,
        repositories: repositories ?? this.repositories,
        media: media ?? this.media,
        sharedNotes: sharedNotes ?? this.sharedNotes,
        sosa1Id: sosa1Id ?? this.sosa1Id,
        sosaNumbers: sosaNumbers ?? this.sosaNumbers,
        childToFamilyId: childToFamilyId ?? this.childToFamilyId,
        nodes: nodes ?? this.nodes,
      );

  /// Returns a set of all unique first names in the dataset.
  Set<String> get allFirstNames => persons.values
      .map((p) => p.firstName)
      .where((name) => name.isNotEmpty)
      .toSet();

  /// Returns a set of all unique last names in the dataset.
  Set<String> get allLastNames => persons.values
      .map((p) => p.lastName.toUpperCase())
      .where((name) => name.isNotEmpty)
      .toSet();

  /// Returns a set of all unique places in the dataset.
  Set<String> get allPlaces {
    final places = <String>{};
    for (final person in persons.values) {
      if (person.birthPlace != null && person.birthPlace!.isNotEmpty) {
        places.add(person.birthPlace!);
      }
      if (person.deathPlace != null && person.deathPlace!.isNotEmpty) {
        places.add(person.deathPlace!);
      }
      if (person.burialPlace != null && person.burialPlace!.isNotEmpty) {
        places.add(person.burialPlace!);
      }
    }
    for (final family in families.values) {
      if (family.marriagePlace != null && family.marriagePlace!.isNotEmpty) {
        places.add(family.marriagePlace!);
      }
    }
    return places;
  }

  @override
  List<Object?> get props => [
        persons,
        families,
        sources,
        repositories,
        media,
        sharedNotes,
        sosa1Id,
        sosaNumbers,
        childToFamilyId,
        nodes,
      ];
}
