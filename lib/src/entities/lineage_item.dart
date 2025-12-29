import 'package:gedcom_parser/src/entities/person.dart';
import 'package:equatable/equatable.dart';

class LineageItem extends Equatable {
  final int sosaNumber;
  final Person person;
  final int generation;

  const LineageItem({
    required this.sosaNumber,
    required this.person,
    required this.generation,
  });

  @override
  List<Object?> get props => [sosaNumber, person, generation];
}
