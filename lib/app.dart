import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/quick_actions_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'features/hos/domain/engine/hos_rules_engine.dart';
import 'features/hos/presentation/providers/hos_provider.dart';
import 'l10n/app_localizations.dart';
import 'routes.dart';

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
            SnackBar(
              // UX-MEDIUM fix: Use locale-aware text instead of hard-coded Arabic
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'بدأت خدمة التتبع تلقائياً لتسجيل حالة القيادة'
                    : 'Tracking service started automatically to record duty status',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
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
            // UX-HIGH-01 fix: Default to English, not Arabic
            if (locale == null) return const Locale('en');
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            // UX-HIGH-01 fix: Fallback to English, not Arabic
            return const Locale('en');
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
