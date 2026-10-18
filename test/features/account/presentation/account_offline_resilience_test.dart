import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/account_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/account_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockBackend extends Mock implements AccountBackend {}

class _TestNetworkInfo implements NetworkInfo {
  bool online = true;
  @override
  bool get isConnected => online;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier(super.state);

  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async => true;

  @override
  void forceLogout() {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void clearError() {}
}

void main() {
  late _MockBackend backend;
  late _TestNetworkInfo network;

  final testUser = User(
    id: '101',
    username: 'driver101',
    fullName: 'Captain Driver',
    email: 'driver@example.com',
    phone: '555-1234',
    role: UserRole.fieldWorker,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    backend = _MockBackend();
    network = _TestNetworkInfo();
  });

  ProviderContainer createContainer({bool isOnline = true}) {
    network.online = isOnline;
    return ProviderContainer(
      overrides: [
        accountBackendProvider.overrideWithValue(backend),
        networkInfoProvider.overrideWithValue(network),
        authStateProvider.overrideWith(
          (ref) => _TestAuthNotifier(AuthState(
            user: testUser,
            status: AuthStatus.authenticated,
            sessionEpoch: 1,
          )),
        ),
      ],
    );
  }

  test('fetchMyAccount offline does not call backend and synthesizes account from auth without error', () async {
    final container = createContainer(isOnline: false);
    addTearDown(container.dispose);

    await container.read(accountProvider.notifier).fetchMyAccount();

    verifyNever(() => backend.getMyAccount(driverId: any(named: 'driverId')));

    final state = container.read(accountProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.accountData, isNotNull);
    expect(state.accountData?.driverId, 101);
    expect(state.accountData?.email, 'driver@example.com');
  });

  test('updatePreferences offline is rejected without mutating local account', () async {
    final container = createContainer(isOnline: false);
    addTearDown(container.dispose);

    await container.read(accountProvider.notifier).fetchMyAccount();

    final result = await container.read(accountProvider.notifier).updatePreferences(
      language: 'Spanish',
      odometerUnit: 'km',
    );

    expect(result, isFalse);

    final state = container.read(accountProvider);
    expect(state.accountData?.language, 'English');
    expect(state.accountData?.odometer, 'mi');
    expect(state.error, 'noInternet');
  });

  test('fetchMyAccount online falling back gracefully on network error', () async {
    final container = createContainer(isOnline: true);
    addTearDown(container.dispose);

    when(() => backend.getMyAccount(driverId: any(named: 'driverId'))).thenAnswer(
      (_) async => err(const NetworkError(
        code: 'network.timeout',
        l10nKey: 'err_network_timeout',
      )),
    );

    await container.read(accountProvider.notifier).fetchMyAccount();

    final state = container.read(accountProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull); // Does not disrupt driver with network error
    expect(state.accountData?.driverId, 101);
  });
}
