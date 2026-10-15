import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/error/user_facing_message.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  final locAr = lookupAppLocalizations(const Locale('ar'));
  final locEn = lookupAppLocalizations(const Locale('en'));

  group('الأمان — لا تتسرّب تفاصيل تقنية', () {
    test('prefers serverMessage and never dumps the exception', () {
      const error = ValidationError(
        code: 'VALIDATION_ERROR',
        l10nKey: 'validationError',
        cause: FormatException('Unexpected character (at offset 0)'),
        context: {
          'serverMessage': 'القاعدة التنظيمية المحددة لا تدعم استثناء الـ 16 ساعة',
        },
      );

      final text = appErrorUserMessage(error, loc: locAr);
      expect(text, contains('16'));
      expect(text, isNot(contains('FormatException')));
      expect(text, isNot(contains('ValidationError')));
    });

    test('network error has no stack text', () {
      const error = NetworkError(
        code: 'network.connectionFailed',
        l10nKey: 'networkConnectionFailed',
      );
      expect(appErrorUserMessage(error, loc: locEn), contains('server'));
      expect(appErrorUserMessage(error, loc: locAr), contains('الخادم'));
    });
  });

  group('الرسائل تصف ما حدث للسائق — لا ما فعله الخادم', () {
    test('validation لا يُعرض كـ«الخادم رفض الطلب»', () {
      // موثّق عمداً: هذا ما كان يظهر، وهو ما اشتكى منه السائق.
      // مضمون ألا يعود بالتحويل إلى «رفض» من الخادم بلا تفسير.
      final text = anyErrorUserMessage(
        const ServerFailure(message: 'validation.badRequest'),
        loc: locAr,
      );
      expect(text, isNot(contains('رفض الطلب')),
          reason: 'السائق لا يعرف ما رفضه الخادم ولا لماذا');
      expect(text, locAr.errCheckYourInput);
    });

    test('التعارض يعطي تفسيراً لا وصفاً لسلوك الخادم', () {
      final text = anyErrorUserMessage(
        const ServerFailure(message: 'resource.conflict'),
        loc: locAr,
      );
      expect(text, locAr.errConflictingChange);
      expect(text, isNot(contains('رفض')));
    });

test('409 المعتمد ⇒ «ألغِ الاعتماد» لا «أعد المحاولة» وحدها', () {
      // ❌ الأعلى خطأ: طلب لا يمكن أن ينجح، والنصيحة بإعادة المحاولة.
      final text = anyErrorUserMessage(
        const ServerFailure(message: 'BUSINESS_RULE_VIOLATION'),
        loc: locAr,
      );
      expect(text, locAr.errBusinessRuleViolation);
      expect(text, contains('اعتماد'),
          reason: 'الخطوة الصحيحة: إلغاء الاعتماد');
      expect(text, isNot(locAr.errRequestFailed));
      expect(text, isNot(contains('تعذر إكمال')),
          reason: 'لا معنى لقول «تعذّر» على قاعدة عمل معروفة');
    });

    test('النصيحة تسبقها خطوة تمكين، لا طلب بلا فائدة', () {
      final text = anyErrorUserMessage(
        const ServerFailure(message: 'BUSINESS_RULE_VIOLATION'),
        loc: locAr,
      );
      // «ألغِ الاعتماد أولاً ثم أعد المحاولة» — الترتيب هو المعنى.
      final uncertifyAt = text.indexOf('ألغِ');
      final retryAt = text.indexOf('المحاولة');
      expect(uncertifyAt, greaterThanOrEqualTo(0));
      expect(retryAt, greaterThan(uncertifyAt),
          reason: 'إعادة المحاولة تأتي بعد خطوة تُتيحها');
    });
  });

  group('رسالة الخادم تُحفظ بدل إهدارها', () {
    test('Failure.serverMessage يتقدّم على الرمز الآلي', () {
      // هذا ما كان يضيع: الخادم كتب تفسيراً دقيقاً ورُمي مع الرمز.
      const failure = ServerFailure(
        message: 'BUSINESS_RULE_VIOLATION',
        serverMessage: 'السجل اليومي معتمد مسبقاً، لا يمكن تعديل البيانات قبل إلغاء الاعتماد',
      );
      final text = anyErrorUserMessage(failure, loc: locAr);
      expect(text, contains('معتمد مسبقاً'));
      expect(text, isNot(contains('BUSINESS_RULE_VIOLATION')));
    });

    test('الخادم يبقى المرجع: نصّه يُعرض حرفياً', () {
      const failure = ServerFailure(
        message: 'resource.conflict',
        serverMessage: 'المركبة محجوزة لزميل آخر اليوم',
      );
      expect(anyErrorUserMessage(failure, loc: locAr), contains('محجوزة'));
    });

    test('الأمان محفوظ: رسالة خطرة لا تُعرض', () {
      const failure = ServerFailure(
        message: 'server.500',
        serverMessage: 'org.springframework.jdbc.SQLException at driver',
      );
      final text = anyErrorUserMessage(failure, loc: locAr);
      expect(text, isNot(contains('org.springframework')));
      expect(text, isNot(contains('Exception')));
    });

    test('الأمان محفوظ: بريد أو رابط لا يُعرض', () {
      const failure = ServerFailure(
        message: 'validation.badRequest',
        serverMessage: 'contact admin@company.com or see https://x.co/a',
      );
      final text = anyErrorUserMessage(failure, loc: locAr);
      expect(text, isNot(contains('@')));
      expect(text, isNot(contains('http')));
    });

    test('❌ رسالة فارغة أو غير آمنة ⇒ نرجع للترجمة لا للرمز', () {
      const empty = ServerFailure(message: 'x.y', serverMessage: '   ');
      expect(anyErrorUserMessage(empty, loc: locAr), isNot(contains('x.y')));
    });
  });

  group('الترتيب: الأدقّ قبل الأعمّ', () {
    test('sessionConflict ليست انتهاء جلسة', () {
      // ❌ كان `session` يسبق `conflict` ⇒ رسالة نقيض ما حدث.
      final text = anyErrorUserMessage(
        const ServerFailure(message: 'resource.sessionConflict'),
        loc: locAr,
      );
      expect(text, locAr.errConflictingChange);
      expect(text, isNot(locAr.errSessionExpiredAction));
    });

    test('انتهاء الجلسة ما زال يُكتشف', () {
      for (final code in ['session_expired', 'token_expired', 'unauthorized']) {
        expect(
          anyErrorUserMessage(ServerFailure(message: code), loc: locAr),
          locAr.errSessionExpiredAction,
          reason: code,
        );
      }
    });

    test('لا يُقال للسائق «تحقّق من الشبكة» لسبب ليس شبكة', () {
      for (final code in [
        'BUSINESS_RULE_VIOLATION',
        'resource.conflict',
        'validation.badRequest',
        'resource.notFound',
      ]) {
        final text = anyErrorUserMessage(ServerFailure(message: code), loc: locAr);
        expect(text, isNot(locAr.errNoInternet), reason: code);
        expect(text, isNot(contains('الإنترنت')), reason: code);
      }
    });

    test('أخطاء الشبكة ما زالت تُكتشف', () {
      for (final code in [
        'network.connectionFailed',
        'noInternet',
        'request.timeout',
        'connection.refused',
      ]) {
        expect(
          anyErrorUserMessage(ServerFailure(message: code), loc: locAr),
          locAr.errNoInternet,
          reason: code,
        );
      }
    });
  });
}
