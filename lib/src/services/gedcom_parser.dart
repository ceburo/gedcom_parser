import 'package:gedcom_parser/src/entities/shared_note.dart';
import 'package:gedcom_parser/src/entities/family.dart';
import 'package:gedcom_parser/src/entities/gedcom_data.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/media.dart';
import 'package:gedcom_parser/src/entities/person.dart';
import 'package:gedcom_parser/src/entities/repository.dart';
import 'package:gedcom_parser/src/entities/source.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';
import 'package:gedcom_parser/src/utils/gedcom_string_utils.dart';

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
    final sharedNotes = <String, SharedNote>{};
    final childToFamilyId = <String, String>{};

    for (final node in nodes) {
      final xref = GedcomStringUtils.unescapePointer(node.xref);
      if (node.tag == "INDI" && xref != null) {
        persons[xref] = _parsePerson(node);
      } else if (node.tag == "FAM" && xref != null) {
        final family = _parseFamily(node);
        families[xref] = family;
        for (final childId in family.childrenIds) {
          childToFamilyId[childId] = xref;
        }
      } else if (node.tag == "SOUR" && xref != null) {
        sources[xref] = _parseSource(node);
      } else if (node.tag == "REPO" && xref != null) {
        repositories[xref] = _parseRepository(node);
      } else if (node.tag == "OBJE" && xref != null) {
        media[xref] = _parseMedia(node);
      } else if (node.tag == "SNOTE" && xref != null) {
        sharedNotes[xref] = _parseSharedNote(node);
      }
    }

    return GedcomData(
      persons: persons,
      families: families,
      sources: sources,
      repositories: repositories,
      media: media,
      sharedNotes: sharedNotes,
      childToFamilyId: childToFamilyId,
      nodes: nodes,
    );
  }

  SharedNote _parseSharedNote(GedcomNode node) {
    return SharedNote(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      text: node.valueWithChildren,
      nodes: node.children,
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
      final xref = match.group(2);
      final tag = match.group(3)!;
      final value = match.group(4);

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
    String? firstName;
    String? lastName;
    String? rawName;
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
    String? suffix;
    final notes = <String>[];
    final sharedNoteIds = <String>[];
    final birthSources = <SourceCitation>[];
    final deathSources = <SourceCitation>[];
    final burialSources = <SourceCitation>[];
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "NAME":
          if (rawName != null) break;
          rawName = child.valueWithChildren;
          final val = rawName;
          if (val.contains("/")) {
            final parts = val.split("/");
            firstName = parts[0].trim();
            if (parts.length > 1) {
              lastName = parts[1].trim();
            }
            if (parts.length > 2) {
              suffix = parts[2].trim();
            }
          } else {
            firstName = val;
            lastName = "";
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
            if (sub.tag == "NSFX") {
              suffix = sub.valueWithChildren;
            }
          }
          break;
        case "NICK":
          if (nickname != null) break;
          nickname = child.valueWithChildren;
          break;
        case "ALIA":
          if (alias != null) break;
          alias = child.valueWithChildren;
          break;
        case "SEX":
          if (sex != null) break;
          sex = GedcomStringUtils.unescapeText(child.value);
          break;
        case "BIRT":
          if (birthDate != null || birthPlace != null) break;
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              birthDate = GedcomStringUtils.unescapeText(sub.value);
            }
            if (sub.tag == "PLAC") {
              birthPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              birthSources.add(_parseSourceCitation(sub));
            }
          }
          break;
        case "DEAT":
          if (deathDate != null || deathPlace != null) break;
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              deathDate = GedcomStringUtils.unescapeText(sub.value);
            }
            if (sub.tag == "PLAC") {
              deathPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              deathSources.add(_parseSourceCitation(sub));
            }
          }
          break;
        case "BURI":
          if (burialDate != null || burialPlace != null) break;
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              burialDate = GedcomStringUtils.unescapeText(sub.value);
            }
            if (sub.tag == "PLAC") {
              burialPlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              burialSources.add(_parseSourceCitation(sub));
            }
          }
          break;
        case "OCCU":
          occupation = child.valueWithChildren;
          break;
        case "NOTE":
          notes.add(child.valueWithChildren);
          break;
        case "SNOTE":
          if (child.value != null) {
            sharedNoteIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
      }
    }

    return Person(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      firstName: firstName ?? "",
      lastName: lastName ?? "",
      rawName: rawName,
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
      suffix: suffix,
      notes: notes,
      sharedNoteIds: sharedNoteIds,
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
    final sharedNoteIds = <String>[];
    final marriageSources = <SourceCitation>[];
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "HUSB":
          husbandId = GedcomStringUtils.unescapePointer(child.value);
          break;
        case "WIFE":
          wifeId = GedcomStringUtils.unescapePointer(child.value);
          break;
        case "CHIL":
          if (child.value != null) {
            childrenIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
        case "MARR":
          if (marriageDate != null || marriagePlace != null) break;
          for (final sub in child.children) {
            if (sub.tag == "DATE") {
              marriageDate = GedcomStringUtils.unescapeText(sub.value);
            }
            if (sub.tag == "PLAC") {
              marriagePlace = sub.valueWithChildren;
            }
            if (sub.tag == "SOUR") {
              marriageSources.add(_parseSourceCitation(sub));
            }
          }
          break;
        case "NOTE":
          notes.add(child.valueWithChildren);
          break;
        case "SNOTE":
          if (child.value != null) {
            sharedNoteIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
      }
    }

    return Family(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      husbandId: husbandId,
      wifeId: wifeId,
      childrenIds: childrenIds,
      marriageDate: marriageDate,
      marriagePlace: marriagePlace,
      notes: notes,
      sharedNoteIds: sharedNoteIds,
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
    final notes = <String>[];
    final sharedNoteIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "TITL":
          if (title.isNotEmpty) break;
          title = child.valueWithChildren;
          break;
        case "AUTH":
          if (author != null) break;
          author = child.valueWithChildren;
          break;
        case "PUBL":
          if (publicationInfo != null) break;
          publicationInfo = child.valueWithChildren;
          break;
        case "REPO":
          if (repositoryId != null) break;
          repositoryId = child.value;
          break;
        case "TEXT":
          if (text != null) break;
          text = child.valueWithChildren;
          break;
        case "NOTE":
          notes.add(child.valueWithChildren);
          break;
        case "SNOTE":
          if (child.value != null) {
            sharedNoteIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
      }
    }
    return Source(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      title: title,
      author: author,
      publicationInfo: publicationInfo,
      repositoryId: GedcomStringUtils.unescapePointer(repositoryId),
      text: text,
      notes: notes,
      sharedNoteIds: sharedNoteIds,
      nodes: node.children,
    );
  }

  Repository _parseRepository(GedcomNode node) {
    var name = "";
    String? address;
    String? phone;
    String? email;
    String? website;
    final notes = <String>[];
    final sharedNoteIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "NAME":
          name = child.valueWithChildren;
          break;
        case "ADDR":
          if (address != null) break;
          address = child.valueWithChildren;
          break;
        case "PHON":
          if (phone != null) break;
          phone = GedcomStringUtils.unescapeText(child.value);
          break;
        case "EMAIL":
          if (email != null) break;
          email = GedcomStringUtils.unescapeText(child.value);
          break;
        case "WWW":
          if (website != null) break;
          website = GedcomStringUtils.unescapeText(child.value);
          break;
        case "NOTE":
          notes.add(child.valueWithChildren);
          break;
        case "SNOTE":
          if (child.value != null) {
            sharedNoteIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
      }
    }
    return Repository(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      name: name,
      address: address,
      phone: phone,
      email: email,
      website: website,
      notes: notes,
      sharedNoteIds: sharedNoteIds,
      nodes: node.children,
    );
  }

  Media _parseMedia(GedcomNode node) {
    final files = <MediaFile>[];
    String? title;
    String? blobData;
    final notes = <String>[];
    final sharedNoteIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "FILE":
          final path = GedcomStringUtils.unescapeText(child.value) ?? "";
          String? format;
          for (final sub in child.children) {
            if (sub.tag == "FORM") {
              format = GedcomStringUtils.unescapeText(sub.value);
            }
          }
          files.add(MediaFile(path: path, format: format));
          break;
        case "FORM":
          if (files.isEmpty) {
            files.add(MediaFile(
                path: "", format: GedcomStringUtils.unescapeText(child.value)));
          } else {
            // If we already have files, this FORM might be for the first one if it didn't have one
            // but usually FORM follows FILE. In GEDCOM 5.5 BLOB, FORM is a child of OBJE.
            final first = files.first;
            files[0] = MediaFile(
                path: first.path,
                format: GedcomStringUtils.unescapeText(child.value));
          }
          break;
        case "TITL":
          title = child.valueWithChildren;
          break;
        case "NOTE":
          notes.add(child.valueWithChildren);
          break;
        case "SNOTE":
          if (child.value != null) {
            sharedNoteIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
        case "BLOB":
          blobData = child.valueWithChildren;
          break;
      }
    }
    return Media(
      id: GedcomStringUtils.unescapePointer(node.xref)!,
      files: files,
      title: title,
      notes: notes,
      sharedNoteIds: sharedNoteIds,
      blobData: blobData,
      nodes: node.children,
    );
  }

  SourceCitation _parseSourceCitation(GedcomNode node) {
    final sourceId = GedcomStringUtils.unescapePointer(node.value) ?? "";
    String? page;
    String? quality;
    String? text;
    final mediaIds = <String>[];

    for (final child in node.children) {
      switch (child.tag) {
        case "PAGE":
          page = child.valueWithChildren;
          break;
        case "QUAY":
          quality = GedcomStringUtils.unescapeText(child.value);
          break;
        case "DATA":
          for (final sub in child.children) {
            if (sub.tag == "TEXT") {
              text = sub.valueWithChildren;
            }
          }
          break;
        case "OBJE":
          if (child.value != null) {
            mediaIds.add(GedcomStringUtils.unescapePointer(child.value)!);
          }
          break;
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
