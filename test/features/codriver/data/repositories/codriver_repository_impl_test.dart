import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/driver_session_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/codriver/data/repositories/codriver_repository_impl.dart';

class _MockDriverSessionBackend extends Mock
    implements DriverSessionBackend {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockDriverSessionBackend mockBackend;
  late _MockNetworkInfo mockNetworkInfo;
  late CoDriverRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(DutyStatusAction.legacySwitch);
    registerFallbackValue(const DriverId(1));
  });

  setUp(() {
    mockBackend = _MockDriverSessionBackend();
    mockNetworkInfo = _MockNetworkInfo();
    repository = CoDriverRepositoryImpl(
      driverSessionBackend: mockBackend,
      networkInfo: mockNetworkInfo,
    );
  });

  group('switchPrimary', () {
    test('calls backend with legacySwitch without reason first', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      when(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.legacySwitch,
          coDriverId: const DriverId(102),
        ),
      ).thenAnswer((_) async => ok(null));

      final result = await repository.switchPrimary(coDriverId: 102);

      expect(result.isRight(), isTrue);
      verify(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.legacySwitch,
          coDriverId: const DriverId(102),
        ),
      ).called(1);
      verifyNever(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.switchPrimary,
          coDriverId: any(named: 'coDriverId'),
          reason: any(named: 'reason'),
        ),
      );
    });

    test('falls back to switchPrimary with reason if legacySwitch fails', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);
      when(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.legacySwitch,
          coDriverId: const DriverId(103),
        ),
      ).thenAnswer((_) async => err(const ServerError(code: '400')));
      when(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.switchPrimary,
          coDriverId: const DriverId(103),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => ok(null));

      final result = await repository.switchPrimary(
        coDriverId: 103,
        reason: 'سبب مخصص',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.legacySwitch,
          coDriverId: const DriverId(103),
        ),
      ).called(1);
      verify(
        () => mockBackend.switchPrimaryDriver(
          action: DutyStatusAction.switchPrimary,
          coDriverId: const DriverId(103),
          reason: 'سبب مخصص',
        ),
      ).called(1);
    });

    test('returns ServerFailure when coDriverId <= 0 without calling backend', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(true);

      final result = await repository.switchPrimary(coDriverId: 0);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
      verifyZeroInteractions(mockBackend);
    });

    test('returns NetworkFailure when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenReturn(false);

      final result = await repository.switchPrimary(coDriverId: 102);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected NetworkFailure'),
      );
      verifyZeroInteractions(mockBackend);
    });
  });
}
