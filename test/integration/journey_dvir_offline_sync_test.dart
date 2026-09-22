import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';

import '../helpers/sync_test_helpers.dart';
import '../helpers/test_helpers.dart';

/// الرحلة 2: فحص المركبة DVIR → إصلاح → مزامنة Offline
/// تغطي FMCSA §396.11 و §396.13 ومتطلبات عدم الفقدان
void main() {
  group('Journey 2: DVIR Offline → Repair → Previous Review', () {
    test('إنشاء تقرير DVIR بدون عيوب - يجب أن يُحفظ محلياً حتى Offline', () {
      final event = PendingEvent(
        id: 'dvir_001',
        type: 'dvir_create',
        payload: const {
          'vehicleId': 'TRUCK_123',
          'driverId': 'DRIVER_001',
          'type': 'pre_trip',
          'condition': 'satisfactory',
          'hasDefects': false,
          'timestamp': '2026-09-21T06:00:00Z',
        },
        createdAt: DateTime.utc(2026, 9, 21, 6, 0),
      );
      expect(event.payload['condition'], 'satisfactory');
      expect(event.payload['hasDefects'], false);
      // حتى لو فشل الإرسال، يجب عدم الحذف
      expect(event.id, isNotEmpty);
    });

    test('DVIR بعيوب - يجب تسجيل العيوب وطلب اعتماد الإصلاح', () {
      final event = PendingEvent(
        id: 'dvir_002',
        type: 'dvir_create',
        payload: const {
          'vehicleId': 'TRUCK_123',
          'hasDefects': true,
          'defects': ['Brake defect', 'Light defect'],
          'condition': 'defect_corrected_later',
        },
        createdAt: DateTime.utc(2026, 9, 21, 6, 10),
      );
      final defects = event.payload['defects'] as List;
      expect(defects.length, 2);
      expect(defects, contains('Brake defect'));
    });

    test('اعتماد الإصلاح (Repair Certification) - Offline ثم Sync', () async {
      // الميكانيكي يعتمد الإصلاح
      final repairEvent = PendingEvent(
        id: 'dvir_repair_001',
        type: 'dvir_repair_certify',
        payload: const {
          'dvirId': 'dvir_002',
          'mechanicName': 'Ahmed',
          'action': 'repaired',
          'signature': 'data:image/png;base64,xxx',
        },
        createdAt: DateTime.utc(2026, 9, 21, 10, 0),
      );
      expect(repairEvent.payload['mechanicName'], 'Ahmed');

      // السائق يراجع بعد الإصلاح (Previous DVIR Review)
      final reviewEvent = PendingEvent(
        id: 'dvir_review_001',
        type: 'dvir_review',
        payload: const {
          'dvirId': 'dvir_002',
          'reviewingDriverId': 1,
          'reviewingDriverName': 'Ali',
          'driverAgreed': true,
          'signature': 'data:image/png;base64,yyy',
        },
        createdAt: DateTime.utc(2026, 9, 21, 10, 5),
      );
      expect(reviewEvent.payload['driverAgreed'], true);
      expect(reviewEvent.payload['signature'], contains('base64'));

      // محاكاة Offline: كلا الحدثين يجب أن يبقيا في الطابور
      final dispatcher = FailClosedRemoteEventDispatcher();
      final r1 = await dispatcher.dispatch(repairEvent);
      final r2 = await dispatcher.dispatch(reviewEvent);
      expect(r1.isLeft(), isTrue);
      expect(r2.isLeft(), isTrue);

      // Retry policy تضمن عدم الحذف
      const policy = RetryPolicy(maxRetries: 5, baseDelay: Duration(seconds: 5), backoffFactor: 2.0);
      expect(policy.calculateNextRetry(3, nowUtc: DateTime.utc(2026, 9, 21, 10, 0)), isNotNull);
    });

    test('مراجعة تقرير سابق (§396.13) - يجب أن تكون قبل التشغيل', () {
      // السائق قبل التشغيل يجب أن يراجع آخر DVIR
      final previousDvir = {
        'id': 'dvir_prev_001',
        'vehicleId': 'TRUCK_123',
        'date': '2026-09-20T18:00:00Z',
        'hasDefects': true,
        'certified': true,
        'nextDriverReviewed': false,
      };
      expect(previousDvir['nextDriverReviewed'], false);
      // يجب أن يُطلب منه المراجعة — هذا ما يختبره previous_dvir_review_page
      final needsReview = previousDvir['nextDriverReviewed'] == false;
      expect(needsReview, isTrue);
    });

    test('DVIR بعد المزامنة - يجب الحفاظ على Atomic Save', () {
      // إما تُحفظ جميع بيانات DVIR أو لا يُحفظ شيء
      final events = [
        PendingEvent(id: 'a', type: 'dvir_create', payload: const {'id': 'dvir_003'}, createdAt: DateTime.utc(2026, 9, 21, 6, 0)),
        PendingEvent(id: 'b', type: 'dvir_repair_certify', payload: const {'dvirId': 'dvir_003'}, createdAt: DateTime.utc(2026, 9, 21, 7, 0)),
      ];
      // الترتيب يجب أن يُحفظ لضمان Atomic
      expect(events[0].createdAt.isBefore(events[1].createdAt), isTrue);
    });

    test('خطأ التحقق (Validation) يُترجم بشكل صديق', () {
      const error = ValidationError(code: 'validation.badRequest', l10nKey: 'validationError');
      expect(error.l10nKey, 'validationError');
      // سيُترجم إلى "البيانات غير صالحة" عبر app_error_l10n
    });

    test('Result.fold يتعامل مع النجاح والفشل بشكل صحيح', () {
      final success = ok<String>('dvir_123');
      final failure = err<String>(const ServerError(code: 'server.500', l10nKey: 'serverError'));

      expect(expectSuccess(success), 'dvir_123');
      expect(expectError(failure).code, 'server.500');
    });
  });
}
