import 'package:equatable/equatable.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

/// يمثل جلسة اتصال آمنة ومصادق عليها مع خادم Traccar.
/// هذا النموذج لا يحفظ أي كلمات مرور، ويقوم بتنقيح بيانات الاعتماد عند الطباعة للحماية.
class AuthSession extends Equatable {
  /// أصل الخادم (Origin) بصيغة scheme://host:port لضمان عدم تسريب الجلسة لخادم آخر
  final String serverOrigin;

  /// القيمة السرية لملف تعريف الارتباط (JSESSIONID).
  final String sessionCredential;

  /// رمز Bearer الصادر من `POST /api/session/token`.
  ///
  /// مسارات `/api/eld/**` في عقد OpenAPI محمية بـ `BearerAuth` فقط، بينما
  /// `sessionCredential` هو كوكي Traccar. نحتفظ بالاثنين: الكوكي يخدم واجهات
  /// Traccar الأصلية (المواقع/الأحداث/WebSocket)، والرمز يخدم مسارات ELD.
  /// قد يكون `null` في جلسات قديمة مخزنة قبل إضافة الرمز.
  final String? bearerToken;

  /// كيان المستخدم
  final User user;

  /// وقت إنشاء الجلسة محلياً
  final DateTime createdAt;

  const AuthSession({
    required this.serverOrigin,
    required this.sessionCredential,
    required this.user,
    required this.createdAt,
    this.bearerToken,
  });

  /// إنشاء جلسة جديدة مع طابع زمني تلقائي
  factory AuthSession.create({
    required String serverOrigin,
    required String sessionCredential,
    required User user,
    String? bearerToken,
  }) {
    return AuthSession(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      user: user,
      createdAt: DateTime.now().toUtc(),
      bearerToken: bearerToken,
    );
  }

  AuthSession copyWithBearerToken(String? token) {
    return AuthSession(
      serverOrigin: serverOrigin,
      sessionCredential: sessionCredential,
      user: user,
      createdAt: createdAt,
      bearerToken: token,
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
    return 'AuthSession(serverOrigin: $serverOrigin, credential: [REDACTED], '
        'bearer: ${bearerToken == null ? 'none' : '[REDACTED]'}, '
        'createdAt: $createdAt, user: $user)';
  }
}
