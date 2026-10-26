import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_data.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/form_list_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/shipping_documents_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/trailers_provider.dart';

/// اختبارات المتحكم المشترك لقوائم نموذج اليوم (مراجعة 2026-10-25): كانت
/// وثائق الشحن بلا تغطية إطلاقاً والمقطورات تغطي دوالها النقية فقط —
/// هذه تغطي مسار الإضافة الموحد بترتيبه المعلن، ووجهتي الحفظ
/// (اللوحة الحية لسجل اليوم / نموذج السجل للسجول السابقة)، والحذف.

class _StubLogsNotifier extends StateNotifier<LogsState>
    implements LogsNotifier {
  _StubLogsNotifier(super.initial);

  final List<List<String>> formListsSaved = [];
  List<String>? savedTrailers;
  List<String>? savedDocuments;

  @override
  void updateSelectedFormLists({
    List<String>? trailers,
    List<String>? shippingDocuments,
  }) {
    formListsSaved.add([...?trailers, ...?shippingDocuments]);
    savedTrailers = trailers ?? savedTrailers;
    savedDocuments = shippingDocuments ?? savedDocuments;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DailyLog _pastLog({
  List<String> trailers = const [],
  List<String> documents = const [],
}) {
  return DailyLog(
    id: const DailyLogId(7),
    date: DateTime.utc(2026, 10, 20),
    totalDrivingHours: 3,
    isFormComplete: true,
    isCertified: false,
    today: false,
    trailers: trailers,
    shippingDocuments: documents,
  );
}

ProviderContainer _container({LogsState initialLogs = const LogsState()}) {
  final stub = _StubLogsNotifier(initialLogs);
  final container = ProviderContainer(
    overrides: [
      logsProvider.overrideWith((ref) => stub),
      dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
    ],
  );
  addTearDown(container.dispose);
  // autoDispose: إبقاء المزودات حية كما تفعل الصفحات الحقيقية.
  addTearDown(container.listen(trailersProvider, (_, _) {}).close);
  addTearDown(container.listen(shippingDocumentsProvider, (_, _) {}).close);
  return container;
}

void main() {
  group('وثائق الشحن — مسار الإضافة الموحد بترتيبه المعلن', () {
    test('فارغ ← empty، وفارغ بلا مسافة لا يُحفظ', () {
      final c = _container();
      final notifier = c.read(shippingDocumentsProvider.notifier);

      notifier.addItem('   ');
      expect(c.read(shippingDocumentsProvider).failure, FormListFailure.empty);
      expect(c.read(dashboardDataProvider).shippingDocuments, isNull);
    });

    test('أطول من 100 ← tooLong قبل فحص الفاصلة والصيغة', () {
      final c = _container();
      c.read(shippingDocumentsProvider.notifier).addItem('a' * 101);
      expect(
        c.read(shippingDocumentsProvider).failure,
        FormListFailure.tooLong,
      );
    });

    test('فاصلة ← containsComma (وثيقة واحدة في كل مرة)', () {
      final c = _container();
      c.read(shippingDocumentsProvider.notifier).addItem('BOL-1, BOL-2');
      expect(
        c.read(shippingDocumentsProvider).failure,
        FormListFailure.containsComma,
      );
    });

    test('محارف غير صالحة ← invalidFormat', () {
      final c = _container();
      c.read(shippingDocumentsProvider.notifier).addItem(r'BOL#<!>');
      expect(
        c.read(shippingDocumentsProvider).failure,
        FormListFailure.invalidFormat,
      );
    });

    test('صالح ← يُحفظ في اللوحة الحية وتُصفَّر حالة الفشل', () {
      final c = _container();
      final notifier = c.read(shippingDocumentsProvider.notifier);

      notifier.addItem('BOL-2026/77');

      final state = c.read(shippingDocumentsProvider);
      expect(state.failure, isNull);
      expect(state.event, FormListEvent.addedSuccessfully);
      expect(state.items, ['BOL-2026/77']);
      expect(c.read(dashboardDataProvider).shippingDocuments, 'BOL-2026/77');
    });

    test('التكرار ← alreadyExists ولا يُكرر في المصدر', () {
      final c = _container();
      final notifier = c.read(shippingDocumentsProvider.notifier);
      notifier.addItem('BOL-1');
      notifier.addItem('BOL-1');

      expect(
        c.read(shippingDocumentsProvider).failure,
        FormListFailure.alreadyExists,
      );
      expect(c.read(shippingDocumentsProvider).items, ['BOL-1']);
    });
  });

  group('المقطورات — قواعدها الخاصة عبر نفس المسار', () {
    test('الحد 5 مقطورات ← limitReached عند السادسة', () {
      final c = _container();
      final dashboard = c.read(dashboardDataProvider.notifier);
      dashboard.updateTrailers(['T1', 'T2', 'T3', 'T4', 'T5']);
      final notifier = c.read(trailersProvider.notifier);

      notifier.addItem('T6');

      expect(c.read(trailersProvider).failure, FormListFailure.limitReached);
      // الخمسة الأصلية كما هي.
      expect(c.read(trailersProvider).items, hasLength(5));
    });

    test('إضافة صالحة ← تحفظ في اللوحة الحية لسجل اليوم', () {
      final c = _container();
      c.read(trailersProvider.notifier).addItem('TR-9');

      expect(c.read(trailersProvider).items, contains('TR-9'));
      expect(c.read(dashboardDataProvider).trailerId, contains('TR-9'));
    });
  });

  group('وجهة الحفظ حسب نوع السجل', () {
    test('سجل سابق ← يقرأ من نموذج الخادم ويحفظ في نموذج السجل', () {
      final c = _container(
        initialLogs: LogsState(
          selectedLog: _pastLog(documents: const ['OLD-1']),
          serverForm: const DailyFormData(shippingDocuments: ['DOC-A']),
        ),
      );

      // نموذج الخادم مقدم على صف السجل.
      expect(c.read(shippingDocumentsProvider).items, ['DOC-A']);

      c.read(shippingDocumentsProvider.notifier).addItem('DOC-B');
      final stub = c.read(logsProvider.notifier) as _StubLogsNotifier;
      expect(stub.savedDocuments, ['DOC-A', 'DOC-B']);
      // اللوحة الحية لم تُمس.
      expect(c.read(dashboardDataProvider).shippingDocuments, isNull);
    });

    test('سجل سابق بلا نموذج خادم ← يقرأ من صف السجل نفسه', () {
      final c = _container(
        initialLogs: LogsState(
          selectedLog: _pastLog(trailers: const ['ROW-T1']),
        ),
      );

      expect(c.read(trailersProvider).items, ['ROW-T1']);

      c.read(trailersProvider.notifier).removeItem('ROW-T1');
      final stub = c.read(logsProvider.notifier) as _StubLogsNotifier;
      expect(stub.savedTrailers, isEmpty);
    });
  });

  group('الحذف', () {
    test('removeItem يحذف من المصدر الحي ويحدّث الحالة', () {
      final c = _container();
      final dashboard = c.read(dashboardDataProvider.notifier);
      dashboard.updateShippingDocuments(['A', 'B']);

      c.read(shippingDocumentsProvider.notifier).removeItem('A');

      expect(c.read(shippingDocumentsProvider).items, ['B']);
      expect(c.read(dashboardDataProvider).shippingDocuments, 'B');
    });
  });
}
