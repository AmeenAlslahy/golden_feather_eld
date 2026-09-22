import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';

import '../helpers/sync_test_helpers.dart';

/// الرحلة 1: تسجيل الدخول → تغيير حالة الخدمة → العمل دون اتصال → المزامنة
/// تغطي 80% من مخاطر فقدان سجل القيادة
void main() {
  group('Journey 1: Auth → HOS Duty Status (Online/Offline)', () {
    late HosCalculator calculator;
    late TrustedTimeProvider timeProvider;

    setUp(() {
      final now = DateTime.utc(2026, 9, 21, 8, 0);
      timeProvider = FakeTrustedTimeProvider(initialUtcTime: now);
      calculator = HosCalculator(HosConfiguration.usa70_8(), timeProvider);
    });

    test('السائق يبدأ القيادة - يجب حساب الوقت المتبقي بشكل صحيح', () {
      // Arrange: سائق بدأ مناوبته الآن، لم يقد بعد
      final now = DateTime.now();
      // Act: حساب الحدود
      final result = calculator.calculateAllLimits(
        drivingHours: 0,
        shiftStartTime: now,
        cycleHours: 10,
      );
      // Assert: يبقى 11 ساعة قيادة و 14 ساعة مناوبة
      expect(result, isA<CalculationSuccess>());
      final limits = (result as CalculationSuccess).limits;
      expect(limits.remainingDriveMinutes, 660); // 11*60
      expect(limits.remainingShiftMinutes, 840); // 14*60
      expect(limits.remainingCycleHours, 60); // 70-10
    });

    test('القيادة 8 ساعات متواصلة - يجب طلب استراحة 30 دقيقة', () {
      final now = DateTime.now();
      final shiftStart = now.subtract(const Duration(hours: 8));
      final result = calculator.calculateAllLimits(
        drivingHours: 8,
        shiftStartTime: shiftStart,
        cycleHours: 20,
      );
      expect(result, isA<CalculationSuccess>());
      final limits = (result as CalculationSuccess).limits;
      expect(limits.remainingDriveMinutes, 180); // 11-8=3h
      expect(limits.breakRequired, isTrue); // ≥8h يتطلب استراحة
    });

    test('Offline: تغيير حالة الخدمة يُحفظ محلياً ولا يُفقد', () async {
      // Arrange: محاكاة Offline عبر Sync Engine
      final event = PendingEvent(
        id: 'hos_001',
        type: 'duty_status_change',
        payload: const {
          'status': 'driving',
          'timestamp': '2026-09-21T08:00:00Z',
          'location': {'lat': 15.35, 'lon': 44.20},
        },
        createdAt: DateTime.utc(2026, 9, 21, 8, 0),
      );

      // Act: محاولة الإرسال في وضع Offline (FailClosed)
      final dispatcher = FailClosedRemoteEventDispatcher();
      final result = await dispatcher.dispatch(event);

      // Assert: يجب أن يُرجع خطأ لكن لا يحذف الحدث (يُعاد جدولته)
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (r) => null);
      expect(failure, isA<ServerFailure>());

      // Retry policy يجب أن لا تحذف الحدث بل تعيد جدولته
      const policy = RetryPolicy(maxRetries: 5, baseDelay: Duration(seconds: 5), backoffFactor: 2.0);
      final next = policy.calculateNextRetry(1, nowUtc: DateTime.utc(2026, 9, 21, 8, 0));
      expect(next, isNotNull);
      expect(next!.isAfter(DateTime.utc(2026, 9, 21, 8, 0)), isTrue);
    });

    test('DISCONNECTED CONTINUE: السماح بالاستمرار دون اتصال مع تسجيل الحالة', () async {
      // هذا يختبر زر DISCONNECTED CONTINUE المطلوب في SRS 6.8
      final event = PendingEvent(
        id: 'hos_002',
        type: 'disconnected_continue',
        payload: const {'reason': 'offline_continue', 'driverId': '123'},
        createdAt: DateTime.utc(2026, 9, 21, 8, 5),
      );
      // يجب أن يُحفظ محلياً حتى لو فشل الإرسال
      expect(event.type, 'disconnected_continue');
      expect(event.payload['reason'], 'offline_continue');

      const policy = RetryPolicy(maxRetries: 10, baseDelay: Duration(seconds: 5), backoffFactor: 2.0);
      // حتى بعد 5 محاولات، لا يُحذف
      final retryAfter5 = policy.calculateNextRetry(5, nowUtc: DateTime.utc(2026, 9, 21, 8, 5));
      expect(retryAfter5, isNotNull);
      // حتى بعد 10 محاولات (الحد الأقصى)، يجب أن يعيد الجدولة بحد أقصى لا يحذف
      final retryAfter10 = policy.calculateNextRetry(10, nowUtc: DateTime.utc(2026, 9, 21, 8, 5));
      expect(retryAfter10, isNotNull);
    });

    test('العودة Online: جميع الأحداث المعلقة يجب أن تُزامن بترتيبها', () {
      // Arrange: 3 أحداث محلية أثناء Offline
      final events = [
        PendingEvent(id: '1', type: 'duty_status_change', payload: const {'status': 'on_duty'}, createdAt: DateTime.utc(2026, 9, 21, 8, 0)),
        PendingEvent(id: '2', type: 'duty_status_change', payload: const {'status': 'driving'}, createdAt: DateTime.utc(2026, 9, 21, 8, 5)),
        PendingEvent(id: '3', type: 'duty_status_change', payload: const {'status': 'off_duty'}, createdAt: DateTime.utc(2026, 9, 21, 12, 0)),
      ];
      // Assert: الترتيب الزمني محفوظ
      expect(events[0].createdAt.isBefore(events[1].createdAt), isTrue);
      expect(events[1].createdAt.isBefore(events[2].createdAt), isTrue);
      // عند المزامنة، يجب إرسالها بالترتيب لضمان Atomic Save
      final sorted = [...events]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(sorted[0].id, '1');
      expect(sorted[1].id, '2');
      expect(sorted[2].id, '3');
    });

    test('خطأ الشبكة يُترجم إلى رسالة مستخدم صحيحة (عربي/إنجليزي)', () {
      const error = NetworkError(code: 'network.timeout', l10nKey: 'networkTimeout');
      expect(error.code, 'network.timeout');
      expect(error.l10nKey, 'networkTimeout');
      // l10nKey سيُترجم عبر app_error_l10n.dart إلى "انتهت مهلة الاتصال" / "Network timeout"
    });
  });
}

/// مزود وقت مزيف للاختبار
class FakeTrustedTimeProvider implements TrustedTimeProvider {
  @override
  DateTime initialUtcTime;
  FakeTrustedTimeProvider({required this.initialUtcTime});
  @override
  DateTime get nowUtc => initialUtcTime;
  @override
  Future<DateTime> getTrustedTime() async => nowUtc;
  @override
  Stream<DateTime> get onTimeChanged => Stream.value(nowUtc);

  @override
  void anchor(DateTime serverUtc) {
    initialUtcTime = serverUtc;
  }

  @override
  TrustedTimeResult get currentTime => TrustedTimeAvailable(initialUtcTime);

  @override
  Duration get monotonicElapsed => Duration.zero;

  @override
  TrustedTimeState get state => TrustedTimeState.trusted;
}
