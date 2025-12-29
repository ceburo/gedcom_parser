import 'package:gedcom_parser/gedcom_parser.dart';

void main() {
  // A simple GEDCOM content as a list of lines
  final gedcomLines = [
    '0 HEAD',
    '1 CHAR UTF-8',
    '1 GEDC',
    '2 VERS 5.5.1',
    '2 FORM LINEAGE-LINKED',
    '0 @I1@ INDI',
    '1 NAME John /Doe/',
    '1 GIVN John',
    '1 SURN Doe',
    '1 SEX M',
    '1 BIRT',
    '2 DATE 1 JAN 1900',
    '2 PLAC New York, USA',
    '0 @I2@ INDI',
    '1 NAME Jane /Smith/',
    '1 GIVN Jane',
    '1 SURN Smith',
    '1 SEX F',
    '0 @F1@ FAM',
    '1 HUSB @I1@',
    '1 WIFE @I2@',
    '1 MARR',
    '2 DATE 1 JAN 1925',
    '0 TRLR',
  ];

  // Initialize the parser
  final parser = GedcomParser();

  // Parse the lines
  final data = parser.parseLines(gedcomLines);

  // Access the parsed data
  print('Parsed ${data.persons.length} persons and ${data.families.length} families.');

  // Print details of each person
  for (final person in data.persons.values) {
    print('Person: ${person.fullName} (${person.sex})');
    if (person.birthDate != null) {
      print('  Born: ${person.birthDate} at ${person.birthPlace}');
    }
  }

  // Print details of each family
  for (final family in data.families.values) {
    final husband = data.persons[family.husbandId];
    final wife = data.persons[family.wifeId];
    print('Family: ${husband?.fullName} & ${wife?.fullName}');
    if (family.marriageDate != null) {
      print('  Married: ${family.marriageDate}');
    }
  }
}
