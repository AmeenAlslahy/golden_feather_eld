import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/features/dvir/data/repositories/dvir_repository_impl.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Backend extends Mock implements DvirBackend {}

class _Online implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

/// §396.13 previous-report source: `GET /eld/dvir/pre-trip/{uniqueId}`
/// (live shape 2026-09-25) with the vehicle list as the only fallback.
void main() {
  late _Backend backend;
  late DvirRepositoryImpl repo;

  setUp(() {
    backend = _Backend();
    repo = DvirRepositoryImpl(dvirBackend: backend, networkInfo: _Online());
  });

  test('live "No Records" body → Right(null): nothing to review', () async {
    when(() => backend.getPreviousDvir('ELD-PRO-1006')).thenAnswer(
      (_) async => ok(<String, dynamic>{
        'success': true,
        'data': {'message': 'No Records', 'hasPreviousDvir': false},
      }),
    );
    final result = await repo.getPreviousDvir('ELD-PRO-1006');
    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => throw StateError('left')), isNull);
  });

  test('a DVIR body (Swagger list item shape) → Right(report)', () async {
    when(() => backend.getPreviousDvir('ELD-PRO-1006')).thenAnswer(
      (_) async => ok(<String, dynamic>{
        'hasPreviousDvir': true,
        'id': 42,
        'uniqueId': 'ELD-PRO-1006',
        'vehicleName': 'Truck #1006',
        'inspectionType': 'Pre-Trip',
        'inspectionTime': '2026-09-24T10:00:00Z',
        'status': 'Has Defects',
        'hasDefects': true,
        'defects': [
          {'itemCode': 'SERVICE_BRAKES', 'itemName': 'Service Brakes', 'category': 'VEHICLE'},
        ],
        'nextDriverReviewed': false,
        'driver': {'id': 101, 'name': 'Prev Driver'},
      }),
    );
    final result = await repo.getPreviousDvir('ELD-PRO-1006');
    final report = result.getOrElse((_) => throw StateError('left'));
    expect(report, isNotNull);
    expect(report!.id, '42');
    expect(report.nextDriverReviewed, isFalse);
  });

  test('unreadable body → Left so the caller falls back to the list', () async {
    when(() => backend.getPreviousDvir('X')).thenAnswer(
      (_) async => ok(<String, dynamic>{'hasPreviousDvir': true, 'foo': 'bar'}),
    );
    expect((await repo.getPreviousDvir('X')).isLeft(), isTrue);

    when(() => backend.getPreviousDvir('Y')).thenAnswer(
      (_) async => err(const NetworkError(code: 'NET_DOWN', l10nKey: 'error.network')),
    );
    expect((await repo.getPreviousDvir('Y')).isLeft(), isTrue);
  });

  test('empty / placeholder vehicle id never hits the server', () async {
    expect((await repo.getPreviousDvir('')).isRight(), isTrue);
    expect((await repo.getPreviousDvir('No Vehicle')).isRight(), isTrue);
    verifyNever(() => backend.getPreviousDvir(any()));
  });

  group('DvirState.previousToReview precedence', () {
    DvirReport report(String id, String vehicle, {bool reviewed = false}) => DvirReport(
          id: id,
          type: InspectionType.preTrip,
          date: DateTime.utc(2026, 9, 24),
          driverName: 'D',
          vehicleId: vehicle,
          items: const [],
          nextDriverReviewed: reviewed,
        );

    test('server answer wins over the list', () {
      final state = DvirState(
        reports: [report('1', 'V')],
        previousDvir: null,
        previousVehicleId: 'V',
        previousLookupDone: true,
      );
      // Server said "none" → list is ignored.
      expect(state.previousToReview('V'), isNull);
    });

    test('list is used only when the lookup failed or has not answered', () {
      final failed = DvirState(
        reports: [report('1', 'V')],
        previousVehicleId: 'V',
        previousLookupDone: true,
        previousLookupFailed: true,
      );
      expect(failed.previousToReview('V')?.id, '1');

      final pending = DvirState(reports: [report('1', 'V')]);
      expect(pending.previousToReview('V')?.id, '1');
      expect(pending.previousToReview('OTHER'), isNull);
    });

    test('an already-reviewed previous report needs no review', () {
      final state = DvirState(
        previousDvir: report('7', 'V', reviewed: true),
        previousVehicleId: 'V',
        previousLookupDone: true,
      );
      expect(state.previousToReview('V'), isNull);
    });
  });
}
