import 'package:equatable/equatable.dart';

/// يمثل جلسة اتصال آمنة ومصادق عليها مع خادم Traccar.
/// هذا النموذج لا يحفظ أي كلمات مرور، ويقوم بتنقيح بيانات الاعتماد عند الطباعة للحماية.
class AuthSession extends Equatable {
  /// أصل الخادم (Origin) بصيغة scheme://host:port لضمان عدم تسريب الجلسة لخادم آخر
  final String serverOrigin;
  
  /// القيمة السرية لملف تعريف الارتباط (JSESSIONID) أو الرمز
  final String sessionCredential;
  
  /// بيانات المستخدم المستردة من الخادم (User Model JSON)
  final Map<String, dynamic> userMetadata;

  /// وقت إنشاء الجلسة محلياً
  final DateTime createdAt;

  const AuthSession({
    required this.serverOrigin,
    required this.sessionCredential,
    required this.userMetadata,
    required this.createdAt,
  });

  /// إنشاء جلسة جديدة مع طابع زمني تلقائي
  factory AuthSession.create({
    required String serverOrigin,
    required String sessionCredential,
    required Map<String, dynamic> userMetadata,
  }) {
    return AuthSession(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      userMetadata: userMetadata,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// التحقق مما إذا كانت الجلسة تنتمي لخادم معين
  bool belongsTo(String origin) {
    return serverOrigin.toLowerCase() == origin.toLowerCase();
  }

  @override
  List<Object?> get props => [serverOrigin, userMetadata, createdAt];

  /// نمنع طباعة `sessionCredential` لحماية الخصوصية والأمان في Logs
  @override
  String toString() {
    return 'AuthSession(serverOrigin: $serverOrigin, credential: [REDACTED], createdAt: $createdAt, userMetadata: $userMetadata)';
  }

  // دعم التحويل لـ JSON والحفظ الآمن
  Map<String, dynamic> toJson() {
    return {
      'serverOrigin': serverOrigin,
      'sessionCredential': sessionCredential,
      'userMetadata': userMetadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      serverOrigin: json['serverOrigin'] as String,
      sessionCredential: json['sessionCredential'] as String,
      userMetadata: Map<String, dynamic>.from(json['userMetadata'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
