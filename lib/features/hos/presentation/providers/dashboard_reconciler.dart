import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import 'status_dashboard_providers.dart';

/// معدّل لوحة الحالة: يُجلب من الخادم كل [AppConstants.dashboardRefreshInterval]
///، وفور العودة من الخلفية.
///
/// ### لماذا هذا موجود
///
/// كان المشروع **بلا أي تعامل مع دورة حياة التطبيق**:
///
/// ```
/// AppLifecycleState | WidgetsBindingObserver | didChangeAppLifecycleState
/// → 0 نتيجة في 424 ملف
/// ```
///
/// ولا جلب دوري للوحة: `AppConstants.syncInterval` كان ثابتاً ميتاً بلا
/// أي مستدعٍ. فكان التطبيق يعرض **نفس الأرقام من لحظة فتحه** مهما بقي
/// مفتوحاً، وعلى السائق أن يفتحه بنفسه ليعرف أين وصل.
///
/// والضغط أثقل: لأن العدّاد لا يصحّحه إلا عند الجلب، فالأرقام
/// المعروضة كانت ثابتة بينما الخادم يواصل الحساب — فيفترق الرقمان.
/// والفرق يميل دائماً في صالح السائق (التطبيق أقل) = رصيد قانوني
/// مُبالَغ فيه.
///
/// ### القاعدة
///
/// - **الخادم هو المرجع القانوني.** التطبيق يحسب محلياً حتى لا
///   يُغرق الخادم، ثم يعود كل 5 دقائق ليصحّح.
/// - الجلب لا يجري في الخلفية إطلاقاً: `Timer.periodic` في Dart لا
///   يضمن التنفيذ، فالعمل في الخلفية استنزاف بلا فائدة. نُوقفه ونستأنفه.
class DashboardReconciler with WidgetsBindingObserver {
  DashboardReconciler(this._refresh);

  /// جلب اللوحة من الخادم (لا يلمس حالة التحميل ولا يعرض خطأ).
  final Future<void> Function() _refresh;

  Timer? _timer;
  bool _foreground = true;

  Duration get interval => AppConstants.dashboardRefreshInterval;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _arm();
    AppLogger.info(
      'DashboardReconciler started (every ${interval.inMinutes} min)',
    );
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _disarm();
  }

  void _arm() {
    _disarm();
    _timer = Timer.periodic(interval, (_) => _tick('periodic'));
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(String reason) {
    // نبضة في الخلفية = لا فائدة (المعالجات موقوفة) ومهدور شبكة.
    if (!_foreground) return;
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        final wasBackgrounded = !_foreground;
        _foreground = true;
        if (wasBackgrounded) {
          // 🔴 الفارق قد يكون ساعات. بدون هذا الجلب الفوري يبقى السائق
          // ينظر إلى أرقام سبقت الحقيقة بوقت طويل، ويُظن أن
          // رصيده أكبر مما هو — وهذا أخطر خطأ في التطبيق كله.
          _tick('resumed');
          _arm(); // إعادة ضبط العدّاد: المؤقت لا يعوّض نبضات فوتهت.
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _disarm();
    }
  }
}

/// مزود المعدّل — يُنشأ مرة واحدة عند بناء التطبيق ويبقى طوال العمر.
///
/// `Provider` عادي (لا `autoDispose`) عمداً: لو كان `autoDispose` لأُعيد
/// إنشاؤه مع كل خروج من الشاشة ومات مراقب دورة الحياة مع أول unmount.
final dashboardReconcilerProvider = Provider<DashboardReconciler>((ref) {
  final reconciler = DashboardReconciler(() async {
    // `read` لا `watch`: نبضة الجلب يجب ألا تُعيد بناء المعدّل (حلقة).
    await ref.read(statusDashboardProvider.notifier).reconcileWithServer();
  });
  reconciler.start();
  ref.onDispose(reconciler.stop);
  return reconciler;
});
