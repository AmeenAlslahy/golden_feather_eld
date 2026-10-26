import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/app/di/app_providers.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_auth_backend.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/auth_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/splash_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockStorage extends Mock implements LocalStorageService {
  @override
  String get language => 'en';
  @override
  String get serverUrl => 'https://snsoft.cloud';
  @override
  String get backendType => 'eld';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AST-001: Image cache width/height optimization', () {
    testWidgets('SplashPage Image.asset decodes with ResizeImage dimensions 360x360', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SplashPage(),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.width, 120);
      expect(imageWidget.height, 120);

      // Verify that cacheWidth and cacheHeight configure ResizeImage
      expect(imageWidget.image, isA<ResizeImage>());
      final resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.width, 360);
      expect(resizeImage.height, 360);
      expect(resizeImage.imageProvider, isA<AssetImage>());
      final assetImage = resizeImage.imageProvider as AssetImage;
      expect(assetImage.assetName, 'assets/images/ic_launcher.png');
    });

    testWidgets('AuthPage Image.asset decodes with ResizeImage dimensions 360x360', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            traccarAuthRepositoryProvider.overrideWithValue(_MockRepo()),
            localStorageProvider.overrideWithValue(_MockStorage()),
            authBackendProvider.overrideWithValue(const MockAuthBackend()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const AuthPage(),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.width, 120);
      expect(imageWidget.height, 120);

      // Verify that cacheWidth and cacheHeight configure ResizeImage
      expect(imageWidget.image, isA<ResizeImage>());
      final resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.width, 360);
      expect(resizeImage.height, 360);
      expect(resizeImage.imageProvider, isA<AssetImage>());
      final assetImage = resizeImage.imageProvider as AssetImage;
      expect(assetImage.assetName, 'assets/images/ic_launcher.png');
    });
  });
}
