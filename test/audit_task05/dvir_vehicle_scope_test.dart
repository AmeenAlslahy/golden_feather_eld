/// انحدار: نموذج تقرير الفحص كان يعرض **أسطول الشركة كاملاً** بدل مركبات السائق.
///
/// ### العطل
///
/// `dvir_form_page.dart` كان يفتح حوار اختيار المركبة هكذا:
///
/// ```dart
/// VehiclePickerDialog(allowCompanyFleet: true)
/// ```
///
/// و`allowCompanyFleet: true` له أثران في `vehicle_picker_dialog.dart`:
/// 1. **ينتقل تلقائياً** إلى أسطول الشركة إذا كانت مركبات السائق فارغة
///    (`initState`: `_browsingCompany = true` ثم `loadCompanyVehicles()`).
/// 2. **يعرض زر** «عرض كل المركبات» للتبديل إلى أسطول الشركة.
///
/// ### الأثر
///
/// السائق يستطيع اختيار **أي مركبة في الشركة**، لا مركبته المعيَّنة، rapport الفحص يُنشئ سجل DVIR على مركبة لا يقودها — مخالفة امتثال مباشرة، وقد الرحلة creó依頼ه الصحيح لرحلة أخرى.
///
/// ⚠️ «عرض كل المركبات» ليس عيباً في حد ذاته: في صفحة اختيار مركبة
/// التشغيل (التوصيل) هو **عرض فقط** ومقصود. العيب هو إتاحته في **تقرير الفحص**، حيث السائق يكتب تقريراً قانونياً باسمه.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/vehicle_picker_dialog.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements VehicleRepository {}

void main() {
  late _Repo repo;
  late List<String> companyFleetCalls;

  setUp(() {
    repo = _Repo();
    companyFleetCalls = [];
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([
          Vehicle(id: 'MINE-1', name: 'My Truck', year: '2020', vin: 'V1'),
        ]));
    when(() => repo.getCompanyVehicles()).thenAnswer((_) async {
      companyFleetCalls.add('called');
      return const Right([
        Vehicle(id: 'OTHER-1', name: 'Someone Elses Truck', year: '2019', vin: 'V2'),
      ]);
    });
  });

  Future<void> pump(WidgetTester tester, {required bool allowCompanyFleet}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vehicleProvider.overrideWith((ref) => VehicleNotifier(repo))],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: VehiclePickerDialog(allowCompanyFleet: allowCompanyFleet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('allowCompanyFleet:false ⇒ لا انتقال لأسطول الشركة', (tester) async {
    await pump(tester, allowCompanyFleet: false);

    expect(find.textContaining('My Truck'), findsOneWidget);
    expect(companyFleetCalls, isEmpty,
        reason: 'لا يُطلب أسطول الشركة أصلاً');
    expect(find.textContaining('Someone Elses'), findsNothing);
  });

  testWidgets('allowCompanyFleet:false ⇒ لا زر «عرض كل المركبات»',
      (tester) async {
    await pump(tester, allowCompanyFleet: false);

    final loc = lookupAppLocalizations(const Locale('en'));
    expect(find.text(loc.viewAllVehicles), findsNothing,
        reason: 'السائق لا يملك طريقاً إلى أسطول الشركة');
  });

  testWidgets('❌ allowCompanyFleet:true كان يعرض أسطول الشركة (السلوك القديم)',
      (tester) async {
    // موثّق عمداً: لو عاد العطل يوماً فلن «يُصلح» بالتصحيح الخطأ.
    await pump(tester, allowCompanyFleet: true);

    // زر «عرض كل المركبات» موجود ⇒ طريق إلى مركبة ليست له.
    final loc = lookupAppLocalizations(const Locale('en'));
    expect(find.text(loc.viewAllVehicles), findsOneWidget,
        reason: 'هذا ما كان يُعرض في نموذج الفحص');
  });

  testWidgets('القائمة الفارغة بلا شركة ⇒ لا انتقال تلقائي', (tester) async {
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([]));
    await pump(tester, allowCompanyFleet: false);

    expect(companyFleetCalls, isEmpty);
  });
}
