import 'package:gedcom_parser/src/entities/shared_note.dart';
import 'package:gedcom_parser/gedcom_parser.dart';
import 'package:gedcom_parser/src/utils/gedcom_string_utils.dart';

/// Service responsible for synchronizing structured entities (Person, Family)
/// with their underlying [GedcomNode]s to ensure lossless export.
class GedcomSyncService {
  /// Synchronizes a [GedcomData] object by updating its root nodes
  /// with the structured data from persons and families.
  GedcomData syncGedcomData(GedcomData data) {
    // 1. Remove nodes for entities that no longer exist
    var updatedNodes = data.nodes.where((node) {
      final xref = GedcomStringUtils.unescapePointer(node.xref);
      if (xref == null) return true;

      if (node.tag == "INDI") return data.persons.containsKey(xref);
      if (node.tag == "FAM") return data.families.containsKey(xref);
      if (node.tag == "SOUR") return data.sources.containsKey(xref);
      if (node.tag == "REPO") return data.repositories.containsKey(xref);
      if (node.tag == "OBJE") return data.media.containsKey(xref);
      if (node.tag == "SNOTE") return data.sharedNotes.containsKey(xref);
      return true;
    }).toList();

    // 2. Sync all persons
    for (final person in data.persons.values) {
      final personNodes = syncPersonNodes(person);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "INDI",
        person.id,
        personNodes,
      );
    }

    // 3. Sync all families
    for (final family in data.families.values) {
      final familyNodes = syncFamilyNodes(family);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "FAM",
        family.id,
        familyNodes,
      );
    }

    // 4. Sync all sources
    for (final source in data.sources.values) {
      final sourceNodes = syncSourceNodes(source);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "SOUR",
        source.id,
        sourceNodes,
      );
    }

    // 5. Sync all repositories
    for (final repo in data.repositories.values) {
      final repoNodes = syncRepositoryNodes(repo);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "REPO",
        repo.id,
        repoNodes,
      );
    }

    // 6. Sync all media
    for (final media in data.media.values) {
      final mediaNodes = syncMediaNodes(media);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "OBJE",
        media.id,
        mediaNodes,
      );
    }

    // 7. Sync all shared notes
    for (final note in data.sharedNotes.values) {
      final noteNode = syncSharedNoteNode(note);
      updatedNodes = _updateRootNode(
        updatedNodes,
        "SNOTE",
        note.id,
        noteNode.children,
        value: noteNode.value,
      );
    }

    return data.copyWith(nodes: updatedNodes);
  }

  /// Synchronizes a single [Person] within [GedcomData].
  GedcomData syncPerson(GedcomData data, String personId) {
    final person = data.persons[personId];
    if (person == null) {
      return data;
    }

    final personNodes = syncPersonNodes(person);
    final updatedNodes = _updateRootNode(
      data.nodes,
      "INDI",
      person.id,
      personNodes,
    );

    return data.copyWith(nodes: updatedNodes);
  }

  /// Synchronizes a single [Family] within [GedcomData].
  GedcomData syncFamily(GedcomData data, String familyId) {
    final family = data.families[familyId];
    if (family == null) {
      return data;
    }

    final familyNodes = syncFamilyNodes(family);
    final updatedNodes = _updateRootNode(
      data.nodes,
      "FAM",
      family.id,
      familyNodes,
    );

    return data.copyWith(nodes: updatedNodes);
  }

  List<GedcomNode> _updateRootNode(
    List<GedcomNode> nodes,
    String tag,
    String id,
    List<GedcomNode> children, {
    String? value,
  }) {
    final index = nodes.indexWhere(
      (n) => n.tag == tag && GedcomStringUtils.unescapePointer(n.xref) == id,
    );
    if (index != -1) {
      final updatedNode = nodes[index].copyWith(
        value: value ?? nodes[index].value,
        children: children,
      );
      return List<GedcomNode>.from(nodes)..[index] = updatedNode;
    }
    // Add new root node if not found
    final newNode = GedcomNode(
      level: 0,
      tag: tag,
      xref: GedcomStringUtils.escapePointer(id),
      value: value,
      children: children,
    );
    return [...nodes, newNode];
  }

  /// Synchronizes a [Person] with its [GedcomNode]s.
  List<GedcomNode> syncPersonNodes(Person person) {
    var nodes = List<GedcomNode>.from(person.nodes);

    // Sync Name
    if (person.firstName.isNotEmpty ||
        person.lastName.isNotEmpty ||
        nodes.any((n) => n.tag == "NAME")) {
      nodes = _updateNameNode(
        nodes,
        person,
      );
    }

    // Sync Nickname
    nodes = _updateSimpleNode(nodes, "NICK", person.nickname, level: 1);

    // Sync Alias
    nodes =
        _updateSimpleNode(nodes, "ALIA", person.alias, level: 1, isXref: true);

    // Sync Sex
    if (person.sex != "U" || nodes.any((n) => n.tag == "SEX")) {
      nodes = _updateSimpleNode(nodes, "SEX", person.sex, level: 1);
    }

    // Sync Birth
    nodes = _updateEventNode(
      nodes,
      "BIRT",
      person.birthDate,
      person.birthPlace,
      person.birthSources,
      level: 1,
    );

    // Sync Death
    nodes = _updateEventNode(
      nodes,
      "DEAT",
      person.deathDate,
      person.deathPlace,
      person.deathSources,
      level: 1,
    );

    // Sync Burial
    nodes = _updateEventNode(
      nodes,
      "BURI",
      person.burialDate,
      person.burialPlace,
      person.burialSources,
      level: 1,
    );

    // Sync Occupation
    nodes = _updateSimpleNode(nodes, "OCCU", person.occupation, level: 1);

    // Sync Notes
    nodes = _updateNotes(nodes, person.notes, level: 1);

    // Sync Shared Notes
    nodes = _updateMultipleNodes(
      nodes,
      "SNOTE",
      person.sharedNoteIds,
      level: 1,
      isXref: true,
    );

    // Sync Media
    nodes = _updateMedia(nodes, person.mediaIds, level: 1);

    return nodes;
  }

  /// Synchronizes a [Family] with its [GedcomNode]s.
  List<GedcomNode> syncFamilyNodes(Family family) {
    var nodes = List<GedcomNode>.from(family.nodes);

    // Sync Husband
    nodes = _updateSimpleNode(
      nodes,
      "HUSB",
      family.husbandId,
      level: 1,
      isXref: true,
    );

    // Sync Wife
    nodes = _updateSimpleNode(
      nodes,
      "WIFE",
      family.wifeId,
      level: 1,
      isXref: true,
    );

    // Sync Children
    nodes = _updateMultipleNodes(
      nodes,
      "CHIL",
      family.childrenIds,
      level: 1,
      isXref: true,
    );

    // Sync Marriage
    nodes = _updateEventNode(
      nodes,
      "MARR",
      family.marriageDate,
      family.marriagePlace,
      family.marriageSources,
      level: 1,
    );

    // Sync Notes
    nodes = _updateNotes(nodes, family.notes, level: 1);

    // Sync Shared Notes
    nodes = _updateMultipleNodes(
      nodes,
      "SNOTE",
      family.sharedNoteIds,
      level: 1,
      isXref: true,
    );

    // Sync Media
    nodes = _updateMedia(nodes, family.mediaIds, level: 1);

    return nodes;
  }

  /// Synchronizes a [Source] with its [GedcomNode]s.
  List<GedcomNode> syncSourceNodes(Source source) {
    var nodes = List<GedcomNode>.from(source.nodes);

    nodes = _updateSimpleNode(nodes, "TITL", source.title, level: 1);
    nodes = _updateSimpleNode(nodes, "AUTH", source.author, level: 1);
    nodes = _updateSimpleNode(nodes, "PUBL", source.publicationInfo, level: 1);
    nodes = _updateSimpleNode(
      nodes,
      "REPO",
      source.repositoryId,
      level: 1,
      isXref: true,
    );
    nodes = _updateSimpleNode(nodes, "TEXT", source.text, level: 1);

    // Sync Notes
    nodes = _updateNotes(nodes, source.notes, level: 1);

    // Sync Shared Notes
    nodes = _updateMultipleNodes(
      nodes,
      "SNOTE",
      source.sharedNoteIds,
      level: 1,
      isXref: true,
    );

    return nodes;
  }

  /// Synchronizes a [Repository] with its [GedcomNode]s.
  List<GedcomNode> syncRepositoryNodes(Repository repo) {
    var nodes = List<GedcomNode>.from(repo.nodes);

    nodes = _updateSimpleNode(nodes, "NAME", repo.name, level: 1);
    nodes = _updateSimpleNode(nodes, "ADDR", repo.address, level: 1);
    nodes = _updateSimpleNode(nodes, "PHON", repo.phone, level: 1);
    nodes = _updateSimpleNode(nodes, "EMAIL", repo.email, level: 1);
    nodes = _updateSimpleNode(nodes, "WWW", repo.website, level: 1);

    // Sync Notes
    nodes = _updateNotes(nodes, repo.notes, level: 1);

    // Sync Shared Notes
    nodes = _updateMultipleNodes(
      nodes,
      "SNOTE",
      repo.sharedNoteIds,
      level: 1,
      isXref: true,
    );

    return nodes;
  }

  /// Synchronizes a [Media] with its [GedcomNode]s.
  List<GedcomNode> syncMediaNodes(Media media) {
    var nodes = List<GedcomNode>.from(media.nodes);

    // Sync Files
    nodes = _updateMediaFiles(nodes, media.files, level: 1);

    nodes = _updateSimpleNode(nodes, "TITL", media.title, level: 1);
    nodes = _updateSimpleNode(nodes, "BLOB", media.blobData, level: 1);

    // Sync Notes
    nodes = _updateNotes(nodes, media.notes, level: 1);

    // Sync Shared Notes
    nodes = _updateMultipleNodes(
      nodes,
      "SNOTE",
      media.sharedNoteIds,
      level: 1,
      isXref: true,
    );

    return nodes;
  }

  List<GedcomNode> _updateMediaFiles(
    List<GedcomNode> nodes,
    List<MediaFile> files, {
    required int level,
  }) {
    final result = <GedcomNode>[];
    var fileIndex = 0;

    for (final node in nodes) {
      if (node.tag == "FILE") {
        if (fileIndex < files.length) {
          final file = files[fileIndex];
          final updatedFileNode = node.copyWith(
            value: GedcomStringUtils.escapeText(file.path),
          );

          final updatedChildren = _updateSimpleNode(
            updatedFileNode.children,
            "FORM",
            file.format,
            level: level + 1,
          );
          result.add(updatedFileNode.copyWith(children: updatedChildren));
          fileIndex++;
        } else {
          // Skip (remove) extra existing nodes
        }
      } else {
        result.add(node);
      }
    }

    // Add remaining new files
    while (fileIndex < files.length) {
      final file = files[fileIndex];
      var fileNode = GedcomNode(
        level: level,
        tag: "FILE",
        value: GedcomStringUtils.escapeText(file.path),
      );
      if (file.format != null) {
        fileNode = fileNode.copyWith(
          children: [
            GedcomNode(
              level: level + 1,
              tag: "FORM",
              value: GedcomStringUtils.escapeText(file.format!),
            ),
          ],
        );
      }
      result.add(fileNode);
      fileIndex++;
    }

    return result;
  }

  List<GedcomNode> _updateNameNode(
    List<GedcomNode> nodes,
    Person person,
  ) {
    final nameValue = person.rawName ??
        "${person.firstName} ${person.middleNames ?? ''} /${person.lastName}/ ${person.suffix ?? ''}"
            .replaceAll("  ", " ")
            .trim();
    return _updateSimpleNode(nodes, "NAME", nameValue, level: 1);
  }

  List<GedcomNode> _updateSimpleNode(
    List<GedcomNode> nodes,
    String tag,
    String? value, {
    required int level,
    bool isXref = false,
  }) {
    final index = nodes.indexWhere((n) => n.tag == tag);
    if (value == null || value.isEmpty) {
      if (index != -1) {
        return List<GedcomNode>.from(nodes)..removeAt(index);
      }
      return nodes;
    }

    final nodeValue = isXref
        ? GedcomStringUtils.escapePointer(value)
        : GedcomStringUtils.escapeText(value);

    if (index != -1) {
      final updatedNode =
          _setNodeValue(nodes[index], nodeValue, isXref: isXref);
      return List<GedcomNode>.from(nodes)..[index] = updatedNode;
    } else {
      final newNode = _setNodeValue(
        GedcomNode(level: level, tag: tag),
        nodeValue,
        isXref: isXref,
      );
      return [...nodes, newNode];
    }
  }

  List<GedcomNode> _updateMultipleNodes(
    List<GedcomNode> nodes,
    String tag,
    List<String> values, {
    required int level,
    bool isXref = false,
  }) {
    final result = <GedcomNode>[];
    var valueIndex = 0;

    for (final node in nodes) {
      if (node.tag == tag) {
        if (valueIndex < values.length) {
          final value = values[valueIndex];
          final nodeValue = isXref
              ? GedcomStringUtils.escapePointer(value)
              : GedcomStringUtils.escapeText(value);
          result.add(_setNodeValue(node, nodeValue, isXref: isXref));
          valueIndex++;
        } else {
          // If we only have one value in the entity, keep extra nodes to be lossless.
          // This handles cases like multiple MARR or ALIA tags where our entity
          // model only stores the first one.
          if (values.length == 1) {
            result.add(node);
          }
          // Otherwise, skip (remove) extra existing nodes
        }
      } else {
        result.add(node);
      }
    }

    // Add remaining new values
    while (valueIndex < values.length) {
      final value = values[valueIndex];
      final nodeValue = isXref
          ? GedcomStringUtils.escapePointer(value)
          : GedcomStringUtils.escapeText(value);
      result.add(_setNodeValue(
        GedcomNode(level: level, tag: tag),
        nodeValue,
        isXref: isXref,
      ));
      valueIndex++;
    }

    return result;
  }

  List<GedcomNode> _updateEventNode(
    List<GedcomNode> nodes,
    String tag,
    String? date,
    String? place,
    List<SourceCitation> sources, {
    required int level,
  }) {
    final index = nodes.indexWhere((n) => n.tag == tag);

    if (date == null && place == null && sources.isEmpty) {
      if (index != -1) {
        return List<GedcomNode>.from(nodes)..removeAt(index);
      }
      return nodes;
    }

    GedcomNode eventNode;
    if (index != -1) {
      eventNode = nodes[index];
    } else {
      eventNode = GedcomNode(level: level, tag: tag);
    }

    var children = List<GedcomNode>.from(eventNode.children);
    children = _updateSimpleNode(children, "DATE", date, level: level + 1);
    children = _updateSimpleNode(children, "PLAC", place, level: level + 1);
    children = _updateSources(children, sources, level: level + 1);

    final updatedEvent = eventNode.copyWith(children: children);

    if (index != -1) {
      return List<GedcomNode>.from(nodes)..[index] = updatedEvent;
    } else {
      return [...nodes, updatedEvent];
    }
  }

  List<GedcomNode> _updateNotes(
    List<GedcomNode> nodes,
    List<String> notes, {
    required int level,
  }) =>
      _updateMultipleNodes(nodes, "NOTE", notes, level: level);

  List<GedcomNode> _updateMedia(
    List<GedcomNode> nodes,
    List<String> mediaIds, {
    required int level,
  }) =>
      _updateMultipleNodes(nodes, "OBJE", mediaIds, level: level, isXref: true);

  List<GedcomNode> _updateSources(
    List<GedcomNode> nodes,
    List<SourceCitation> sources, {
    required int level,
  }) {
    final result = <GedcomNode>[];
    var sourceIndex = 0;

    for (final node in nodes) {
      if (node.tag == "SOUR") {
        if (sourceIndex < sources.length) {
          final citation = sources[sourceIndex];
          final sourceXref = GedcomStringUtils.escapePointer(citation.sourceId);

          var children = List<GedcomNode>.from(node.children);
          children = _updateSimpleNode(
            children,
            "PAGE",
            citation.page,
            level: level + 1,
          );
          children = _updateSimpleNode(
            children,
            "QUAY",
            citation.quality,
            level: level + 1,
          );

          // Handle DATA/TEXT
          if (citation.text != null) {
            final dataIndex = children.indexWhere((n) => n.tag == "DATA");
            GedcomNode dataNode;
            if (dataIndex != -1) {
              dataNode = children[dataIndex];
            } else {
              dataNode = GedcomNode(level: level + 1, tag: "DATA");
            }

            var dataChildren = List<GedcomNode>.from(dataNode.children);
            dataChildren = _updateSimpleNode(
              dataChildren,
              "TEXT",
              citation.text,
              level: level + 2,
            );

            final updatedData = dataNode.copyWith(children: dataChildren);
            if (dataIndex != -1) {
              children[dataIndex] = updatedData;
            } else {
              children.add(updatedData);
            }
          } else {
            children.removeWhere((n) => n.tag == "DATA");
          }

          children = _updateMultipleNodes(
            children,
            "OBJE",
            citation.mediaIds,
            level: level + 1,
            isXref: true,
          );

          result.add(node.copyWith(value: sourceXref, children: children));
          sourceIndex++;
        } else {
          // Skip (remove) extra existing nodes
        }
      } else {
        result.add(node);
      }
    }

    // Add remaining new sources
    while (sourceIndex < sources.length) {
      final citation = sources[sourceIndex];
      final sourceXref = GedcomStringUtils.escapePointer(citation.sourceId);

      var children = <GedcomNode>[];
      children = _updateSimpleNode(
        children,
        "PAGE",
        citation.page,
        level: level + 1,
      );
      children = _updateSimpleNode(
        children,
        "QUAY",
        citation.quality,
        level: level + 1,
      );

      if (citation.text != null) {
        var dataChildren = <GedcomNode>[];
        dataChildren = _updateSimpleNode(
          dataChildren,
          "TEXT",
          citation.text,
          level: level + 2,
        );
        children.add(
          GedcomNode(level: level + 1, tag: "DATA", children: dataChildren),
        );
      }

      children = _updateMultipleNodes(
        children,
        "OBJE",
        citation.mediaIds,
        level: level + 1,
        isXref: true,
      );

      result.add(
        GedcomNode(
          level: level,
          tag: "SOUR",
          value: sourceXref,
          children: children,
        ),
      );
      sourceIndex++;
    }

    return result;
  }

  /// Updates a node's value and handles CONT/CONC for multi-line strings.
  /// Preserves children that are not CONT or CONC.
  GedcomNode _setNodeValue(GedcomNode node, String value,
      {bool isXref = false}) {
    if (isXref) {
      return node.copyWith(value: value, children: node.children);
    }

    final lines = value.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0] : "";

    // Preserve non-CONT/CONC children
    final otherChildren =
        node.children.where((c) => c.tag != "CONT" && c.tag != "CONC").toList();
    final newChildren = <GedcomNode>[];

    for (var i = 1; i < lines.length; i++) {
      newChildren.add(
        GedcomNode(
          level: node.level + 1,
          tag: "CONT",
          value: GedcomStringUtils.escapeText(lines[i]),
        ),
      );
    }

    newChildren.addAll(otherChildren);

    return node.copyWith(
      value: GedcomStringUtils.escapeText(firstLine),
      children: newChildren,
    );
  }

  /// Synchronizes a [SharedNote] with its [GedcomNode]s.
  GedcomNode syncSharedNoteNode(SharedNote note) {
    final node = GedcomNode(
      level: 0,
      tag: "SNOTE",
      xref: GedcomStringUtils.escapePointer(note.id),
      children: note.nodes,
    );
    return _setNodeValue(node, note.text);
  }
}
