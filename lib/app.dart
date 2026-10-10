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
import 'core/widgets/app_feedback.dart';
import 'features/hos/presentation/providers/hos_provider.dart';
import 'features/hos/presentation/providers/status_dashboard_providers.dart';
import 'features/hos/presentation/providers/recap_provider.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'features/hos/domain/engine/hos_rules_engine.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// P0 leak fix — قرار إبطال مزودات الجلسة (pure وقابل للاختبار):
/// - أثناء الانتقال: أبداً (يمنع إعادة الإنشاء + GET أثناء logout).
/// - عند تأسيس هوية (id أو جيل جديدان): نعم — ويشمل ذلك إعادة login
///   نفس السائق (id ثابت لكن epoch جديد).
bool shouldRefreshSessionProviders(AuthState? previous, AuthState next) {
  if (next.transitioning) return false;
  return previous?.user?.id != next.user?.id ||
      previous?.sessionEpoch != next.sessionEpoch;
}

/// تطبيق Golden Feather ELD الرئيسي
class GoldenFeatherApp extends ConsumerWidget {
  const GoldenFeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P0 leak fix: تحديث مزودات HOS الخاصة بالسائق عند تأسيس هوية فقط —
    // لا أثناء الانتقال (وإلا أُعيد الإنشاء وأُطلقت قراءات محكومة بالفشل
    // أثناء logout). يشمل إعادة login نفس السائق (epoch مختلف).
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (shouldRefreshSessionProviders(previous, next)) {
        ref.invalidate(statusDashboardProvider);
        ref.invalidate(recapProvider);
        ref.invalidate(hosStatusProvider);
      }
    });

    // Global listener for automatic tracking UI side-effects
    ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
      if (next is HosEngineReady) {
        final prevStatus =
            (previous is HosEngineReady) ? previous.update.currentStatus : null;
        if (next.update.currentStatus == DutyStatus.driving &&
            prevStatus != DutyStatus.driving) {
          final feedbackContext = rootNavigatorKey.currentContext;
          if (feedbackContext != null) {
            AppFeedback.success(
              feedbackContext,
              'بدأت خدمة التتبع تلقائياً لتسجيل حالة القيادة',
            );
          }
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
