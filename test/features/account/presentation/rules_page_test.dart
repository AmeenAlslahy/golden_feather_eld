import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/contracts/rules_screen_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/eld_info_row.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/presentation/pages/rules_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier(super.state);
  @override
  Future<bool> login(
          {required String username,
          required String password,
          String? serverUrl}) async =>
      true;
  @override
  void forceLogout() {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> checkAuthStatus() async {}
  @override
  void clearError() {}
}

class _FakeLocalStorage extends Mock implements LocalStorageService {}

/// Records what the page sends and lets the test shape what the server allows.
class _RecordingRulesBackend implements RulesScreenBackend {
  _RecordingRulesBackend(this.model);
  RulesScreenModel model;
  RawJson? lastUpdate;

  @override
  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId}) async =>
      fp.Right(model);

  @override
  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RawJson update,
  }) async {
    lastUpdate = update;
    return fp.Right(model);
  }
}

RulesScreenModel _model({
  Set<String> editable = const {},
  Map<String, dynamic> fixed = const {},
  String notice = '',
}) =>
    RulesScreenModel(
      ruleSource: 'Federal',
      cycleRule: 'USA 70/8',
      cargoType: 'Property',
      restart: '34 Hour Restart',
      restBreak: '30 Minute Rest Break Required',
      sixteenHourException: false,
      options: const {
        'cycleRule': ['USA 70/8', 'USA 60/7'],
        'cargoType': ['Property', 'Passenger'],
        'restart': ['34 Hour Restart', 'None'],
        'restBreak': ['30 Minute Rest Break Required', 'None'],
      },
      editableFields: editable,
      readOnlyFields: const {},
      fixedSettings: fixed,
      notice: notice,
      limits: HosConfiguration.usa70_8(),
    );

/// SRS 4 — Rules screen: server-driven read-only vs editable fields,
/// fleet-fixed settings, and the SAVE pipeline.
void main() {
  late _RecordingRulesBackend backend;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    registerFallbackValue(HosConfiguration.usa70_8());
    final storage = _FakeLocalStorage();
    when(() => storage.setHosConfiguration(any())).thenAnswer((_) async {});
    when(() => storage.hosConfiguration).thenReturn(HosConfiguration.usa70_8());

    final auth = AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: '106',
        fullName: 'Test Driver',
        email: 't@d.com',
        username: 't',
        role: UserRole.fieldWorker,
        createdAt: DateTime(2026),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rulesScreenBackendProvider.overrideWithValue(backend),
          localStorageProvider.overrideWithValue(storage),
          authStateProvider.overrideWith((ref) => _AuthNotifier(auth)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const RulesPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('read-only account: rule source + rules are info rows, no dropdowns',
      (tester) async {
    backend = _RecordingRulesBackend(_model(
      fixed: const {
        'personalConveyance': true,
        'yardMoves': false,
      },
      notice: 'Rules are managed by your carrier.',
    ));
    await pump(tester);

    expect(find.text('Rules are managed by your carrier.'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    final rows = tester
        .widgetList<EldInfoRow>(find.byType(EldInfoRow))
        .map((w) => '${w.label}=${w.value}')
        .toList();
    expect(rows, contains('Rule Source=Federal'));
    expect(rows, contains('Cycle Rule=USA 70/8'));
    expect(rows, contains('16-Hour Short-Haul Exception=No'));
    // Fleet-fixed settings come from the server, never invented.
    expect(rows, contains('Personal Conveyance=Allowed'));
    expect(rows, contains('Yard Moves=Forbidden'));
    expect(rows, contains('Unlimited Trailers=Not provided by the server'));
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('editable account: dropdowns + switch, SAVE sends the selection',
      (tester) async {
    backend = _RecordingRulesBackend(_model(
      editable: const {
        'cycleRule',
        'cargoType',
        'restart',
        'restBreak',
        'sixteenHourException',
      },
    ));
    await pump(tester);

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4));
    // Rule source is never editable — still an info row.
    expect(
      tester
          .widgetList<EldInfoRow>(find.byType(EldInfoRow))
          .any((w) => w.label == 'Rule Source' && w.value == 'Federal'),
      isTrue,
    );

    // Change the cycle rule.
    await tester.tap(find.text('USA 70/8'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USA 60/7').last);
    await tester.pumpAndSettle();

    // Enable the 16-hour exception (allowed because the server lists it).
    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();

    final save = find.widgetWithText(AppButton, 'SAVE');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(backend.lastUpdate, isNotNull);
    expect(backend.lastUpdate!['cycleRule'], 'USA 60/7');
    expect(backend.lastUpdate!['cargoType'], 'Property');
    expect(backend.lastUpdate!['sixteenHourException'], isTrue);
    expect(find.text('Rules updated successfully'), findsOneWidget);
  });
}
