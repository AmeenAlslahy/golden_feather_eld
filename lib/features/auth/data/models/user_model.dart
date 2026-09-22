import 'package:golden_feather_eld/core/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    super.isActive = true,
    super.lastLogin,
    required super.createdAt,
    super.attributes = const {},
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      attributes: user.attributes,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json,
      {String? defaultEmail}) {
    // Use the real driver ID returned by the Traccar server (handles both int from API and String from storage)
    final idValue = json['id']?.toString() ?? '';
    final nameValue =
        json['name']?.toString() ?? json['fullName']?.toString() ?? '';
    final emailValue =
        json['email']?.toString() ?? json['username']?.toString() ?? nameValue;

    // Determine role
    UserRole userRole = UserRole.fieldWorker;
    if (json['administrator'] == true) {
      userRole = UserRole.admin;
    } else if (json['role'] != null) {
      userRole = UserRole.fromCode(json['role'].toString());
    }

    final disabled = json['disabled'];
    final bool isDisabled = disabled is bool
        ? disabled
        : (disabled is num ? disabled != 0 : false);
    final isActive = json['disabled'] != null
        ? !isDisabled
        : (json['isActive'] is bool ? (json['isActive'] as bool) : true);

    return UserModel(
      id: idValue,
      username: emailValue,
      email: emailValue, // defaultEmail logic can be handled here if needed
      fullName: nameValue,
      phone: json['phone']?.toString(),
      role: userRole,
      isActive: isActive,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
    );
  }

  factory UserModel.fromMetadata(Map<String, dynamic> metadata,
      {String? defaultEmail}) {
    return UserModel.fromJson(metadata, defaultEmail: defaultEmail);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.code,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attributes': attributes,
    };
  }
}
