import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_inspection_backend.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/inspection/presentation/pages/send_logs_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Storage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
}

/// Records what the page sends; the server answer is scripted per test.
class _Backend extends MockInspectionBackend {
  final calls = <String>[];
  RawJson sendAnswer = const {'status': 'PENDING', 'message': 'Transfer queued.'};
  AppError? sendError;
  List<Map<String, dynamic>> transfers = const [];

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
  }) async {
    calls.add('send:${driverId.value}:${transferType.name}:$outputFileComment:${routingCode ?? ''}');
    if (sendError != null) return err(sendError!);
    return ok(sendAnswer);
  }

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  }) async {
    calls.add('email:${driverId.value}:$recipientEmail:${comment ?? ''}:${routingCode ?? ''}');
    if (sendError != null) return err(sendError!);
    return ok(sendAnswer);
  }

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) async =>
      ok({'transfers': transfers});
}

class _Adapter extends Mock implements BackendAdapter {}

/// SRS 8.4 / 8.5 — Send / Email logs: local validation before any request,
/// the existing send-logs / email endpoints, the server's own outcome text,
/// and the transfer history from the server.
void main() {
  late _Backend backend;

  late _Adapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = _Backend();
    adapter = _Adapter();
    when(() => adapter.inspection).thenReturn(backend);
    when(() => adapter.isMock).thenReturn(true);
  });

  Future<void> pump(WidgetTester tester, {bool email = false}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(adapter),
          localStorageProvider.overrideWithValue(_Storage()),
          currentDriverIdProvider.overrideWithValue(106),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SendLogsPage(isEmailMode: email),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapSend(WidgetTester tester) async {
    final send = find.widgetWithText(AppButton, 'SEND');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('send mode: comment 4–60 chars is enforced before any request',
      (tester) async {
    await pump(tester);

    expect(find.text('Send 8 Logs'), findsOneWidget);
    // Reference layout (screenshot 9): Comment + Data Transfer Type: Email.
    expect(find.text('Comment'), findsOneWidget);
    expect(find.text('Data Transfer Type'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abc');
    await tapSend(tester);
    expect(find.text('The comment must be 4 to 60 characters.'), findsOneWidget);
    expect(backend.calls, isEmpty);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('send mode: valid comment → send-logs (EMAIL), server text shown',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Roadside check I-80');
    await tapSend(tester);

    expect(backend.calls, ['send:106:email:Roadside check I-80:']);
    // The server's own outcome text is what the driver sees.
    expect(find.text('Transfer queued.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'SEND'), findsNothing);
  });

  testWidgets('email mode: invalid address refused; valid → email endpoint',
      (tester) async {
    await pump(tester, email: true);
    expect(find.text('Send logs via email'), findsOneWidget);
    // Reference layout (screenshot 3): recipient + SRS 8.4 routing code.
    expect(find.text('Recipient Email'), findsOneWidget);
    expect(find.text('Routing Code'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'nope');
    await tapSend(tester);
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(backend.calls, isEmpty);

    await tester.enterText(find.byType(TextField).first, 'officer@dot.gov');
    await tapSend(tester);

    expect(backend.calls, ['email:106:officer@dot.gov:Email logs transfer:']);
    expect(find.text('Transfer queued.'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('server FAILED status is a refusal, not a success screen',
      (tester) async {
    backend.sendAnswer = const {'status': 'FAILED', 'message': 'Routing code unknown.'};
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Roadside check');
    await tapSend(tester);

    expect(find.text('Routing code unknown.'), findsOneWidget);
    // Form stays; nothing is claimed as sent.
    expect(find.widgetWithText(AppButton, 'SEND'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('a transport error never leaks raw text to the driver', (tester) async {
    backend.sendError = const ServerError(
      code: 'HTTP_500',
      context: {'raw': 'DioException Hibernate could not extract ResultSet'},
    );
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Roadside check');
    await tapSend(tester);

    expect(find.textContaining('Dio'), findsNothing);
    expect(find.textContaining('Hibernate'), findsNothing);
    // Feedback now renders as the AppFeedback top overlay, not a SnackBar.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.widgetWithText(AppButton, 'SEND'), findsOneWidget);
    // Pump past the AppFeedback auto-dismiss timer (3s).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
