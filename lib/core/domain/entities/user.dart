import 'package:equatable/equatable.dart';

/// كيان المستخدم
class User extends Equatable {
  /// رقم المستخدم
  final String id;

  /// اسم المستخدم
  final String username;

  /// الايميل
  final String email;

  /// الاسم الكامل
  final String fullName;

  /// رقم الهاتف
  final String? phone;

  /// الدور
  final UserRole role;

  /// نشط
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final Map<String, dynamic> attributes;

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
    this.attributes = const {},
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSupervisor => role == UserRole.supervisor;
  bool get isFieldWorker => role == UserRole.fieldWorker;

  /// جلب بيانات المستخدم
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
        attributes,
      ];
}

/// أدوار المستخدمين
enum UserRole {
  admin('admin'),
  supervisor('supervisor'),
  fieldWorker('field_worker');

  final String code;
  const UserRole(this.code);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.fieldWorker,
    );
  }
}
