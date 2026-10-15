/// انحدار: صفحة التفتيش كانت تُجمّد أزرارها الأربعة عند غياب الإنترنت.
///
/// ### العطل
///
/// `inspection_start_view.dart` كان يحسب:
///
/// ```dart
/// final capabilitiesReady = screen != null;
/// bool enabled(bool serverFlag) => capabilitiesReady && serverFlag;
/// ```
///
/// و`screen` تأتي من `getScreen()` — وهي **قراءة عبر الشبكة فقط**. عند
/// الانقطاع وغياب الكاش تُرجع `_screenFallback` قيمة `Left`، فيصبح
/// `screen == null`، و`screen?.canStartInspection ?? false` = `false`،
/// فتنغلق الأزرار الأربعة: بدء التفتيش، إرسال السجلات، البريد، الحزمة.
///
/// والكاش **في الذاكرة فقط** (`inspection_repository_impl.dart:43-52`)
/// فيُفقد عند إعادة التشغيل وعند تبديل السائق ⇒ **إقلاع بارد بلا شبكة
/// يُجمّد كل شيء**.
///
/// ### التناقض
///
/// نفس الميزة تعلّق على بُعد 30 سطراً (`inspection_provider.dart:254-256`):
/// «تسجيل القفل مركزياً — **غير معيق**: التفتيش الميداني يجب أن يعمل بلا
/// شبكة (SRS 6.8)».
///
/// وكل ما خلف البوابة جاهز فعلاً:
/// - بدء التفتيش محلي، والتسجيل `unawaited`.
/// - إرسال السجلات يولّد ملف 49 CFR Part 395 محلياً ويصفّه في الطابور.
///
/// فالبوابة وحدها كانت تمنع المفتّش roadside من العمل.
///
/// ### الأمان
///
/// الخادم يبقى المرجع النهائي عند المزامنة. ورفضه أصبح (Task 04)
/// `RejectedFailure` نهائياً ⇒ dead-letter، لا إعادة محاولة لا نهائية.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/inspection/presentation/pages/inspection_start_view.dart';

void main() {
  const serverAllows = true;
  const serverDenies = false;

  InspectionCapabilityGate gate({required bool answered, required bool online}) =>
      InspectionCapabilityGate(serverAnswered: answered, isOnline: online);

  group('مع الخادم: fail-closed', () {
    test('الخادم أذن ⇒ مفعّل', () {
      final g = gate(answered: true, online: true);
      expect(g.isOpen, isTrue);
      expect(g.isEnabled(serverFlag: serverAllows), isTrue);
    });

    test('الخادم رفض ⇒ معطّل + رسالة الرفض', () {
      final g = gate(answered: true, online: true);
      expect(g.isEnabled(serverFlag: serverDenies), isFalse);
      expect(g.denial(serverFlag: serverDenies, message: 'رفض'),
          'رفض');
    });

    test('لم يجب بعد وهو متصل ⇒ مقفول بلا اتهام الخادم', () {
      // لسنا نسأل بعد ⇒ لا نخمّن، ولا نُعلم السائق بأن الخادم رفض.
      final g = gate(answered: false, online: true);
      expect(g.isOpen, isFalse);
      expect(g.isEnabled(serverFlag: serverDenies), isFalse);
      expect(g.denial(serverFlag: serverDenies, message: 'رفض'), isNull);
    });
  });

  group('❌ بلا خادم وبلا شبكة: كان يُجمّد كل شيء', () {
    test('الأزرار الأربعة مفعّلة الآن', () {
      final g = gate(answered: false, online: false);
      expect(g.isOpen, isTrue,
          reason: 'لا فائدة من انتظار ما لا يمكن أن يأتي');
      expect(g.isEnabled(serverFlag: serverDenies), isTrue,
          reason: 'هذا هو العطل المُصلَح');
      expect(g.isEnabled(serverFlag: serverAllows), isTrue);
    });

    test('لا تُعرض رسالة «الخادم لم يسمح»', () {
      // نُسند إليه رفضاً لم يُصدره.
      final g = gate(answered: false, online: false);
      expect(g.denial(serverFlag: serverDenies, message: 'رفض'), isNull);
    });

    test('يُعلَم السائق بأن الصلاحيات لم تُتحقّق منها', () {
      expect(gate(answered: false, online: false).offlineWithoutServerAnswer,
          isTrue);
    });
  });

  group('لا تراجع في الأمان', () {
    test('رفض الخادم يبقى نافذاً حتى بلا اتصال إن أجاب مرة واحدة', () {
      // إن كان الخادم ردّ قبل الانقطاع، فالردّ حقيقة نثق بها — ولا
      // يُرفع تعطيله لمجرد انقطاع الشبكة بعده.
      final g = gate(answered: true, online: false);
      expect(g.isEnabled(serverFlag: serverDenies), isFalse);
      expect(g.denial(serverFlag: serverDenies, message: 'رفض'), 'رفض');
    });

    test('خادم ردّ بإذن ثم انقطع ⇒ يبقى مفعّلاً', () {
      final g = gate(answered: true, online: false);
      expect(g.isEnabled(serverFlag: serverAllows), isTrue);
    });
  });

  group('جدول القرار كامل', () {
    test('كل توليفات (serverAnswered × isOnline × serverFlag)', () {
      // الجدول موثّق في [InspectionCapabilityGate]؛ هذا يثبّته.
      expect(
        [
          for (final answered in [true, false])
            for (final online in [true, false])
              for (final flag in [true, false])
                (
                  answered: answered,
                  online: online,
                  flag: flag,
                  enabled: gate(answered: answered, online: online)
                      .isEnabled(serverFlag: flag),
                ),
        ],
        [
          // أجاب، متصل
          (answered: true, online: true, flag: true, enabled: true),
          (answered: true, online: true, flag: false, enabled: false),
          // أجاب، انقطع
          (answered: true, online: false, flag: true, enabled: true),
          (answered: true, online: false, flag: false, enabled: false),
          // لم يجب، متصل ⇒ مقفول (لسنا نسأل)
          (answered: false, online: true, flag: true, enabled: false),
          (answered: false, online: true, flag: false, enabled: false),
          // لم يجب، انقطع ⇒ مفتوح  ← الإصلاح
          (answered: false, online: false, flag: true, enabled: true),
          (answered: false, online: false, flag: false, enabled: true),
        ],
      );
    });
  });
}
