import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/constants/app_constants.dart';
import 'app/services/quick_actions_initializer.dart';
import 'routes.dart';
import 'features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'features/hos/domain/engine/hos_rules_engine.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// تطبيق Golden Feather ELD الرئيسي
class GoldenFeatherApp extends ConsumerWidget {
  const GoldenFeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global listener for automatic tracking UI side-effects
    ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
      if (next is HosEngineReady) {
        final prevStatus =
            (previous is HosEngineReady) ? previous.update.currentStatus : null;
        if (next.update.currentStatus == DutyStatus.driving &&
            prevStatus != DutyStatus.driving) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('بدأت خدمة التتبع تلقائياً لتسجيل حالة القيادة'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          // معلومات التطبيق
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // الترجمة
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('ar');
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('ar');
          },

          // الثيم
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,

          // التوجيه
          routerConfig: ref.watch(routerProvider),

          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                const QuickActionsInitializer(),
              ],
            );
          },
        );
      },
    );
  }
}
