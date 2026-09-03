import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final bool admin;
  final String map;
  final String language;
  final Map<String, dynamic> attributes;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.admin,
    required this.map,
    required this.language,
    required this.attributes,
  });

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    bool? admin,
    String? map,
    String? language,
    Map<String, dynamic>? attributes,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      admin: admin ?? this.admin,
      map: map ?? this.map,
      language: language ?? this.language,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        admin,
        map,
        language,
        attributes,
      ];
}
