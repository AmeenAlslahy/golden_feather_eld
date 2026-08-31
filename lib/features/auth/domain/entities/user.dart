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
    // Traccar API returns id as int, name, email, administrator boolean
    final idValue = json['id']?.toString() ?? '';
    final nameValue = json['name']?.toString() ?? json['fullName']?.toString() ?? '';
    final emailValue = json['email']?.toString() ?? json['username']?.toString() ?? nameValue;
    
    // Determine role
    UserRole userRole = UserRole.fieldWorker;
    if (json['administrator'] == true) {
      userRole = UserRole.admin;
    } else if (json['role'] != null) {
      userRole = UserRole.fromCode(json['role'] as String);
    }

    final isActive = json['disabled'] != null ? !(json['disabled'] as bool) : (json['isActive'] as bool? ?? true);

    return User(
      id: idValue,
      username: emailValue,
      email: emailValue,
      fullName: nameValue,
      phone: json['phone']?.toString(),
      role: userRole,
      isActive: isActive,
      lastLogin: json['lastLogin'] != null ? DateTime.tryParse(json['lastLogin'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
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



