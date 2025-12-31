import 'package:gedcom_parser/src/entities/family.dart';
import 'package:gedcom_parser/src/entities/gedcom_data.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/media.dart';
import 'package:gedcom_parser/src/entities/person.dart';
import 'package:gedcom_parser/src/entities/repository.dart';
import 'package:gedcom_parser/src/entities/source.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';

/// A service for parsing GEDCOM files into structured [GedcomData].
class GedcomParser {
  /// Parses a list of GEDCOM lines into a [GedcomData] object.
  ///
  /// This method handles the initial node parsing and then maps those nodes
  /// to high-level entities like [Person], [Family], [Source], etc.
  GedcomData parseLines(List<String> lines) {
    final nodes = _parseToNodes(lines);

    final persons = <String, Person>{};
    final families = <String, Family>{};
    final sources = <String, Source>{};
    final repositories = <String, Repository>{};
    final media = <String, Media>{};
    final childToFamilyId = <String, String>{};

    for (final node in nodes) {
      if (node.tag == "INDI" && node.xref != null) {
        persons[node.xref!] = _parsePerson(node);
      } else if (node.tag == "FAM" && node.xref != null) {
        final family = _parseFamily(node);
        families[node.xref!] = family;
        for (final childId in family.childrenIds) {
          childToFamilyId[childId] = node.xref!;
        }
      } else if (node.tag == "SOUR" && node.xref != null) {
        sources[node.xref!] = _parseSource(node);
      } else if (node.tag == "REPO" && node.xref != null) {
        repositories[node.xref!] = _parseRepository(node);
      } else if (node.tag == "OBJE" && node.xref != null) {
        media[node.xref!] = _parseMedia(node);
      }
    }

    return GedcomData(
      persons: persons,
      families: families,
      sources: sources,
      repositories: repositories,
      media: media,
      childToFamilyId: childToFamilyId,
      nodes: nodes,
    );
  }

  List<GedcomNode> _parseToNodes(List<String> lines) {
    final roots = <_MutableGedcomNode>[];
    final stack = <_MutableGedcomNode>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      // GEDCOM line format: level [xref] tag [value]
      // Note: xref is @ID@
      final match = RegExp(
        r'^(\d+)\s+(?:(@[^@]+@)\s+)?(\w+)(?:\s+(.*))?$',
      ).firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final level = int.parse(match.group(1)!);
      var xref = match.group(2);
      if (xref != null && xref.startsWith("@") && xref.endsWith("@")) {
        xref = xref.substring(1, xref.length - 1);
      }
      final tag = match.group(3)!;
      var value = match.group(4);
      if (value != null && value.startsWith("@") && value.endsWith("@")) {
        value = value.substring(1, value.length - 1);
      }

      final node = _MutableGedcomNode(level, tag, value, xref);

      if (level == 0) {
        roots.add(node);
        stack.clear();
        stack.add(node);
      } else {
        while (stack.isNotEmpty && stack.last.level >= level) {
          stack.removeLast();
        }
        if (stack.isNotEmpty) {
          stack.last.children.add(node);
          stack.add(node);
        }
      }
    }

    return roots.map((r) => r.toImmutable()).toList();
  }

  Person _parsePerson(GedcomNode node) {
    var firstName = "";
    var lastName = "";
    String? middleNames;
    String? nickname;
    String? alias;
    String? sex;
    String? birthDate;
    String? birthPlace;
    String? deathDate;
    String? deathPlace;
    String? burialDate;
    String? burialPlace;
    String? occupation;
    final notes = <String>[];
    final birthSources = <SourceCitation>[];
    final deathSources = <SourceCitation>[];
    final burialSources = <SourceCitation>[];
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "NAME":
          final val = child.valueWithChildren;
          if (val.contains("/")) {
            final parts = val.split("/");
            firstName = parts[0].trim();
            if (parts.length > 1) {
              lastName = parts[1].trim();
            }
          } else {
            firstName = val;
          }

          // Try to get more specific name parts if available
          for (final sub in child.children) {
            if (sub.tag == "GIVN") {
              final givn = sub.valueWithChildren;
              if (givn.contains(" ")) {
                final parts = givn.split(" ");
                firstName = parts[0];
                middleNames = parts.sublist(1).join(" ");
              } else {
                firstName = givn;
              }
            }
            if (sub.tag == "SURN") {
              lastName = sub.valueWithChildren;
            }
          }
        case "NICK":
          nickname = child.valueWithChildren;
        case "ALIA":
          alias = child.valueWithChildren;
        case "SEX":
          sex = child.value;
        case "BIRT":
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              birthDate = sub.value;
            }
            if (sub.tag == "PLAC") {
              birthPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              birthSources.add(_parseSourceCitation(sub));
            }
          }
        case "DEAT":
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              deathDate = sub.value;
            }
            if (sub.tag == "PLAC") {
              deathPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              deathSources.add(_parseSourceCitation(sub));
            }
          }
        case "BURI":
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              burialDate = sub.value;
            }
            if (sub.tag == "PLAC") {
              burialPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              burialSources.add(_parseSourceCitation(sub));
            }
          }
        case "OCCU":
          occupation = child.valueWithChildren;
        case "NOTE":
          notes.add(child.valueWithChildren);
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(child.value!);
          }
      }
    }

    return Person(
      id: node.xref!,
      firstName: firstName,
      lastName: lastName,
      middleNames: middleNames,
      nickname: nickname,
      alias: alias,
      sex: sex ?? "U",
      birthDate: birthDate,
      birthPlace: birthPlace,
      deathDate: deathDate,
      deathPlace: deathPlace,
      burialDate: burialDate,
      burialPlace: burialPlace,
      occupation: occupation,
      notes: notes,
      birthSources: birthSources,
      deathSources: deathSources,
      burialSources: burialSources,
      mediaIds: mediaIds,
      nodes: node.children,
    );
  }

  Family _parseFamily(GedcomNode node) {
    String? husbandId;
    String? wifeId;
    final childrenIds = <String>[];
    String? marriageDate;
    String? marriagePlace;
    final notes = <String>[];
    final marriageSources = <SourceCitation>[];
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "HUSB":
          husbandId = child.value;
        case "WIFE":
          wifeId = child.value;
        case "CHIL":
          if (child.value != null) {
            childrenIds.add(child.value!);
          }
        case "MARR":
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              marriageDate = sub.value;
            }
            if (sub.tag == "PLAC") {
              marriagePlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              marriageSources.add(_parseSourceCitation(sub));
            }
          }
        case "NOTE":
          notes.add(child.valueWithChildren);
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(child.value!);
          }
      }
    }

    return Family(
      id: node.xref!,
      husbandId: husbandId,
      wifeId: wifeId,
      childrenIds: childrenIds,
      marriageDate: marriageDate,
      marriagePlace: marriagePlace,
      notes: notes,
      marriageSources: marriageSources,
      mediaIds: mediaIds,
      nodes: node.children,
    );
  }

  Source _parseSource(GedcomNode node) {
    var title = "";
    String? author;
    String? publicationInfo;
    String? repositoryId;
    String? text;

    for (final child in node.children) {
      switch (child.tag) {
        case "TITL":
          title = child.valueWithChildren;
        case "AUTH":
          author = child.valueWithChildren;
        case "PUBL":
          publicationInfo = child.valueWithChildren;
        case "REPO":
          repositoryId = child.value;
        case "TEXT":
          text = child.valueWithChildren;
      }
    }
    return Source(
      id: node.xref!,
      title: title,
      author: author,
      publicationInfo: publicationInfo,
      repositoryId: repositoryId,
      text: text,
    );
  }

  Repository _parseRepository(GedcomNode node) {
    var name = "";
    String? address;
    String? phone;
    String? email;
    String? website;

    for (final child in node.children) {
      switch (child.tag) {
        case "NAME":
          name = child.valueWithChildren;
        case "ADDR":
          address = child.valueWithChildren;
        case "PHON":
          phone = child.value;
        case "EMAIL":
          email = child.value;
        case "WWW":
          website = child.value;
      }
    }
    return Repository(
      id: node.xref!,
      name: name,
      address: address,
      phone: phone,
      email: email,
      website: website,
    );
  }

  Media _parseMedia(GedcomNode node) {
    var path = "";
    String? title;
    String? format;
    String? description;
    String? blobData;

    for (final child in node.children) {
      switch (child.tag) {
        case "FILE":
          path = child.value ?? "";
        case "TITL":
          title = child.valueWithChildren;
        case "FORM":
          format = child.value;
        case "NOTE":
          description = child.valueWithChildren;
        case "BLOB":
          blobData = child.valueWithChildren;
      }
    }
    return Media(
      id: node.xref!,
      path: path,
      title: title,
      format: format,
      description: description,
      blobData: blobData,
    );
  }

  SourceCitation _parseSourceCitation(GedcomNode node) {
    final sourceId = node.value ?? "";
    String? page;
    String? quality;
    String? text;
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "PAGE":
          page = child.valueWithChildren;
        case "QUAY":
          quality = child.value;
        case "DATA":
          for (final sub in child.children) {
            if (sub.tag == "TEXT") {
              text = sub.valueWithChildren;
            }
          }
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(child.value!);
          }
      }
    }
    return SourceCitation(
      sourceId: sourceId,
      page: page,
      quality: quality,
      text: text,
      mediaIds: mediaIds,
    );
  }
}

class _MutableGedcomNode {
  int level;
  String tag;
  String? value;
  String? xref;
  List<_MutableGedcomNode> children = [];

  _MutableGedcomNode(this.level, this.tag, this.value, this.xref);

  GedcomNode toImmutable() => GedcomNode(
        level: level,
        tag: tag,
        value: value,
        xref: xref,
        children: children.map((c) => c.toImmutable()).toList(),
      );
}
