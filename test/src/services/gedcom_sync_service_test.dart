import 'package:gedcom_parser/gedcom_parser.dart';
import 'package:test/test.dart';

void main() {
  late GedcomSyncService syncService;

  setUp(() {
    syncService = GedcomSyncService();
  });

  group('GedcomSyncService', () {
    test('should update NAME node when person name changes', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        nodes: [GedcomNode(level: 1, tag: 'NAME', value: 'Old /Name/')],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final nameNode = synchronizedNodes.firstWhere((n) => n.tag == 'NAME');

      expect(nameNode.value, 'John /Doe/');
    });

    test('should add NAME node if it does not exist', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        nodes: [],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final nameNode = synchronizedNodes.firstWhere((n) => n.tag == 'NAME');

      expect(nameNode.value, 'John /Doe/');
    });

    test('should update BIRT/PLAC node', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        birthPlace: 'Paris',
        nodes: [
          GedcomNode(
            level: 1,
            tag: 'BIRT',
            children: [GedcomNode(level: 2, tag: 'PLAC', value: 'Old Place')],
          ),
        ],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final birtNode = synchronizedNodes.firstWhere((n) => n.tag == 'BIRT');
      final placNode = birtNode.children.firstWhere((n) => n.tag == 'PLAC');

      expect(placNode.value, 'Paris');
    });

    test('should preserve unmapped nodes', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        nodes: [
          GedcomNode(level: 1, tag: 'NAME', value: 'John /Doe/'),
          GedcomNode(level: 1, tag: 'CUSTOM', value: 'Value'),
        ],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);

      expect(synchronizedNodes.any((n) => n.tag == 'CUSTOM'), isTrue);
      expect(
        synchronizedNodes.firstWhere((n) => n.tag == 'CUSTOM').value,
        'Value',
      );
    });

    test('should preserve unknown sub-nodes when updating a node', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        birthPlace: 'New Place',
        nodes: [
          GedcomNode(
            level: 1,
            tag: 'BIRT',
            children: [
              GedcomNode(level: 2, tag: 'PLAC', value: 'Old Place'),
              GedcomNode(level: 2, tag: '_CUSTOM_SUB', value: 'Keep Me'),
            ],
          ),
        ],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final birtNode = synchronizedNodes.firstWhere((n) => n.tag == 'BIRT');

      expect(
        birtNode.children.any((n) => n.tag == 'PLAC' && n.value == 'New Place'),
        isTrue,
      );
      expect(
        birtNode.children.any(
          (n) => n.tag == '_CUSTOM_SUB' && n.value == 'Keep Me',
        ),
        isTrue,
      );
    });

    test('should handle multi-line values with CONT', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        notes: ['Line 1\nLine 2'],
        nodes: [],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final noteNode = synchronizedNodes.firstWhere((n) => n.tag == 'NOTE');

      expect(noteNode.value, 'Line 1');
      expect(
        noteNode.children.any((n) => n.tag == 'CONT' && n.value == 'Line 2'),
        isTrue,
      );
    });

    test('should update multi-line values and preserve other children', () {
      const person = Person(
        id: 'I1',
        firstName: 'John',
        lastName: 'Doe',
        notes: ['New Line 1\nNew Line 2'],
        nodes: [
          GedcomNode(
            level: 1,
            tag: 'NOTE',
            value: 'Old Line 1',
            children: [
              GedcomNode(level: 2, tag: 'CONT', value: 'Old Line 2'),
              GedcomNode(level: 2, tag: '_UNKNOWN', value: 'Keep'),
            ],
          ),
        ],
      );

      final synchronizedNodes = syncService.syncPersonNodes(person);
      final noteNode = synchronizedNodes.firstWhere((n) => n.tag == 'NOTE');

      expect(noteNode.value, 'New Line 1');
      expect(
        noteNode.children.any(
          (n) => n.tag == 'CONT' && n.value == 'New Line 2',
        ),
        isTrue,
      );
      expect(
        noteNode.children.any((n) => n.tag == '_UNKNOWN' && n.value == 'Keep'),
        isTrue,
      );
      // Ensure old CONT is gone
      expect(noteNode.children.where((n) => n.tag == 'CONT').length, 1);
    });
  });
}
