import 'package:gedcom_parser/src/entities/gedcom_data.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';
import 'package:gedcom_parser/src/services/gedcom_sync_service.dart';
import 'package:gedcom_parser/src/utils/gedcom_string_utils.dart';

/// A service for exporting [GedcomData] back to GEDCOM format.
class GedcomExporter {
  /// Exports the given [data] to a GEDCOM string.
  ///
  /// If the [data] contains raw [GedcomNode]s, they will be used for export
  /// to ensure no data is lost. Otherwise, a standard GEDCOM 7.0 file
  /// will be generated from the structured entities.
  String export(GedcomData data) {
    if (data.nodes.isNotEmpty) {
      final syncedData = GedcomSyncService().syncGedcomData(data);
      final buffer = StringBuffer();
      for (final node in syncedData.nodes) {
        _writeNode(buffer, node);
      }
      return buffer.toString();
    }

    final buffer = StringBuffer();
    // ... fallback logic ...

    // Header
    buffer.writeln("0 HEAD");
    buffer.writeln("1 GEDC");
    buffer.writeln("2 VERS 7.0");
    buffer.writeln("1 SOUR AGES");
    buffer.writeln("2 VERS 1.0.0");

    // Individuals
    for (final person in data.persons.values) {
      buffer.writeln("0 @${person.id}@ INDI");
      final name = GedcomStringUtils.escapeText(
          "${person.firstName} /${person.lastName}/");
      buffer.writeln("1 NAME $name");
      buffer.writeln("1 SEX ${person.sex}");

      if (person.occupation != null) {
        buffer.writeln(
            "1 OCCU ${GedcomStringUtils.escapeText(person.occupation!)}");
      }

      for (final note in person.notes) {
        buffer.writeln("1 NOTE ${GedcomStringUtils.escapeText(note)}");
      }

      for (final noteId in person.sharedNoteIds) {
        buffer.writeln("1 SNOTE @$noteId@");
      }

      for (final mediaId in person.mediaIds) {
        buffer.writeln("1 OBJE @$mediaId@");
      }

      if (person.birthDate != null ||
          person.birthPlace != null ||
          person.birthSources.isNotEmpty) {
        buffer.writeln("1 BIRT");
        if (person.birthDate != null) {
          buffer.writeln("2 DATE ${person.birthDate}");
        }
        if (person.birthPlace != null) {
          buffer.writeln("2 PLAC ${person.birthPlace}");
        }
        for (final citation in person.birthSources) {
          _writeSourceCitation(buffer, 2, citation);
        }
      }

      if (person.deathDate != null ||
          person.deathPlace != null ||
          person.deathSources.isNotEmpty) {
        buffer.writeln("1 DEAT");
        if (person.deathDate != null) {
          buffer.writeln("2 DATE ${person.deathDate}");
        }
        if (person.deathPlace != null) {
          buffer.writeln("2 PLAC ${person.deathPlace}");
        }
        for (final citation in person.deathSources) {
          _writeSourceCitation(buffer, 2, citation);
        }
      }

      if (person.burialDate != null ||
          person.burialPlace != null ||
          person.burialSources.isNotEmpty) {
        buffer.writeln("1 BURI");
        if (person.burialDate != null) {
          buffer.writeln("2 DATE ${person.burialDate}");
        }
        if (person.burialPlace != null) {
          buffer.writeln("2 PLAC ${person.burialPlace}");
        }
        for (final citation in person.burialSources) {
          _writeSourceCitation(buffer, 2, citation);
        }
      }

      // FAMC (Family as Child)
      if (data.childToFamilyId.containsKey(person.id)) {
        buffer.writeln("1 FAMC @${data.childToFamilyId[person.id]}@");
      }

      // FAMS (Family as Spouse)
      for (final family in data.families.values) {
        if (family.husbandId == person.id || family.wifeId == person.id) {
          buffer.writeln("1 FAMS @${family.id}@");
        }
      }
    }

    // Families
    for (final family in data.families.values) {
      buffer.writeln("0 @${family.id}@ FAM");
      if (family.husbandId != null) {
        buffer.writeln("1 HUSB @${family.husbandId}@");
      }
      if (family.wifeId != null) {
        buffer.writeln("1 WIFE @${family.wifeId}@");
      }
      for (final childId in family.childrenIds) {
        buffer.writeln("1 CHIL @$childId@");
      }

      if (family.marriageDate != null ||
          family.marriagePlace != null ||
          family.marriageSources.isNotEmpty) {
        buffer.writeln("1 MARR");
        if (family.marriageDate != null) {
          buffer.writeln("2 DATE ${family.marriageDate}");
        }
        if (family.marriagePlace != null) {
          buffer.writeln("2 PLAC ${family.marriagePlace}");
        }
        for (final citation in family.marriageSources) {
          _writeSourceCitation(buffer, 2, citation);
        }
      }

      for (final note in family.notes) {
        buffer.writeln("1 NOTE ${GedcomStringUtils.escapeText(note)}");
      }

      for (final noteId in family.sharedNoteIds) {
        buffer.writeln("1 SNOTE @$noteId@");
      }

      for (final mediaId in family.mediaIds) {
        buffer.writeln("1 OBJE @$mediaId@");
      }
    }

    // Shared Notes
    for (final note in data.sharedNotes.values) {
      buffer.writeln(
          "0 @${note.id}@ SNOTE ${GedcomStringUtils.escapeText(note.text)}");
    }

    // Repositories
    for (final repo in data.repositories.values) {
      buffer.writeln("0 @${repo.id}@ REPO");
      buffer.writeln("1 NAME ${repo.name}");
      if (repo.address != null) {
        buffer.writeln("1 ADDR ${repo.address}");
      }
      if (repo.phone != null) {
        buffer.writeln("1 PHON ${repo.phone}");
      }
      if (repo.email != null) {
        buffer.writeln("1 EMAIL ${repo.email}");
      }
      if (repo.website != null) {
        buffer.writeln("1 WWW ${repo.website}");
      }
    }

    // Sources
    for (final source in data.sources.values) {
      buffer.writeln("0 @${source.id}@ SOUR");
      buffer.writeln("1 TITL ${source.title}");
      if (source.author != null) {
        buffer.writeln("1 AUTH ${source.author}");
      }
      if (source.publicationInfo != null) {
        buffer.writeln("1 PUBL ${source.publicationInfo}");
      }
      if (source.repositoryId != null) {
        buffer.writeln("1 REPO @${source.repositoryId}@");
      }
      if (source.text != null) {
        buffer.writeln("1 TEXT ${source.text}");
      }
    }

    // Media
    for (final m in data.media.values) {
      buffer.writeln("0 @${m.id}@ OBJE");
      buffer.writeln("1 FILE ${m.path}");
      if (m.format != null) {
        buffer.writeln("2 FORM ${m.format}");
      }
      if (m.title != null) {
        buffer.writeln("1 TITL ${m.title}");
      }
      for (final note in m.notes) {
        buffer.writeln("1 NOTE ${GedcomStringUtils.escapeText(note)}");
      }
      for (final noteId in m.sharedNoteIds) {
        buffer.writeln("1 SNOTE @$noteId@");
      }
    }

    // Trailer
    buffer.writeln("0 TRLR");

    return buffer.toString();
  }

  void _writeSourceCitation(
    StringBuffer buffer,
    int level,
    SourceCitation citation,
  ) {
    final sourceXref = GedcomStringUtils.escapePointer(citation.sourceId);
    buffer.writeln("$level SOUR $sourceXref");
    if (citation.page != null) {
      buffer.writeln(
          "${level + 1} PAGE ${GedcomStringUtils.escapeText(citation.page!)}");
    }
    if (citation.quality != null) {
      buffer.writeln(
          "${level + 1} QUAY ${GedcomStringUtils.escapeText(citation.quality!)}");
    }
    if (citation.text != null) {
      buffer.writeln("${level + 1} DATA");
      buffer.writeln(
          "${level + 2} TEXT ${GedcomStringUtils.escapeText(citation.text!)}");
    }
    for (final mediaId in citation.mediaIds) {
      buffer.writeln("${level + 1} OBJE @$mediaId@");
    }
  }

  void _writeNode(StringBuffer buffer, GedcomNode node) {
    buffer.write("${node.level} ");
    if (node.xref != null) {
      var xref = node.xref!;
      if (!xref.startsWith('@')) {
        xref = '@$xref@';
      }
      buffer.write("$xref ");
    }
    buffer.write(node.tag);
    if (node.value != null) {
      buffer.write(" ${node.value}");
    }
    buffer.writeln();
    for (final child in node.children) {
      _writeNode(buffer, child);
    }
  }
}
