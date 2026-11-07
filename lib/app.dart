import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/local_storage_service.dart';
import 'core/utils/logger.dart';
import 'core/utils/startup_profiler.dart';
import 'app/services/quick_actions_initializer.dart';
import 'routes.dart';
import 'core/widgets/app_feedback.dart';
import 'features/hos/presentation/providers/hos_provider.dart';
import 'features/hos/presentation/providers/status_dashboard_providers.dart';
import 'features/hos/presentation/providers/dashboard_reconciler.dart';
import 'features/hos/presentation/providers/hos_engine_provider.dart';
import 'features/hos/data/providers/status_dashboard_repository_providers.dart';
import 'features/logs/data/datasources/log_local_data_source.dart';
import 'features/logs/presentation/providers/log_detail_tab_provider.dart';
import 'features/logs/presentation/providers/log_draft_signature_provider.dart';
import 'features/logs/presentation/providers/unidentified_events_provider.dart';
import 'features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'features/account/data/providers/rules_screen_providers.dart';
import 'features/account/presentation/providers/account_provider.dart';
import 'features/codriver/data/providers/codriver_repository_providers.dart';
import 'features/inspection/data/providers/inspection_repository_providers.dart';
import 'features/hos/presentation/providers/recap_provider.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'features/hos/domain/engine/hos_rules_engine.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// P0 عزل السائقين — مسح ما يُبنى منه الـ tracker ثم إبطاله.
///
/// الترتيب مقصود: مسح أولاً ثم إبطال، حتى لا يُعاد بناء الـ tracker من
/// تفضيلات السائق السابق بينما المسح ما زال جارياً. الفشل هنا لا يُسقط
/// شيئاً: أسوأ حالة هي بقاء القيمة القديمة (سلوك ما قبل الإصلاح).
Future<void> _clearDriverScopedTracking(WidgetRef ref) async {
  try {
    await ref.read(localStorageProvider).clearDutyTrackingState();
    // لا يُمسح اختيار المركبة: صار محفوظاً موسوماً بمالكه
    // (`driverId|vehicleId`) في VehicleNotifier. مسحه هنا كان يجعل كل
    // إقلاع/إعادة دخول يطلب من السائق الاختيار من جديد، كما أن مالكاً
    // آخر لا يقرأ اختيار غيره بسبب الوسم.
    await ref.read(logLocalDataSourceProvider).clearPeriods();
    ref.invalidate(dutyStatusTrackerProvider);
  } catch (e) {
    AppLogger.warning('Driver-scoped tracking reset failed: $e');
  }
}

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
    // M0 — قياس أول إطار (حارس داخلي: الاستدعاءات المتكررة بلا أثر).
    StartupProfiler.scheduleFirstFrameMark();
    // P0 leak fix: تحديث مزودات HOS الخاصة بالسائق عند تأسيس هوية فقط —
    // لا أثناء الانتقال (وإلا أُعيد الإنشاء وأُطلقت قراءات محكومة بالفشل
    // أثناء logout). يشمل إعادة login نفس السائق (epoch مختلف).
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (shouldRefreshSessionProviders(previous, next)) {
        ref.invalidate(statusDashboardProvider);
        ref.invalidate(recapProvider);
        ref.invalidate(hosStatusProvider);

        // 🔒 عزل المحرك بين السائقين.
        //
        // `hosEngineProvider` غير `autoDispose`، فالمحرك — ومعه آلة
        // الحالة المرطَّبة من فترات **السائق السابق** — كان يبقى حيّاً
        // بعد تبديل السائق. وأي لوحة أوفلاين تُبنى منه
        // (`_buildOfflineDashboardFromEngine`) كانت تعرض رصيد السائق
        // الأول للحساب الثاني.
        //
        // إبطال المحرك يُنشئ آلة حالة فارغة جديدة، ويعيد الترطيب من
        // فترات السائق الجديد عبر `hosStoredPeriodsProvider`
        // (وهو مرتبط بالجلسة فيتمسّح معه).
        ref.invalidate(hosEngineProvider);
        ref.invalidate(hosStoredPeriodsProvider);

        // 🧷 P0 عزل التتبع — الـ tracker كان يبقى حياً بعد التبديل
        // (provider غير autoDispose) وحالته تُقرأ من تفضيلات **عامة**
        // بلا مالك: السائق التالي يبدأ من حالة السائق السابق المعلنة.
        ref.invalidate(dutyStatusTrackerProvider);

        // 🧷 عزل حالة شاشات السجلات: الأحداث غير المحددة (غير autoDispose
        // سابقاً)، مسودات التوقيع العابرة للشاشات، وتبويب التفاصيل العالمي.
        ref.invalidate(unidentifiedEventsProvider);
        ref.invalidate(logDraftSignatureProvider);
        ref.invalidate(logDetailTabProvider);

        // 🧹 مسح الكاش المحلي عند تبديل هوية السائق.
        //
        // السبب: `hos_dashboard_snapshot` و `vehicle_list_cache` مخزَّنان على
        // القرص بلا ربط بمعرّف السائق. كان تسجيل الخروج يمسح الجلسة فقط،
        // فيبقى سجل السائق السابق على القرص. ولو دخل سائق آخر **أونلاين**،
        // كانت شاشته تُعرض من ذلك الكاش قبل وصول رد الخادم — تسريب عبر
        // الجلسات.
        //
        // ملاحظة: تسجيل الدخول نفسه يتطلب اتصالاً، لذا السائق الجديد
        // لا يستطيع الدخول بلا شبكة أصلاً. المسح هنا يغطي نافذة الالتقاط
        // بين تسجيل الخروج وتسجيل الدخول التالي.
        final nextDriverId = next.user?.id;
        if (previous?.user?.id != nextDriverId) {
          ref.read(dashboardLocalCacheProvider).clear();
          ref.read(vehicleLocalCacheProvider).clear();
          ref.read(coDriverLocalCacheProvider).clear();
          ref.read(inspectionLocalCacheProvider).clear();
          ref.read(rulesScreenLocalCacheProvider).clear();

          // 🧷 P0 عزل السائقين — مسح الحالة القانونية الحية وفترات HOS
          // المخزنة (بلا مالك) قبل أن يُبنى tracker السائق الجديد.
          // غير منتظر عمداً: لا نُجمّد الواجهة على كتابة تفضيلات، والـ
          // إبطال يقع **بعد** اكتمال المسح داخل الدالة.
          unawaited(_clearDriverScopedTracking(ref));
        }

        if (next.isAuthenticated && next.user != null) {
          unawaited(ref.read(accountProvider.notifier).fetchMyAccount());
        }
      }
    });

    // Global listener for automatic tracking UI side-effects
    ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
      if (next is HosEngineReady) {
        final prevStatus = (previous is HosEngineReady)
            ? previous.update.currentStatus
            : null;
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

    // ♻️ معدّل لوحة الحالة: جلب من الخادم كل 5 دقائق + جلب فوري عند
    // العودة من الخلفية.
    //
    // `watch` عمداً (لا `read`): نريد إنشاءه مرة واحدة يبقى طوال عمر
    // التطبيق، لا عند أول شاشة فقط. لو استُدعي مرة واحدة لالتحقق من
    // الوجود فقط لأُهمل لاحقاً وتوقفت النبضات.
    ref.watch(dashboardReconcilerProvider);

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
