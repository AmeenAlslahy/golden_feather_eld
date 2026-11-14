import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_detail_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _Live303DvirBackend extends MockDvirBackend {
  static const liveResponse = {
    'id': 303,
    'inspectionKind': 'DVIR',
    'inspectionType': 'PRE_TRIP',
    'inspectionTime': '2026-11-07T23:52:56.562798Z',
    'status': 'DEFECTS_EXIST_SAFE',
    'vehicleCondition': 'DEFECTS_EXIST_SAFE',
    'operatingStatus': 'AVAILABLE',
    'result': 'CONDITIONAL',
    'odometer': 58767,
    'notes': 'فحص',
    'driver': {'id': 101, 'name': 'إبراهيم الشامي'},
    'vehicle': {
      'id': 503,
      'name': 'Peterbilt 579 #103',
      'uniqueId': '503',
    },
    'location': {
      'locationText': '15.3782154, 44.167181',
      'latitude': 15.3782154,
      'longitude': 44.167181,
    },
    'trailers': [
      {
        'trailerNumber': '5554',
        'detects': ['TR_KING_PIN', 'TR_COUPLING', 'TR_BRAKES'],
      },
    ],
    'detects': [
      {
        'id': 281,
        'assetType': 'VEHICLE',
        'assetIdentifier': '503',
        'itemCode': 'BRAKES_PARKING',
        'itemName': 'BRAKES_PARKING',
        'description': 'BRAKES_PARKING',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487143Z',
      },
      {
        'id': 282,
        'assetType': 'VEHICLE',
        'assetIdentifier': '503',
        'itemCode': 'BRAKES_SERVICE',
        'itemName': 'BRAKES_SERVICE',
        'description': 'BRAKES_SERVICE',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487158Z',
      },
      {
        'id': 283,
        'assetType': 'VEHICLE',
        'assetIdentifier': '503',
        'itemCode': 'STEERING_MECHANISM',
        'itemName': 'STEERING_MECHANISM',
        'description': 'STEERING_MECHANISM',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487162Z',
      },
      {
        'id': 284,
        'assetType': 'TRAILER',
        'assetIdentifier': '5554',
        'itemCode': 'TR_KING_PIN',
        'itemName': 'TR_KING_PIN',
        'description': 'TR_KING_PIN',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487166Z',
      },
      {
        'id': 285,
        'assetType': 'TRAILER',
        'assetIdentifier': '5554',
        'itemCode': 'TR_COUPLING',
        'itemName': 'TR_COUPLING',
        'description': 'TR_COUPLING',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487197Z',
      },
      {
        'id': 286,
        'assetType': 'TRAILER',
        'assetIdentifier': '5554',
        'itemCode': 'TR_BRAKES',
        'itemName': 'TR_BRAKES',
        'description': 'TR_BRAKES',
        'severity': 'LOW',
        'stage': 'OPEN',
        'outOfService': false,
        'createdAt': '2026-11-07T23:52:57.487201Z',
      },
    ],
    'photos': [],
    // 1x1 transparent PNG base64
    'signature': {
      'signed': true,
      'signedAt': '2026-11-07T23:52:56.562798Z',
      'signatureData':
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    },
    'certified': true,
    'locked': true,
    'retentionUntil': '2027-02-07',
  };

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    return ok(liveResponse);
  }
}

Widget _harness({required Widget child, Locale locale = const Locale('ar')}) {
  final backend = _Live303DvirBackend();
  return ProviderScope(
    overrides: [
      activeBackendProvider.overrideWithValue(MockAdapter()),
      dvirBackendProvider.overrideWithValue(backend),
      networkInfoProvider.overrideWithValue(_OnlineNetwork()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DvirDetailPage renders live report 303 correctly in Arabic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(child: const DvirDetailPage(dvirId: '303')),
    );
    await tester.pumpAndSettle();

    // Vehicle display shows both name and ID
    expect(find.text('Peterbilt 579 #103 (503)'), findsOneWidget);

    // Condition status shows "توجد عيوب" in Arabic, never "غير معروف"
    expect(find.text('توجد عيوب'), findsWidgets);
    expect(find.text('غير معروف'), findsNothing);

    // False mechanic section does NOT appear
    expect(find.text('شهادة الميكانيكي'), findsNothing);

    // Retention date from server
    expect(find.text('2027-02-07'), findsOneWidget);

    // Scroll to see defects and signature
    await tester.scrollUntilVisible(find.text('Brakes Parking'), 500);
    expect(find.text('Brakes Parking'), findsOneWidget);
    expect(find.text('Brakes Service'), findsOneWidget);
    expect(find.text('Steering Mechanism'), findsOneWidget);
    expect(find.text('مسمار التثبيت (King Pin)'), findsOneWidget);
  });
}
