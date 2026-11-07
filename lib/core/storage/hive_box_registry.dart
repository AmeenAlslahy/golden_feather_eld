import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';

/// سجل فتح صناديق Hive عند الطلب (lazy).
///
/// **السبب:** كان `LocalDatabaseService.init()` يفتح خمسة صناديق متتالية
/// قبل `runApp`، فمنع أول إطار لأكثر من 13 ثانية على جهاز الاختبار.
/// الآن لا يُفتح أي صندوق حتى يطلبه مستهلكه فعلياً، مع إعادة استخدام
/// نفس الـ Future إذا طلبه أكثر من مستهلك في نفس اللحظة (بلا فتح مزدوج).
final Map<String, Future<Box<dynamic>>> _pendingOpens =
    <String, Future<Box<dynamic>>>{};

/// هل هيّأ Hive مسار تخزينه بعد (`Hive.init` أو `Hive.initFlutter`)؟
///
/// **لماذا هذا الفحص موجود:** في Hive 2.2.3، استدعاء `Hive.openBox` قبل
/// التهيئة يُنتج خطأين: واحداً على الـ Future المُعاد (يمكن معالجته) وآخر
/// **غير معالَج** على مُكمّل داخلي (`_openingBoxes`) لا يستمع إليه أحد،
/// فيُسقط zone الاختبار حتى لو عالج المستدعي الـ Future. الحل الوحيد هو
/// عدم استدعاء `Hive.openBox` إطلاقاً قبل التهيئة.
///
/// `HiveInterface` لا يكشف حالة التهيئة، و`HiveImpl.homePath` هو المؤشر
/// الوحيد المتاح. الاختبارات التي تستدعي `Hive.init` مباشرة تُعتبر مهيّأة
/// أيضاً، فلا نحتاج علماً خاصاً بنا.
bool get isHiveInitialized {
  // `HiveInterface` لا يكشف الحالة. نقرأ `homePath` من التنفيذ الفعلي عبر
  // dynamic بدل استيراد `package:hive/src/hive_impl.dart` (استيراد داخلي
  // ممنوع) أو علم خاص بنا (لأن الاختبارات تهيّئ Hive مباشرة).
  // إن تغيّر التنفيذ الداخلي لاحقاً نُعيد true حتى لا نحجب الفتح بلا داعٍ.
  try {
    return (Hive as dynamic).homePath != null;
  } catch (_) {
    return true;
  }
}

/// يضمن أن الصندوق [name] مفتوح ويعيده.
///
/// - إذا كان مفتوحاً مسبقاً (مثل الاختبارات التي تستدعي `Hive.openBox`
///   مباشرة) يُعاد فوراً بلا أي عمل.
/// - إذا لم يُهيّأ Hive بعد يُعاد Future فاشل بدل إسقاط zone (انظر
///   [isHiveInitialized]). المستدعي يقرر: انتظار أو تجاهل كـ cache miss.
/// - إذا كان الفتح جارياً يُعاد نفس الـ Future.
/// - يسجّل زمن الفتح وعدد الصفوف مرة واحدة لكل صندوق — بيانات قياس فقط،
///   تُستخدم لتقرير إن كان الصندوق يحتاج تقليماً/تقسيمًا لاحقاً.
Future<Box<T>> ensureHiveBox<T>(String name) {
  if (Hive.isBoxOpen(name)) {
    return Future<Box<T>>.value(Hive.box<T>(name));
  }

  if (!isHiveInitialized) {
    return Future<Box<T>>.error(
      StateError(
        'Hive is not initialized; call Hive.init() or Hive.initFlutter() '
        'before opening box "$name".',
      ),
    );
  }

  final pending = _pendingOpens[name];
  if (pending != null) {
    return pending.then((box) => box as Box<T>);
  }

  final watch = Stopwatch()..start();
  final Future<Box<T>> future;
  try {
    future = Hive.openBox<T>(name);
  } catch (e, st) {
    // Hive يرمي متزامناً إذا لم يُهيّأ (`Hive.init`). نحوّله إلى Future
    // فاشل حتى يتمكن المستدعون من التعامل معه بـ await/try أو onError،
    // بدل أن يتسرب كخطأ متزامن من دالة يُفترض أنها غير متزامنة.
    return Future<Box<T>>.error(e, st);
  }
  _pendingOpens[name] = future;

  return future
      .then((box) {
        AppLogger.info(
          'HIVE open "$name" in ${watch.elapsedMilliseconds}ms '
          '(${box.length} entries)',
        );
        return box;
      })
      .whenComplete(() => _pendingOpens.remove(name));
}
