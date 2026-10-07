# خط الأساس (Baseline) لـ features/logs

تم القياس قبل البدء بأي تعديلات للمرحلة الأولى.

## 1. المقاييس الزمنية (Performance Benchmarks)
- **زمن فتح AuditTrailPage:**
  - 1000 سجل: ~30ms (TBD exact from test)
  - 5000 سجل: ~150ms (TBD exact from test)
- **زمن getRecentAuditEntries(100) (تحليل البيانات الخام):**
  - 1000 سجل: 12 ms
  - 5000 سجل: 17 ms
- **زمن _saveToBox (إعادة ترميز القائمة كاملة):**
  - حدث 1: ~727 us (0.7 ms)
  - 50 حدثاً: ~379 us (0.4 ms)
  *(ملاحظة: هذه الأرقام على بيئة حاسوب، وعلى أجهزة أندرويد قديمة قد تتضاعف 10 مرات).*
- **عدد مرات البناء (Builds) لـ `_EventRow` في InspectionPreview:** 
  - لـ 100 حدث: 100 Build دفعة واحدة.
  - لـ 200 حدث: 200 Build دفعة واحدة.

## 2. تصنيف استدعاءات `DateTime.now()` (الـ 15 استدعاء)
- **فئة أ (حرجة - للإصلاح في S1.1):** 6 استدعاءات.
  - `edit_log_page.dart` (3 مرات: `_formatCurrentTime`, `now = DateTime.now()`, إنشاء حدث `id`/`startTime`)
  - `unidentified_events_page.dart` (مرتان: `_StatsRow` و `now = DateTime.now()`)
  - `log_repository_impl.dart` (مرة واحدة: `createdAt` للـ Audit)
- **فئة ب (Fallback مشروع - استثناءات لسكربت الـ Lint):** 8 استدعاءات.
  - `daily_log.dart` (التحليل الافتراضي)
  - `log_edit.dart` (DTO Fallback)
  - `log_model.dart` (مرتان لـ Default IDs/Time)
  - `log_local_data_source.dart` (مرتان للـ Caching Fallback)
  - `log_repository_impl.dart` (المرة الثانية للـ Fallback)
  - `log_event_tile.dart` (تعليق Comment)
- **فئة ج (للـ i18n - للإصلاح في S4.6):** 
  - استدعاءات التنسيق المحلي التي لم تُستخدم فيها `intl` في `DailyLog`.

## 3. مقاييس واجهة المستخدم (UI/UX) و الـ dynamic
- **استخدام `dynamic` بشكل عشوائي:** `edit_log_page.dart` و `inspection_preview_page.dart` (موجود).
- **عدد نصوص اللغة الإنجليزية (Hardcoded):** `'Retry'`, `'Auto'`.
- **عناصر تفاعلية بحجم أقل من 48dp:** `IconButton` في `form_tab.dart` بحجم `18`.
- **تحذيرات `flutter analyze` في المشروع:** 0 تحذيرات (No issues found).

## 4. خطة اختبارات Sprint 1 (S1.1–S1.4)
- **الموقع:** ستُكتب في `test/widget/features/logs/` و `test/unit/features/logs/`.
- **السيناريوهات والبيانات الوهمية:**
  - **S1.1 (الوقت الموثوق):** `log_graph_test.dart` و `edit_log_page_test.dart`. سيتم عمل Mock لـ `timeAuthorityProvider` ليرجع وقتاً ثابتاً (مثلاً: `2026-01-01T12:00:00Z`). سيتم تمرير حدث بتوقيت UTC والتحقق من ظهوره بالتوقيت المحلي على الرسم.
  - **S1.2 ('Auto' المزيف):** `inspection_preview_test.dart`. سيمرر `DailyLog` بثلاثة أحداث: الأول `automatedDriving: true`، الثاني `false`، الثالث `null`. ونتأكد من وجود نصوص `Auto` و `Manual` و `—` توالياً.
  - **S1.3 (تكرار الأحداث):** `log_repository_test.dart` (Integration). يُحاكى إنشاء حدث محلي (Offline)، ثم يُرسل للخادم (Mock)، ثم يُعاد جلبه، ونتأكد من عدم تضاعف عدد الأحداث في القائمة المدمجة.
  - **S1.4 (الرسالة المزدوجة):** `log_detail_page_test.dart`. محاكاة عملية الحفظ والتحقق من استدعاء `ScaffoldMessenger` مرة واحدة فقط.

هذا الملف سيعتبر المرجع (Source of Truth) لتقييم نجاح المهام في الـ Sprints القادمة.

---
## تقدم Sprint A (يومياً)
**Day 1 output:**
- عدد `dynamic` في العقود: 8 (لم يتغير بعد).
- منطق `onPressed` المخترق للحدود: 6 ملفات (لم يتغير بعد).
- الاستيرادات المخترقة: 7 (لم يتغير بعد).
- حصيلة اليوم: 3 ملفات جديدة، 13 اختبار وحدة (Unit Tests)، 0 تعديل على الشاشات.

---
## Bug Register (Not Sprint A Scope)
- **BUG-001:** تعارض ألوان الحالة بين StatusColorHelper و InspectionPreview.
  - Helper: ON=gold, SB=yellow
  - Inspection: ON=yellow, SB=gold
  - التأثير: عرض غير متسق لنفس الحالة في شاشتين.
  - القرار: يُعالج في A5.2b (يوم 9) أو Sprint منفصل.
  - الأولوية: عالية (يُخرق الاتساق المطلوب).
