import 'package:equatable/equatable.dart';
import 'package:gedcom_parser/src/entities/gedcom_node.dart';

/// Represents a repository (REPO) where sources are stored.
class Repository extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final List<String> notes;
  final List<String> sharedNoteIds;

  /// The raw GEDCOM nodes for this repository.
  final List<GedcomNode> nodes;

  const Repository({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.notes = const [],
    this.sharedNoteIds = const [],
    this.nodes = const [],
  });

  @override
  List<Object?> get props =>
      [id, name, address, phone, email, website, notes, sharedNoteIds, nodes];

  Repository copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    List<String>? notes,
    List<String>? sharedNoteIds,
    List<GedcomNode>? nodes,
  }) =>
      Repository(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        notes: notes ?? this.notes,
        sharedNoteIds: sharedNoteIds ?? this.sharedNoteIds,
        nodes: nodes ?? this.nodes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'notes': notes,
        'sharedNoteIds': sharedNoteIds,
      };

  factory Repository.fromJson(Map<String, dynamic> json) => Repository(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        notes: (json['notes'] as List<dynamic>?)?.cast<String>() ?? [],
        sharedNoteIds:
            (json['sharedNoteIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
