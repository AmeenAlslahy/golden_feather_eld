import 'package:equatable/equatable.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

/// يمثل جلسة اتصال آمنة ومصادق عليها مع خادم Traccar.
/// هذا النموذج لا يحفظ أي كلمات مرور، ويقوم بتنقيح بيانات الاعتماد عند الطباعة للحماية.
class AuthSession extends Equatable {
  /// أصل الخادم (Origin) بصيغة scheme://host:port لضمان عدم تسريب الجلسة لخادم آخر
  final String serverOrigin;

  /// القيمة السرية لملف تعريف الارتباط (JSESSIONID) أو الرمز
  final String sessionCredential;

  /// كيان المستخدم
  final User user;

  /// وقت إنشاء الجلسة محلياً
  final DateTime createdAt;

  const AuthSession({
    required this.serverOrigin,
    required this.sessionCredential,
    required this.user,
    required this.createdAt,
  });

  /// إنشاء جلسة جديدة مع طابع زمني تلقائي
  factory AuthSession.create({
    required String serverOrigin,
    required String sessionCredential,
    required User user,
  }) {
    return AuthSession(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      user: user,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// التحقق مما إذا كانت الجلسة تنتمي لخادم معين
  bool belongsTo(String origin) {
    return serverOrigin.toLowerCase() == origin.toLowerCase();
  }

  @override
  List<Object?> get props => [serverOrigin, user, createdAt];

  /// نمنع طباعة `sessionCredential` لحماية الخصوصية والأمان في Logs
  @override
  String toString() {
    return 'AuthSession(serverOrigin: $serverOrigin, credential: [REDACTED], createdAt: $createdAt, user: $user)';
  }
}
