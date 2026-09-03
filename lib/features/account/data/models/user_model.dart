import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.admin,
    required super.map,
    required super.language,
    required super.attributes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      admin: json['admin'] as bool? ?? false,
      map: json['map'] as String? ?? 'osm',
      language: json['language'] as String? ?? 'en',
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'admin': admin,
      'map': map,
      'language': language,
      'attributes': attributes,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      admin: entity.admin,
      map: entity.map,
      language: entity.language,
      attributes: entity.attributes,
    );
  }
}
