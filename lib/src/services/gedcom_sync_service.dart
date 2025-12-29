import 'package:gedcom_parser/gedcom_parser.dart';

/// Service responsible for synchronizing structured entities (Person, Family)
/// with their underlying [GedcomNode]s to ensure lossless export.
class GedcomSyncService {
  /// Synchronizes a [GedcomData] object by updating its root nodes
  /// with the structured data from persons and families.
  GedcomData syncGedcomData(GedcomData data) {
    // 1. Remove nodes for persons/families that no longer exist
    var updatedNodes = data.nodes.where((node) {
      if (node.tag == "INDI" && node.xref != null) {
        return data.persons.containsKey(node.xref);
      }
      if (node.tag == "FAM" && node.xref != null) {
        return data.families.containsKey(node.xref);
      }
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
    List<GedcomNode> children,
  ) {
    final index = nodes.indexWhere((n) => n.tag == tag && n.xref == id);
    if (index != -1) {
      final updatedNode = nodes[index].copyWith(children: children);
      return List<GedcomNode>.from(nodes)..[index] = updatedNode;
    }
    // Add new root node if not found
    final newNode = GedcomNode(
      level: 0,
      tag: tag,
      xref: id,
      children: children,
    );
    return [...nodes, newNode];
  }

  /// Synchronizes a [Person] with its [GedcomNode]s.
  List<GedcomNode> syncPersonNodes(Person person) {
    var nodes = List<GedcomNode>.from(person.nodes);

    // Sync Name
    nodes = _updateNameNode(
      nodes,
      person.firstName,
      person.lastName,
      middleNames: person.middleNames,
    );

    // Sync Nickname
    nodes = _updateSimpleNode(nodes, "NICK", person.nickname, level: 1);

    // Sync Alias
    nodes = _updateSimpleNode(nodes, "ALIA", person.alias, level: 1);

    // Sync Sex
    nodes = _updateSimpleNode(nodes, "SEX", person.sex, level: 1);

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

    // Sync Media
    nodes = _updateMedia(nodes, family.mediaIds, level: 1);

    return nodes;
  }

  List<GedcomNode> _updateNameNode(
    List<GedcomNode> nodes,
    String firstName,
    String lastName, {
    String? middleNames,
  }) {
    final nameValue = "$firstName ${middleNames ?? ''} /$lastName/"
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

    final nodeValue =
        isXref ? (value.startsWith("@") ? value : "@$value@") : value;

    if (index != -1) {
      final updatedNode = _setNodeValue(nodes[index], nodeValue);
      return List<GedcomNode>.from(nodes)..[index] = updatedNode;
    } else {
      final newNode = _setNodeValue(
        GedcomNode(level: level, tag: tag),
        nodeValue,
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
          final nodeValue =
              isXref ? (value.startsWith("@") ? value : "@$value@") : value;
          result.add(_setNodeValue(node, nodeValue));
          valueIndex++;
        } else {
          // Skip (remove) extra existing nodes
        }
      } else {
        result.add(node);
      }
    }

    // Add remaining new values
    while (valueIndex < values.length) {
      final value = values[valueIndex];
      final nodeValue =
          isXref ? (value.startsWith("@") ? value : "@$value@") : value;
      result.add(_setNodeValue(GedcomNode(level: level, tag: tag), nodeValue));
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
          final sourceXref = citation.sourceId.startsWith("@")
              ? citation.sourceId
              : "@${citation.sourceId}@";

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
      final sourceXref = citation.sourceId.startsWith("@")
          ? citation.sourceId
          : "@${citation.sourceId}@";

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
  GedcomNode _setNodeValue(GedcomNode node, String value) {
    final lines = value.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0] : "";

    // Preserve non-CONT/CONC children
    final otherChildren =
        node.children.where((c) => c.tag != "CONT" && c.tag != "CONC").toList();
    final newChildren = [...otherChildren];

    for (var i = 1; i < lines.length; i++) {
      newChildren.add(
        GedcomNode(level: node.level + 1, tag: "CONT", value: lines[i]),
      );
    }

    return node.copyWith(value: firstLine, children: newChildren);
  }
}
