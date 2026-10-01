import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/interceptors/auth_interceptor.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:golden_feather_eld/features/auth/domain/entities/auth_session.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// انحدار حرج: 401 على طلب خرج **بلا جلسة** (مثل طلب تهيئة الإعدادات عند
/// الإقلاع قبل اكتمال قراءة Keystore) كان يُعتبر «انتهاء جلسة» فيُمسح
/// التوكن المخزن عند كل إقلاع — فيُطلب من السائق تسجيل الدخول كل مرة.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _FakeAuthLocalDataSource localDataSource;
  var unauthenticatedFired = false;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    adapter = DioAdapter(dio: dio);
    localDataSource = _FakeAuthLocalDataSource();
    unauthenticatedFired = false;
    dio.interceptors.add(AuthInterceptor(
      localDataSource: localDataSource,
      backendType: 'traccar',
      onUnauthenticated: () => unauthenticatedFired = true,
    ));
  });

  test('401 without an attached session must NOT fire the logout event',
      () async {
    localDataSource.session = null; // لا جلسة مخزنة (أو القراءة لم تكتمل)
    adapter.onGet(
      '/eld/company-vehicles/my-vehicles',
      (server) => server.reply(401, {'code': 'UNAUTHORIZED'}),
    );

    await expectLater(
      dio.get<void>('/eld/company-vehicles/my-vehicles'),
      throwsA(isA<DioException>()),
    );

    expect(unauthenticatedFired, isFalse);
  });

  test('401 WITH an attached session fires the logout event (expired session)',
      () async {
    localDataSource.session = _session();
    adapter.onGet(
      '/eld/company-vehicles/my-vehicles',
      (server) => server.reply(401, {'code': 'UNAUTHORIZED'}),
    );

    await expectLater(
      dio.get<void>('/eld/company-vehicles/my-vehicles'),
      throwsA(isA<DioException>()),
    );

    expect(unauthenticatedFired, isTrue);
  });

  test('attaches the stored JSESSIONID cookie to outgoing requests',
      () async {
    localDataSource.session = _session();
    // DioAdapter يطابق رؤوس الطلب: المسار ينجح فقط إذا أرفق المُعترِض
    // كوكيز الجلسة المخزنة.
    adapter.onGet(
      '/eld/company-vehicles/my-vehicles',
      (server) => server.reply(200, {'ok': true}),
      headers: const {'Cookie': 'JSESSIONID=ABC123'},
    );

    final response =
        await dio.get<Map<String, dynamic>>('/eld/company-vehicles/my-vehicles');

    expect(response.statusCode, 200);
  });
}

AuthSession _session() {
  return AuthSession(
    serverOrigin: 'https://api.example.com',
    sessionCredential: 'ABC123',
    user: User(
      id: '101',
      username: 'driver',
      email: 'd@example.com',
      fullName: 'Driver',
      role: UserRole.fieldWorker,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? session;
  int readCount = 0;

  @override
  Future<void> saveSession(AuthSession session) async =>
      this.session = session;

  @override
  Future<AuthSession?> getSession() async {
    readCount++;
    return session;
  }

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<void> saveUser(User user) async {}

  @override
  Future<User?> getUser() async => session?.user;

  @override
  Future<void> clearUser() async {}
}
