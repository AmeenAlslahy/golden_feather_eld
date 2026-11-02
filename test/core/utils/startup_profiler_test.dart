import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/utils/startup_profiler.dart';

/// M0 — تحقق أن أدوات قياس الإقلاع لا ترمي ولا تغيّر دلالات الـ await
/// (قياس فقط: بلا شبكة، بلا حالة أعمال، بلا PII).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StartupProfiler.start();
  });

  test('runId مستقر ضمن نفس التشغيل وغير فارغ', () {
    final a = StartupProfiler.runId;
    final b = StartupProfiler.runId;
    expect(a, isNotEmpty);
    expect(a, same(b));
  });

  test('mark وmarkOnce لا يرميان ويُسجل markOnce مرة واحدة', () {
    StartupProfiler.mark('test:mark');
    StartupProfiler.markOnce('test:once');
    StartupProfiler.markOnce('test:once'); // الاستدعاء الثاني بلا أثر
    // لا استثناء = نجاح؛ الحارس الداخلي يضمن التفرد.
  });

  test('phase يُكمل الجسم ويعيد نفس سلوك الخطأ', () async {
    var executed = false;
    await StartupProfiler.phase('test:phase', () async {
      executed = true;
    });
    expect(executed, isTrue);

    // الاستثناء يمر كما هو (سلوك الخطأ غير مُبدَّل) — وقياس المدة يُسجل.
    await expectLater(
      StartupProfiler.phase('test:phase-throw', () async {
        throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('scheduleFirstFrameMark لا يرمي ويُسجل مرة عبر الإطارات', (
    tester,
  ) async {
    StartupProfiler.scheduleFirstFrameMark();
    await tester.pump();
    await tester.pump(); // إطار ثانٍ — الحارس يمنع التكرار
    // لا استثناء = نجاح.
  });
}
