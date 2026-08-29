import 'package:equatable/equatable.dart';

/// كيان المستخدم
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSupervisor => role == UserRole.supervisor;
  bool get isFieldWorker => role == UserRole.fieldWorker;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        phone,
        role,
        isActive,
        lastLogin,
        createdAt,
      ];

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
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      role: UserRole.fromCode(json['role'] as String? ?? 'field_worker'),
      isActive: json['isActive'] as bool? ?? true,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// أدوار المستخدمين
enum UserRole {
  admin('admin', 'مدير النظام'),
  supervisor('supervisor', 'مشرف'),
  fieldWorker('field_worker', 'موظف ميداني');

  final String code;
  final String arabicName;
  const UserRole(this.code, this.arabicName);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.fieldWorker,
    );
  }
}



