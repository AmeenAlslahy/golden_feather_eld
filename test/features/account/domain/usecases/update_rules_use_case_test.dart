import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/rules_screen_dto.dart';
import 'package:golden_feather_eld/backend/contracts/rules_screen_backend.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/account/domain/entities/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/domain/usecases/update_rules_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockRulesScreenBackend extends Mock implements RulesScreenBackend {}
class MockLocalStorageService extends Mock implements LocalStorageService {}
class FakeDriverId extends Fake implements DriverId {}

void main() {
  late MockRulesScreenBackend mockBackend;
  late MockLocalStorageService mockStorage;
  late UpdateRulesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeDriverId());
    registerFallbackValue(const HosConfiguration(
      drivingLimitMinutes: 0,
      shiftLimitMinutes: 0,
      cycleLimitHours: 0,
      breakDurationMinutes: 0,
      movingSpeedThresholdKmh: 0,
      driveBeforeBreakMinutes: 0,
      maxConsecutiveDays: 0,
      weeklyRestartHours: 0,
    ));
  });

  setUp(() {
    mockBackend = MockRulesScreenBackend();
    mockStorage = MockLocalStorageService();
    useCase = UpdateRulesUseCase(mockBackend, mockStorage, '100');
  });

  test('execute saves rules and merges local configuration on success', () async {
    const request = RulesScreenUpdateRequest(
      cycleRule: 'cycle',
      cargoType: 'cargo',
      restart: 'restart',
      restBreak: 'break',
      sixteenHourException: true,
    );

    const modelLimits = HosConfiguration(
      drivingLimitMinutes: 600,
      shiftLimitMinutes: 800,
      cycleLimitHours: 60,
      breakDurationMinutes: 0,
      movingSpeedThresholdKmh: 0.0,
      driveBeforeBreakMinutes: 0,
      maxConsecutiveDays: 7,
      weeklyRestartHours: 0,
    );

    const returnModel = RulesScreenModel(
      ruleSource: 'source',
      cycleRule: 'cycle',
      cargoType: 'cargo',
      restart: 'restart',
      restBreak: 'break',
      sixteenHourException: true,
      options: {},
      limits: modelLimits,
      editableFields: {},
      readOnlyFields: {},
      fixedSettings: {},
      notice: '',
    );

    when(() => mockBackend.saveRulesScreen(
      driverId: any(named: 'driverId'),
      update: any(named: 'update'),
    )).thenAnswer((_) async => const fp.Right(returnModel));

    final currentConfig = HosConfiguration.usa70_8();
    when(() => mockStorage.hosConfiguration).thenReturn(currentConfig);
    when(() => mockStorage.setHosConfiguration(any())).thenAnswer((_) async {});

    final result = await useCase.execute(request);

    expect(result.isRight(), true);
    verify(() => mockBackend.saveRulesScreen(
      driverId: any(named: 'driverId'),
      update: request.toJson(),
    )).called(1);

    final captured = verify(() => mockStorage.setHosConfiguration(captureAny())).captured;
    final savedConfig = captured.first as HosConfiguration;
    
    // Limits from backend
    expect(savedConfig.drivingLimitMinutes, 600);
    expect(savedConfig.shiftLimitMinutes, 800);
    expect(savedConfig.cycleLimitHours, 60);
    expect(savedConfig.maxConsecutiveDays, 7);
    
    // Limits preserved locally
    expect(savedConfig.breakDurationMinutes, currentConfig.breakDurationMinutes);
    expect(savedConfig.movingSpeedThresholdKmh, currentConfig.movingSpeedThresholdKmh);
    expect(savedConfig.driveBeforeBreakMinutes, currentConfig.driveBeforeBreakMinutes);
    expect(savedConfig.weeklyRestartHours, currentConfig.weeklyRestartHours);
  });

  test('execute does not update local configuration on failure', () async {
    const request = RulesScreenUpdateRequest(
      cycleRule: 'cycle',
      cargoType: 'cargo',
      restart: 'restart',
      restBreak: 'break',
      sixteenHourException: true,
    );

    when(() => mockBackend.saveRulesScreen(
      driverId: any(named: 'driverId'),
      update: any(named: 'update'),
    )).thenAnswer((_) async => const fp.Left(ServerError(code: 'error')));

    final result = await useCase.execute(request);

    expect(result.isLeft(), true);
    verifyNever(() => mockStorage.setHosConfiguration(any()));
  });
}
