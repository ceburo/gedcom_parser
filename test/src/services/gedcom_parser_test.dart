import 'package:gedcom_parser/src/services/gedcom_parser.dart';
import 'package:gedcom_parser/src/services/gedcom_exporter.dart';
import 'package:gedcom_parser/src/entities/source_citation.dart';
import 'package:test/test.dart';

void main() {
  late GedcomParser parser;
  late GedcomExporter exporter;

  setUp(() {
    parser = GedcomParser();
    exporter = GedcomExporter();
  });

  test('should parse and export media with BLOB data (lossless)', () {
    final lines = [
      "0 @O1@ OBJE",
      "1 FORM jpg",
      "1 TITL A picture",
      "1 BLOB",
      "2 CONT /9j/4AAQSkZJRgABAQEASABIAAD/4QA6RXhpZgAATU0AKgAAAAgAAwEAAAMAAAABAAEAAA",
      "2 CONT EbAAEAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG",
    ];

    final data = parser.parseLines(lines);
    final exported = exporter.export(data);

    expect(exported, contains("1 BLOB"));
    expect(
        exported,
        contains(
            "2 CONT /9j/4AAQSkZJRgABAQEASABIAAD/4QA6RXhpZgAATU0AKgAAAAgAAwEAAAMAAAABAAEAAA"));
    expect(
        exported,
        contains(
            "2 CONT EbAAEAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG"));
  });

  test('should parse a simple individual', () {
    final lines = ["0 @I1@ INDI", "1 NAME John /Doe/", "1 SEX M"];

    final data = parser.parseLines(lines);

    expect(data.persons.length, 1);
    final person = data.persons['I1'];
    expect(person, isNotNull);
    expect(person!.firstName, "John");
    expect(person.lastName, "Doe");
    expect(person.sex, "M");
  });

  test('should parse nested events', () {
    final lines = [
      "0 @I1@ INDI",
      "1 BIRT",
      "2 DATE 1 JAN 1980",
      "2 PLAC Springfield",
    ];

    final data = parser.parseLines(lines);

    final person = data.persons['I1'];
    expect(person!.birthDate, "1 JAN 1980");
    expect(person.birthPlace, "Springfield");
  });

  test('should parse media with BLOB data (GEDCOM 5.5)', () {
    final lines = [
      "0 @O1@ OBJE",
      "1 FORM jpg",
      "1 TITL A picture",
      "1 BLOB",
      "2 CONT /9j/4AAQSkZJRgABAQEASABIAAD/4QA6RXhpZgAATU0AKgAAAAgAAwEAAAMAAAABAAEAAA",
      "2 CONT EbAAEAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG",
    ];

    final data = parser.parseLines(lines);

    expect(data.media.length, 1);
    final media = data.media['O1'];
    expect(media, isNotNull);
    expect(media!.format, "jpg");
    expect(media.title, "A picture");
    expect(
        media.blobData,
        contains(
            "/9j/4AAQSkZJRgABAQEASABIAAD/4QA6RXhpZgAATU0AKgAAAAgAAwEAAAMAAAABAAEAAA"));
    expect(
        media.blobData,
        contains(
            "EbAAEAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG"));

    // Check decoded bytes
    expect(media.blobBytes, isNotNull);
    expect(media.blobBytes!.length, greaterThan(0));
  });

  test('should parse family and link children', () {
    final lines = [
      "0 @I1@ INDI", // Father
      "1 NAME Father",
      "0 @I2@ INDI", // Mother
      "1 NAME Mother",
      "0 @I3@ INDI", // Child
      "1 NAME Child",
      "0 @F1@ FAM",
      "1 HUSB @I1@",
      "1 WIFE @I2@",
      "1 CHIL @I3@",
    ];

    final data = parser.parseLines(lines);

    expect(data.families.length, 1);
    final family = data.families['F1'];
    expect(family!.husbandId, "I1");
    expect(family.wifeId, "I2");
    expect(family.childrenIds, ["I3"]);

    // Check childToFamilyId map
    expect(data.childToFamilyId['I3'], "F1");
  });

  test('should handle empty lines and comments gracefully', () {
    final lines = [
      "",
      "0 @I1@ INDI",
      "1 NAME John /Doe/",
      "   ", // whitespace line
    ];

    final data = parser.parseLines(lines);
    expect(data.persons.length, 1);
  });

  test('should parse middle names, nickname and alias', () {
    final lines = [
      "0 @I1@ INDI",
      "1 NAME John William /Doe/",
      "2 GIVN John William",
      "2 SURN Doe",
      "1 NICK Johnny",
      "1 ALIA J-Doe",
    ];

    final data = parser.parseLines(lines);

    final person = data.persons['I1'];
    expect(person!.firstName, "John");
    expect(person.middleNames, "William");
    expect(person.nickname, "Johnny");
    expect(person.alias, "J-Doe");
  });

  test('should parse nested structures with multiple levels', () {
    final lines = [
      "0 @I1@ INDI",
      "1 BIRT",
      "2 DATE 1 JAN 1900",
      "2 PLAC Paris, France",
      "2 SOUR @S1@",
      "3 PAGE 42",
      "1 DEAT",
      "2 DATE 1 JAN 1980",
      "2 PLAC Lyon, France",
      "2 SOUR @S2@",
      "1 BURI",
      "2 DATE 5 JAN 1980",
      "2 PLAC Lyon, France",
    ];

    final data = parser.parseLines(lines);

    final person = data.persons['I1'];
    expect(person!.birthDate, "1 JAN 1900");
    expect(person.birthPlace, "Paris, France");
    expect(person.birthSources, [
      const SourceCitation(sourceId: "S1", page: "42"),
    ]);
    expect(person.deathDate, "1 JAN 1980");
    expect(person.deathPlace, "Lyon, France");
    expect(person.deathSources, [const SourceCitation(sourceId: "S2")]);
    expect(person.burialDate, "5 JAN 1980");
    expect(person.burialPlace, "Lyon, France");
  });

  test('should parse family with marriage details', () {
    final lines = [
      "0 @F1@ FAM",
      "1 MARR",
      "2 DATE 10 JUN 1950",
      "2 PLAC London, UK",
    ];

    final data = parser.parseLines(lines);

    final family = data.families['F1'];
    expect(family!.marriageDate, "10 JUN 1950");
    expect(family.marriagePlace, "London, UK");
  });

  test('should parse occupation', () {
    final lines = ["0 @I1@ INDI", "1 NAME John /Doe/", "1 OCCU Baker"];

    final data = parser.parseLines(lines);

    final person = data.persons['I1'];
    expect(person!.occupation, "Baker");
  });

  test('should keep last occupation if multiple OCCU tags', () {
    final lines = [
      "0 @I1@ INDI",
      "1 NAME John /Doe/",
      "1 OCCU Baker",
      "1 OCCU Farmer",
    ];

    final data = parser.parseLines(lines);

    final person = data.persons['I1'];
    expect(person!.occupation, "Farmer");
  });
}
