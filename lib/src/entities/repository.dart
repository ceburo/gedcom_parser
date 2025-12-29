import 'package:equatable/equatable.dart';

/// Represents a repository (REPO) where sources are stored.
class Repository extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;

  const Repository({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
  });

  @override
  List<Object?> get props => [id, name, address, phone, email, website];

  Repository copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
  }) =>
      Repository(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
      };

  factory Repository.fromJson(Map<String, dynamic> json) => Repository(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
      );
}
