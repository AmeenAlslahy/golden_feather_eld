import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/localization/locale_provider.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

class _Locale extends StateNotifier<Locale> implements LocaleNotifier {
  _Locale(super.state);
  @override
  Future<void> setLocale(String languageCode) async => state = Locale(languageCode);
}

/// Certify tab failure copy: the driver sees a sentence in the app language,
/// never the repository's fixed English strings or a failure code.
void main() {
  setUpAll(() => registerFallbackValue(const DailyLogId(0)));

  final log = DailyLog(
    id: const DailyLogId(7),
    date: DateTime(2026, 9, 24),
    totalDrivingHours: 0,
    isFormComplete: true,
    isCertified: false,
  );

  Future<void> pump(WidgetTester tester, _Repo repo, String lang) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logRepositoryProvider.overrideWithValue(repo),
          localeProvider.overrideWith((ref) => _Locale(Locale(lang))),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: CertifyTab(selectedLog: log)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('readiness failure in Arabic shows Arabic, not the English fixed text',
      (tester) async {
    final repo = _Repo();
    when(() => repo.getReadiness(any())).thenAnswer((_) async =>
        const Left(ServerFailure(message: 'An unexpected error occurred')));

    await pump(tester, repo, 'ar');

    expect(find.text('An unexpected error occurred'), findsNothing);
    expect(find.text('تعذر إكمال الطلب. أعد المحاولة.'), findsOneWidget);
  });

  testWidgets('offline readiness shows the no-internet sentence, not "noInternet"',
      (tester) async {
    final repo = _Repo();
    when(() => repo.getReadiness(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await pump(tester, repo, 'en');

    expect(find.text('noInternet'), findsNothing);
    expect(
      find.text('No internet connection. Check the network and try again.'),
      findsOneWidget,
    );
  });
}
