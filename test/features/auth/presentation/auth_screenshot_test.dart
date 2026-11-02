import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/app/di/app_providers.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_auth_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/app_logo.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/pages/auth_page.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_mode_provider.dart';
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

class _DiskAssetBundle extends CachingAssetBundle {
  static final instance = _DiskAssetBundle();

  @override
  Future<ByteData> load(String key) async {
    if (key.contains('ic_launcher.png')) {
      final bytes = await File('assets/images/ic_launcher.png').readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    final file = File(key);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    return rootBundle.load(key);
  }
}

class _RealImageBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) async {
    if (getTargetSize != null) {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final targetSize = getTargetSize(descriptor.width, descriptor.height);
      return descriptor.instantiateCodec(
        targetWidth: targetSize.width,
        targetHeight: targetSize.height,
      );
    }
    return ui.instantiateImageCodecFromBuffer(buffer);
  }
}

void main() {
  _RealImageBinding();

  setUpAll(() async {
    try {
      final robotoLoader = FontLoader('Roboto');
      final regularFile = File('assets/fonts/google_fonts/Roboto-Regular.ttf');
      if (regularFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(regularFile.readAsBytesSync().buffer)));
      }
      final mediumFile = File('assets/fonts/google_fonts/Roboto-Medium.ttf');
      if (mediumFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(mediumFile.readAsBytesSync().buffer)));
      }
      final boldFile = File('assets/fonts/google_fonts/Roboto-Bold.ttf');
      if (boldFile.existsSync()) {
        robotoLoader.addFont(Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)));
      }
      await robotoLoader.load();
    } catch (_) {}

    try {
      final iconFile = File(r'D:\Flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
      if (iconFile.existsSync()) {
        final iconLoader = FontLoader('MaterialIcons');
        iconLoader.addFont(Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)));
        await iconLoader.load();
      }
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> precacheLogo(WidgetTester tester) async {
    await tester.runAsync(() async {
      final image = AssetImage(AppLogo.assetPath, bundle: _DiskAssetBundle.instance);
      final completer = Completer<ImageInfo>();
      final stream = image.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool syncCall) {
          completer.complete(info);
          stream.removeListener(listener);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          completer.completeError(error, stackTrace);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(
        const Duration(seconds: 2),
      );
    });
    await tester.pump();
  }

  Future<void> captureScreen({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('build/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final file = File('build/screenshots/$filename');
      await file.writeAsBytes(bytes);

      const artifactDir = r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget buildHarness({
    required GlobalKey repaintKey,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    AuthMode initialMode = AuthMode.login,
  }) {
    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          traccarAuthRepositoryProvider.overrideWithValue(_MockRepo()),
          localStorageProvider.overrideWithValue(_MockStorage()),
          authBackendProvider.overrideWithValue(const MockAuthBackend()),
          authModeProvider.overrideWith((ref) => initialMode),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: DefaultAssetBundle(
            bundle: _DiskAssetBundle.instance,
            child: const AuthPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('Capture 6 requested screens for visual review', (tester) async {
    tester.view.physicalSize = const Size(375 * 2.0, 812 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await precacheLogo(tester);

    // 1. Login — Light
    final key1 = GlobalKey();
    await tester.pumpWidget(buildHarness(repaintKey: key1, theme: AppTheme.light));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key1, filename: 'auth_login_light.png');

    // 2. Login — Dark
    final key2 = GlobalKey();
    await tester.pumpWidget(buildHarness(repaintKey: key2, theme: AppTheme.dark));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key2, filename: 'auth_login_dark.png');

    // 3. Login Validation Error — Light
    final key3 = GlobalKey();
    await tester.pumpWidget(buildHarness(repaintKey: key3, theme: AppTheme.light));
    await tester.pumpAndSettle();
    final loginBtnLight = find.widgetWithText(AppButton, 'Login');
    await tester.ensureVisible(loginBtnLight);
    await tester.tap(loginBtnLight);
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key3, filename: 'auth_login_validation_light.png');

    // 4. Login Validation Error — Dark
    final key4 = GlobalKey();
    await tester.pumpWidget(buildHarness(repaintKey: key4, theme: AppTheme.dark));
    await tester.pumpAndSettle();
    final loginBtnDark = find.widgetWithText(AppButton, 'Login');
    await tester.ensureVisible(loginBtnDark);
    await tester.tap(loginBtnDark);
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key4, filename: 'auth_login_validation_dark.png');

    // 5. Forgot Password — Light
    final key5 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key5,
      theme: AppTheme.light,
      initialMode: AuthMode.forgotPassword,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key5, filename: 'auth_forgot_password_light.png');

    // 6. Forgot Password — Dark
    final key6 = GlobalKey();
    await tester.pumpWidget(buildHarness(
      repaintKey: key6,
      theme: AppTheme.dark,
      initialMode: AuthMode.forgotPassword,
    ));
    await tester.pumpAndSettle();
    await captureScreen(tester: tester, key: key6, filename: 'auth_forgot_password_dark.png');
  });
}
