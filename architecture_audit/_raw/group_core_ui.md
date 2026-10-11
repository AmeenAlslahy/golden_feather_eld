# Group: core/theme + core/widgets — Layer/Responsibility Audit

> نطاق التدقيق: `lib/core/theme/**` (10 ملفات) و `lib/core/widgets/**` (15 ملفاً) = **25 ملفاً**، تمت قراءتها بالكامل.
> قاعدة التشخيص المعتمدة: نظام التصميم داخل `core/` **ليس مخالفة** بذاته. لا يُبلَّغ عن "`core/widgets` يستورد `flutter/material`". لا يُبلَّغ إلا عن **مسؤولية موضوعة خطأ** أو **تبعية معكوسة**.
> جميع الأدلة أدناه مقتبسة حرفياً من الملفات مع أرقام أسطر حقيقية.

---

## A. Per-file findings

### `lib/core/theme/app_colors.dart` (155 lines, non-empty 112)
- Actual responsibilities: رموز `Color(0x…)` للهوية (ذهبي/أسود)، عائلات تباين الحالات (نص فاتح/داكن/خلفيات)، المحايدات، وألوان الوضع الداكن، مع دوال `xxxFor(Brightness)`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-007 (مُستهلَك كمرجع)، CUI-013 (الجهة المقابلة)

### `lib/core/theme/app_decorations.dart` (71 lines, non-empty 64)
- Actual responsibilities: مصانع `BoxDecoration` المشتركة (`card` / `tinted` / `solid` / `band` / `outlined`). تستهلك `AppColors` + `AppRadius` + `AppShadows` فقط.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-009 (لم يُستعمل في `eld_card.dart`)

### `lib/core/theme/app_radius.dart` (31 lines, non-empty 22)
- Actual responsibilities: تسعة رموز زوايا (`button`, `card`, `pill`, `badge`, …) بلا أي استيراد.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: none

### `lib/core/theme/app_shadows.dart` (28 lines, non-empty 25)
- Actual responsibilities: رمزان للظلال (`card`, `raised`)، مع قرار تصميمي موثَّق (إخفاء الظل في الوضع الداكن).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-006 (سلوك موازٍ في `app_feedback.dart` يتجاهله)

### `lib/core/theme/app_spacing.dart` (18 lines, non-empty 16)
- Actual responsibilities: سلّم المسافات + `screenPadding` / `cardPadding` / `buttonHeight` / `dividerHeight` / `iconSize`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-018 (غير مُحترَم في `app_status_pill.dart`)

### `lib/core/theme/app_styles.dart` (244 lines, non-empty 234)
- Actual responsibilities: `ThemeExtension<AppStyles>` بستة عشر نمطاً دلالياً، مبنيّة من `AppTypography` + `AppColors` عبر `fromBrightness`، مع `copyWith` و`lerp` صحيحين.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-018 (`fontSize: 18` مكتوبة يدوياً)، CUI-020 (دالتا توافق ميّتة)

### `lib/core/theme/app_theme.dart` (222 lines, non-empty 211)
- Actual responsibilities: `ThemeData light` و`ThemeData dark` كاملان (ColorScheme، AppBar، Card، خمسة أنواع أزرار، InputDecoration، SnackBar، Divider، BottomNav، Radio).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-007
- **لا توجد أي قيم بيئة ولا نقاط نهاية ولا ألوان ذات دلالة تنظيمية** — كل الألوان هوية/محايدة/حالات عامة. مُجيب على السؤال 6: **لا مخالفة في هذا الجانب**.

### `lib/core/theme/app_theme_provider.dart` (48 lines, non-empty 40)
- Actual responsibilities: `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` + **ترحيل بيانات من `SharedPreferences` القديم** + استدعاء `LocalStorageService`.
- Declared layer / actual layer: معلن كـ theme state -> فعلياً **theme state + data migration + two storage backends**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-008

### `lib/core/theme/app_typography.dart` (75 lines, non-empty 67)
- Actual responsibilities: سلّم الخطوط + `TextTheme` فاتح/داكن من مصدر واحد (`_base` ثم `_colored`).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-020 (`fontFamilyIOS` رمز ميّت)، CUI-018 (مُتجاوَز في widgets)

### `lib/core/theme/press_feedback.dart` (34 lines, non-empty 30)
- Actual responsibilities: `InkRipple.splashFactory`، مولّد `overlayColor` حسب حالة pressed/hovered/focused، `pressed()` للدمج، وحبرَي `ink` / `inkOnDark`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-011 (مُتجاوَز في `app_button.dart`)، CUI-014 (مُتجاوَز في `eld_info_row.dart`)، CUI-007 (رمزَي حبر خارج `AppColors`)

### `lib/core/widgets/app_button.dart` (194 lines, non-empty 174)
- Actual responsibilities: زر موحّد بحالات pressed/disabled/loading، بأشكال Stadium، وتطبيق `AppStyles.button`.
- Declared layer / actual layer: core/design-system -> core/design-system مع **تسرّب نوايا ELD في الـAPI**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-003، CUI-011، CUI-018

### `lib/core/widgets/app_feedback.dart` (116 lines, non-empty 104)
- Actual responsibilities: قناة إشعار عبر `OverlayEntry` مع `Dismissible` + `GestureDetector` + **مؤخّر ذاتي الإزالة 3 ثوانٍ** + **متغير عام ثابت `_activeEntry`**.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **خدمة عرض عامة داخل مجلد widgets**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-006
- مُجيب على السؤال 4: **لا نصوص مستخدم مُشفّرة داخل الملف** (يستقبل `message` من المستدعي)، لكن **يتجاوز `snackBarTheme`** المعرَّف في `app_theme.dart:141-151` ويستخدم قيم بصرية مُشفّرة.

### `lib/core/widgets/app_signature_canvas.dart` (232 lines, non-empty 218)
- Actual responsibilities: لوحة توقيع + غلاف `FormField` (`AppSignatureFormField`). **لا قواعد عمل، ولا حفظ، ولا شبكة، ولا إدخال/إخراج بيانات** — تحقّقت من الملف كاملاً (232 سطراً).
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-012
- **COMPLIANT مع السؤال 8**: لا يتجاوز العرض. ومُعرَّف بالكامل (`loc.drawYourSignatureHere`, `loc.clearSignature` في السطرين 135 و172).

### `lib/core/widgets/app_status_badge.dart` (96 lines, non-empty 89)
- Actual responsibilities: شارة حالة عامة بأربعة أنواع (`success/error/warning/info`) + اختيار زوج تباين حسب `Brightness`. **دلالات عامة لا تعني HOS.**
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-010، CUI-018 (`fontSize: 11`)، CUI-002 (مُتجاوَز داخل core نفسه)
- **COMPLIANT مع السؤال 2**: لا قواعد HOS ولا عتبات تنظيمية.

### `lib/core/widgets/app_status_pill.dart` (53 lines, non-empty 49)
- Actual responsibilities: شارة صغيرة (أيقونة + نص) بخلفية مشتقّة من لون المقدمة عبر `AppDecorations.tinted`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-010، CUI-018، CUI-016 (مُعاد تنفيذها يدوياً في `active_defects_section.dart`)

### `lib/core/widgets/app_text_field.dart` (125 lines, non-empty 121)
- Actual responsibilities: غلاف `TextFormField` يقرأ `theme.inputDecorationTheme` ويمرّر كل خصائصه. لا يستورد `AppColors` إطلاقاً — يعتمد على الثيم.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-016 (يُعاد تنفيذه بشكل مسطّح في `DvirFlatTextField`)
- **COMPLIANT مع السؤال 7**: لا نصوص مُشفّرة إطلاقاً — كلها معاملات.

### `lib/core/widgets/connection_status_indicator.dart` (101 lines, non-empty 92)
- Actual responsibilities: `ConsumerWidget` يراقب مزوّد تتبّع حيّ، **ينتقل إلى `AppRoutes.connection`**، ويبني شارة حالة يدوياً.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **core widget مربوط ب-feature domain + الموجّه العام**.
- Architectural status: **CRITICAL**
- Issue IDs: CUI-001، CUI-002، CUI-016

### `lib/core/widgets/critical_error_app.dart` (58 lines, non-empty 55)
- Actual responsibilities: تطبيق طوارئ كامل (`MaterialApp` متداخل) يُعرض عند فشل التهيئة في `main.dart:58`.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **root application + شاشة طوارئ**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-005

### `lib/core/widgets/dashed_line_painter.dart` (24 lines, non-empty 21)
- Actual responsibilities: `CustomPainter` يرسم خطاً متقطعاً أفقياً بلون مُمرَّر.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-015

### `lib/core/widgets/eld_card.dart` (41 lines, non-empty 38)
- Actual responsibilities: `Card` themed مع `InkWell`. **يستهلك `child` المُمرَّر فقط — لا منطق ELD إطلاقاً.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق؛ البادئة `Eld` تسمية فقط)
- Architectural status: **MINOR**
- Issue IDs: CUI-009، CUI-017
- **COMPLIANT مع السؤال 2**.

### `lib/core/widgets/eld_date_paginator.dart` (73 lines, non-empty 69)
- Actual responsibilities: شريط تنقّل بين تاريخين (سابق/تالٍ) مع مؤشّر تحميل. **يستهلك `dateLabel` و`canGoOlder/Newer` كمعاملات — لا يقيّم أي تاريخ ولا يعبر منتصف الليل.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget مع **تسريب رمز دلالي خاص بمعاينة التفتيش**.
- Architectural status: **MINOR**
- Issue IDs: CUI-017، CUI-021
- **COMPLIANT مع السؤال 2** (لا منطق نطاق ولا HOS).

### `lib/core/widgets/eld_events_table.dart` (187 lines, non-empty 178)
- Actual responsibilities: جدول أحداث من ستّة أعمدة، يستقبل `List<EldTableRow>` وكل حقوله `String` جاهزة. **صفر استيراد لـ domain، صفر حساب، صفر عتبة.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (شكل جدول RODS مبسّط)
- Architectural status: **MINOR**
- Issue IDs: CUI-017، CUI-019
- **COMPLIANT مع السؤال 2** (يرسم البيانات المُمرَّرة فقط). ومُعرَّف بالكامل (`loc.time/status/location/odom/eng/src/noData`).

### `lib/core/widgets/eld_graph_grid.dart` (348 lines, non-empty 289)
- Actual responsibilities: `EldGraphPoint` (السطر 5، صنف بيانات) + `EldGraphGrid` (السطر 21، `StatelessWidget`) + `_EldGraphGridPainter` (السطر 54، `CustomPainter`) = **ثلاثة أصناف / إحدى عشرة دالة**: `paint`, `_drawTimeAxis`, `_drawGridLines`, `_drawYAxisLabels`, `_drawRightSideStats`, `_drawStepLine`, `_drawLiveMarker`, `_drawDashedLine`, `_drawTag`, `_getYPosition`, `shouldRepaint`.
- Declared layer / actual layer: معلن كـ reusable painter -> فعلياً **مكوّن شبكة ساعات الحالة التنظيمية (FMCSA graph)**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-004، CUI-018
- **مُجيب على السؤال 10**: عدد الأصناف والدوال أعلاه بأرقام أسطرها. **لا يحسب فترات HOS** (لا `Duration` ولا عتبات ولا 11/14/60 دقيقة) — الحساب كله في المستهلكين (`log_graph.dart:37-55` و `inspection_duty_graph.dart:19-51`). **لكنه يُضمّن ترميز رموز الحالة التنظيمية `OFF/SB/D/ON` وترتيب صفوف مخطط 24 ساعة** — انظر CUI-004.

### `lib/core/widgets/eld_info_row.dart` (63 lines, non-empty 60)
- Actual responsibilities: صف `label` / `value` / `trailing` / `onTap`. **يستهلك النصوص جاهزة.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-014، CUI-017
- **COMPLIANT مع السؤال 2**.

### `lib/core/widgets/eld_retry_view.dart` (51 lines, non-empty 46)
- Actual responsibilities: شاشة خطأ/فراغ: رسالة + زر إعادة محاولة دائري. **يستهلك `message` و`onRetry` — لا منطق.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-016 (مُعاد تنفيذه يدوياً في خمسة مواضع بـfeatures)
- **COMPLIANT مع السؤال 2**، ومُعرَّف (`context.loc.retryButton` في السطر 37).

---

## B. Detailed issues

--------------------------------------------------
### ISSUE CUI-001: `core/widgets/connection_status_indicator.dart` يكسر استقلال الطبقة ويدخل في دورة استيراد من 25 ملفاً
- Severity: **CRITICAL**
- Category: Layer inversion / Import cycle / Dependency rule violation
- Location `lib/core/widgets/connection_status_indicator.dart:1-8`
- Evidence code block:
```dart
 1: import 'package:flutter/material.dart';
 2: import 'package:flutter_riverpod/flutter_riverpod.dart';
 3: import '../../features/tracking/domain/entities/connection_status.dart';
 4: import '../theme/app_colors.dart';
 5: import '../extensions/context_extensions.dart';
 6: import 'package:go_router/go_router.dart';
 7: import '../../routes.dart';
 8: import '../events/eld_events_provider.dart';
```
- Current behavior: هذا الملف هو **الملف الوحيد** في كامل `lib/core/theme/**` و `lib/core/widgets/**` (25 ملفاً) الذي يستورد من `lib/features/**` أو `lib/routes.dart`. تحقّقت بالأمر:
```
core\widgets\connection_status_indicator.dart:3: import '../../features/tracking/domain/entities/connection_status.dart';
core\widgets\connection_status_indicator.dart:7: import '../../routes.dart';
```
  الدورة المصغّرة (أربعة ملفات) بهذا التسلسل:
```
lib/core/widgets/connection_status_indicator.dart:7    -> import '../../routes.dart';
lib/routes.dart:8                                       -> import 'routes/home_routes.dart';
lib/routes/home_routes.dart:3                          -> import '../features/home/presentation/pages/home_page.dart';
lib/features/home/presentation/pages/home_page.dart:11 -> import '../../../../core/widgets/connection_status_indicator.dart';
```
  وبحث SCC كامل بخوارزمية Tarjan على **408 ملفات Dart**، تبيّن أن المكوّن المترابط تسلكياً بأكمله = **25 ملفاً بالضبط**، و`connection_status_indicator.dart` هو ملف `core` الوحيد داخله:
```
core\widgets\connection_status_indicator.dart       routes\account_routes.dart
routes.dart                                         routes\auth_routes.dart
routes\dvir_routes.dart                             routes\home_routes.dart
routes\logs_routes.dart                             features\home\presentation\pages\home_page.dart
features\home\presentation\widgets\eld_drawer.dart  features\hos\presentation\widgets\driving_lock_screen.dart
features\about\presentation\pages\about_page.dart   features\account\presentation\pages\account_page.dart
features\account\presentation\pages\info_packet_page.dart   features\account\presentation\pages\rules_page.dart
features\codriver\presentation\pages\codriver_page.dart     features\connection\presentation\pages\eld_connection_page.dart
features\connection\presentation\widgets\eld_diagnostics_section.dart
features\connection\presentation\widgets\manual_recording_section.dart
features\dvir\presentation\pages\dvir_list_page.dart
features\inspection\presentation\pages\dot_inspection_page.dart
features\inspection\presentation\pages\inspection_start_view.dart
features\logs\presentation\pages\logs_list_page.dart
features\logs\presentation\pages\suggested_events_page.dart
features\settings\presentation\pages\settings_page.dart
features\vehicle\presentation\pages\select_vehicle_page.dart
```
- Why problematic:
  1. **قاعدة الاتجاه معكوسة**: `core` لا يعلم `features` ولا `routes`. الملف يسحب طبقة التطبيق كاملة إلى ورقة تحتها.
  2. **`AppRoutes` غير قابلة للاختبار منفرداً**: السطر 39 `context.push(AppRoutes.connection)` يفرض إنشاء الرسم البياني الكامل للتصفح قبل اختبار هذا الـwidget.
  3. **حجم إعادة البناء إجباري**: أي تعديل في `routes.dart` أو في إحدى صفحات الـfeature العشرين يُجبر إعادة ترجمة هذا الملف ضمن `core`.
  4. **تسرّب أعمق عبر `core/events`**: `lib/core/events/eld_events_provider.dart:3` يستورد بدوره `features/tracking/data/datasources/live_tracking_data_source.dart` — أي أن `core` يستورد **طبقة data** لا مجرد كيان.
- Violated principle: Dependency Inversion (Dependency Rule) — Clean Architecture، الطبقات الداخلية لا تعرف الخارجية.
- Current owner: `lib/core/widgets/connection_status_indicator.dart`
- Correct owner: `lib/features/tracking/presentation/widgets/connection_status_indicator.dart` — كـwidget عرض تستهلكه الصفحة، مع تمرير `onTap` بدل `AppRoutes`.
- Consequences: استحالة اختبار الوحدة للـwidget دون تشغيل الموجّه؛ عواصف إعادة بناء؛ منع إعادة استخدام `core/widgets` في تطبيق آخر (white-label أو حزمة مشتركة)؛ خطر ترابط غير مقصود يبقي `core` غير قابل لإعادة الاستخدام.
- Recommended correction:
  1. انقل الملف كاملاً إلى `lib/features/tracking/presentation/widgets/`.
  2. احذف `import '../../routes.dart'`؛ وحوّل `onPressed` إلى معامل `VoidCallback? onTap` يمرّره المضيف.
  3. احذف `import '../../features/tracking/domain/entities/connection_status.dart'`؛ واجعل النوع يُمرَّر من المضيف.
  4. إن أصررت على بقائه في `core`: اعرض واجهة منظّمة في `core/events/eld_events_provider.dart` تحمل `String` بدل enum الـfeature.
- Related files: `lib/routes.dart:8`, `lib/routes/home_routes.dart:2-3`, `lib/features/home/presentation/pages/home_page.dart:11`, `lib/core/events/eld_events_provider.dart:3,5,16-18`, `lib/features/tracking/domain/entities/connection_status.dart:1-8`
- Confidence: **CONFIRMED** (الـ SCC محسوب آلياً؛ عدّ 25 ملفاً مُطابق)

--------------------------------------------------
### ISSUE CUI-002: `connection_status_indicator.dart` يُعيد بناء `AppStatusBadge` يدوياً بدل استهلاكه
- Severity: **MODERATE**
- Category: Duplication inside core / Missed design-system adoption
- Location `lib/core/widgets/connection_status_indicator.dart:60-99`
- Evidence code block:
```dart
60:    return Center(
61:      child: Container(
62:        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
63:        margin: const EdgeInsets.symmetric(horizontal: 4),
64:        decoration: BoxDecoration(
65:          color: color.withValues(alpha: 0.1),
66:          borderRadius: BorderRadius.circular(16),
67:          border: Border.all(color: color.withValues(alpha: 0.3)),
68:        ),
69:        child: Row(
70:          mainAxisSize: MainAxisSize.min,
...
82:              Icon(icon, size: 14, color: color),
83:            const SizedBox(width: 6),
84:            Flexible(
85:              child: Text(
86:                text,
87:                overflow: TextOverflow.ellipsis,
88:                style:
89:                    (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
90:                        .copyWith(
91:                  color: color,
92:                  fontWeight: FontWeight.bold,
93:                ),
```
- Current behavior: حاوية `BoxDecoration` بخلفية شفافة وحدّ و`Row` ونص ملوّن — وهو بالضبط ما يقدّمه `AppStatusBadge` في `app_status_badge.dart:65-94`. الملف لا يستورد `app_status_badge.dart` إطلاقاً، بينما الملفات الشقيقة في `features` تفعل ذلك بشكل صحيح (`features/sync/presentation/widgets/sync_status_indicator.dart:27`).
- Why problematic: وجود بديلين للشارة داخل نفس الحزمة (CUI-010) مع ثالث داخل `core`؛ وقيم `alpha 0.1 / 0.3` و`radius 16` و`fontWeight: bold` مثبّتة خارج نظام التصميم، فأي تعديل على `AppStatusBadge` لن ينعكس.
- Violated principle: DRY / Single source of truth for visual tokens.
- Current owner: `lib/core/widgets/connection_status_indicator.dart:60-99`
- Correct owner: `lib/core/widgets/app_status_badge.dart` (المصدّر القياسي للشارة)
- Consequences: ثلاث تنفيذات متنافسة للشارة؛ تفاوت بصري بين شارة المزامنة وشارة الاتصال.
- Recommended correction: استبدل الحاوية بـ`AppStatusBadge(label: text, type: ..., icon: icon)`، أو — إن لزم عنصر جانبي — مرّر `AppStatusBadge` مع أيقونة `CircularProgressIndicator` في `icon`.
- Related files: `lib/core/widgets/app_status_badge.dart:65-94`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:27-42`, `lib/core/theme/app_radius.dart:21-30`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-003: `AppButton` يكشف نوايا عمل ELD في واجهة نظام التصميم
- Severity: **MODERATE**
- Category: Misplaced responsibility / Domain vocabulary in shared design-system
- Location `lib/core/widgets/app_button.dart:6-25` و `:55-59`
- Evidence code block:
```dart
 6: enum EldButtonType {
 7:   /// الزر الأساسي بلون الهوية الذهبي (Golden Feather Primary Gold)
 8:   primary,
 9:
10:   /// الزر الثانوي المؤطر (Outlined) بإطار ولون ذهبي أنيق وخلفية شفافة
11:   secondary,
12:
13:   /// زر الاتصال والإجراءات الإيجابية والاعتماد (Success Green)
14:   connect,
15:   agree,
16:
17:   /// الزر التحذيري أو الحذف أو الإلغاء الحرج (Danger Red)
18:   danger,
19:
20:   /// للمطابقة مع الاستخدامات السابقة وتوجيهها للمظهر المناسب:
21:   continueDisconnected,
22:   send,
23:   dark,
24:   muted,
25: }
```
```dart
55:  bool get _isOutlined =>
56:      widget.type == EldButtonType.secondary ||
57:      widget.type == EldButtonType.continueDisconnected ||
58:      widget.type == EldButtonType.dark ||
59:      widget.type == EldButtonType.muted;
```
- Current behavior: تعداد في نظام التصميم يحمل **نوايا تطبيقية** (`continueDisconnected`, `agree`, `send`, `connect`) لا أنماطاً بصرية. و`continueDisconnected` و`agree` و`send` **لا تقابل أي فرق بصري** في `build`: `_isOutlined` يجمع `continueDisconnected` فقط، و`_base`/`_foreground` يعاملان `send` و`agree` تماماً كـ`primary` (السطران 64-66 و 85-87). أي أنها **أسماء أعمال تجارية بلا أثر سلوكي**.
- Why problematic:
  1. واجهة نظام التصميم يجب أن تصف **المظهر** (primary / secondary / danger / outlined)، لا **قرار العمل**.
  2. كل قيمة جديدة بمسمّى من مجال العمل تفرض تعديل `core` — وهو نفس الفخّ الذي أنتج CUI-001.
  3. بادئة `Eld` داخل `core/` توهم بأن `core` مربوط بمجال ELD.
- Violated principle: Interface Segregation / Tell-Don't-Ask — نظام التصميم لا يجب أن يعرف نوايا المجال.
- Current owner: `lib/core/widgets/app_button.dart`
- Correct owner: `lib/core/widgets/app_button.dart` بأنواع **بصرية بحتة** (`primary|secondary|danger|success|outline`)؛ أما اختيار النوع فيبقى قرار الصفحة.
- Consequences: استحالة إعادة استخدام `AppButton` في تطبيق آخر؛ تسرّب مفردات المجال إلى نظام التصميم؛ وخداع أي فحص exhaustiveness لأن قيماً لا تقابل فروعاً حقيقية في السلوك.
- Recommended correction: استبدل `EldButtonType` بـ`AppButtonVariant { primary, success, danger, outlined }` واحذف `connect` و`agree` و`send` و`continueDisconnected` و`dark` و`muted`. الصفحات تختار `AppButtonVariant.success` عند الحاجة.
- Related files: `lib/core/widgets/app_button.dart:55-111`, `lib/features/auth/presentation/widgets/login_form.dart:4`, `lib/features/hos/presentation/pages/change_status_page.dart:6`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:7`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-004: `eld_graph_grid.dart` يُضمّن رموز الحالة التنظيمية FMCSA وترتيب صفوف المخطط داخل `core`
- Severity: **MODERATE**
- Category: Domain leakage into presentation primitive / Hardcoded regulatory vocabulary
- Location `lib/core/widgets/eld_graph_grid.dart:8-9`, `:23`, `:79`, `:104-106`, `:160`, `:177`, `:330-338`
- Evidence code block:
```dart
 8:   final String status; // 'OFF', 'SB', 'D', 'ON'
 9:   final String? tag; // e.g. 'PC', 'YM'
```
```dart
23:   final Map<String, double>? rightSideStats; // Map of 'OFF', 'SB', 'D', 'ON' to hours
```
```dart
79:    final rowHeight = chartHeight / 4.0; // 4 rows: OFF, SB, D, ON
```
```dart
102:  void _drawTimeAxis(Canvas canvas, double offsetX, double chartWidth, double height) {
103:    final hours = [
104:      'M', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
105:      'N', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'M'
106:    ];
```
```dart
330:  double _getYPosition(String status, double rowHeight) {
331:    switch (status) {
332:      case 'OFF': return rowHeight * 0.5;
333:      case 'SB':  return rowHeight * 1.5;
334:      case 'D':   return rowHeight * 2.5;
335:      case 'ON':  return rowHeight * 3.5;
336:      default:    return rowHeight * 0.5;
337:    }
338:  }
```
- Current behavior: `core` يحمل (أ) مفردات الحالة التنظيمية كـ`String` حرة، و(ب) **ترتيب صفوف مخطط ساعات العمل**. ملاحظة تقنية: `_getYPosition` يستعمل `rowHeight * N.5` وليس `rowHeight * N`، فالمقادير الفعلية `0.5r / 1.5r / 2.5r / 3.5r`؛ وبما أن الرسم يبدأ بـ`canvas.translate(0, timeAxisHeight)` تُقصّ الصفوف العليا والسفلى جزئياً خارج `chartHeight`. وبغض النظر عن ذلك، **الترتيب مقصود ومثبّت**.
- Why problematic:
  1. **`_getYPosition` تكرار منطقي**: توجد خريطتان مستقلتان لنفس المعرفة — `inspection_duty_graph.dart:130-162` (`_rowOf`) و`log_graph.dart:46-53` (`normalized`) — وكلتاهما تفرض **نفس** الترتيب. ثلاث نسخ من قاعدة واحدة.
  2. **الترتيب قرار تنظيمي**: مخطط Graph of Duty Status في 49 CFR 395.8 يحدّد الترتيب `OFF / SB / D / ON`. وضعه في `core` يعني أن `core` يحمل معرفة تنظيمية.
  3. **`default:` يبتلع أي رمز جديد بصمت** (السطر 336): رمز غير معروف يُرسم كـ`OFF` — وهو خطأ صامت في سياق تنظيمي.
  4. **نصوص إنجليزية مُشفّرة** (`:104-106`, `:160`, `:177`) لا تمرّ بـ`AppLocalizations`، وهي عناوين المخطط المعروضة للضابط على الطريق. وبالمقابل `eld_events_table.dart` يمرّر عناوينه عبر `context.loc` (`:62-99`)، فهناك تباين غير مبرَّر.
- Violated principle: Domain model must not be re-encoded in the UI layer; Policy (regulatory row order) belongs to domain.
- Current owner: `lib/core/widgets/eld_graph_grid.dart`
- Correct owner: `DutyStatusCode` (`lib/domain/duty_status/duty_status_code.dart:10-16`، وهو يملك `shortCode`) يوفّر الترتيب؛ و`core` يستقبل ترتيب الصفوف جاهزاً كمعامل.
- Consequences: إضافة حالة جديدة كصف مستقل تتطلب تعديل `core`؛ انحراف بصري صامت عند رموز غير معروفة؛ خطر اختلاف ترتيب الصفوف بين المخططات الثلاثة دون ضابط.
- Recommended correction: مرّر `required List<String> rowOrder` و`required Map<String, int> rowIndex` إلى `EldGraphGrid`؛ واجعل `switch` يُبرز الحالات غير المعروفة بدل ابتلاعها؛ وانقل نصوص المحاور إلى `AppLocalizations`.
- Related files: `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart:22-29,130-162`, `lib/features/logs/presentation/widgets/log_graph.dart:25-30,46-53`, `lib/domain/duty_status/duty_status_code.dart:10-16,53-56`
- Confidence: **CONFIRMED** (للرموز والترتيب) / **POTENTIAL** (هل يجب أن يكون الرسم قابلاً لإعادة الاستخدام خارج ELD — قد يكون مقصوداً)

--------------------------------------------------
### ISSUE CUI-005: `critical_error_app.dart` يعرض نصاً عربياً مُشفّراً ويتجاوز نظام الترجمة بالكامل
- Severity: **MODERATE**
- Category: Localization bypass / Root-level responsibility in shared widget
- Location `lib/core/widgets/critical_error_app.dart:17`, `:26-30`, `:32-39`, `:44-47`
- Evidence code block:
```dart
15:    return MaterialApp(
16:      debugShowCheckedModeBanner: false,
17:      title: 'Golden Feather ELD - Error',
```
```dart
26:                const Icon(
27:                  Icons.error_outline,
28:                  color: Colors.red,
29:                  size: 64,
30:                ),
31:                const SizedBox(height: 24),
32:                const Text(
33:                  'عذراً، حدث خطأ حرج',
34:                  style: TextStyle(
35:                    fontSize: 24,
36:                    fontWeight: FontWeight.bold,
37:                    color: Colors.black87,
38:                  ),
39:                ),
```
```dart
44:                  style: const TextStyle(
45:                    fontSize: 16,
46:                    color: Colors.black54,
47:                  ),
```
- Current behavior: **إجابة مباشرة على السؤال 5 — نعم، `lib/core/widgets/critical_error_app.dart:33` هو النص `'عذراً، حدث خطأ حرج'`.** هذا النص **لا يمرّ بـ`AppLocalizations`** ولا بـ`context.loc`. التطبيق يدعم ثلاث لغات (`app.dart:82-83`) ويجبر العربية افتراضياً (`app.dart:85,91`)، فهذه الشاشة تُعرض للمستخدم النهائي فتُجبره على العربية مهما كانت لغة الجهاز. كذلك `title` في السطر 17 إنجليزي ثابت. والرسالة الثانية مُشفّرة في `lib/main.dart:59-60`:
```dart
58:      const CriticalErrorApp(
59:        message:
60:            'تعذر تهيئة الخدمات الأساسية للتطبيق.\nيرجى التحقق من اتصالك وإعادة التشغيل.',
```
- Why problematic:
  1. **تجاوز الترجمة** في النافذة الوحيدة التي يراها السائق عند فشل الإقلاع.
  2. **`MaterialApp` متداخل** (السطر 15) داخل `core/widgets`: هذا تطبيق جذر لا widget مشترك، ما يجعل `core/widgets` تعتمد على بنية التطبيق لا على التصميم.
  3. **ألوان خام خارج `AppColors`**: `Colors.red` (28)، `Colors.black87` (37)، `Colors.black54` (46)، `backgroundColor: Colors.white` (19) — لا تحترم الوضع الداكن ولا لوحة الهوية.
  4. `title: 'Golden Feather ELD - Error'` بينما `app.dart:77` يستخدم `AppConstants.appName` — مصدران لاسم التطبيق.
- Violated principle: Presentation abstraction / Design-system single source of truth.
- Current owner: `lib/core/widgets/critical_error_app.dart`
- Correct owner: `lib/app/fallback/fallback_app.dart`؛ والنصوص إلى `lib/l10n/app_*.arb` عبر `AppLocalizations`.
- Consequences: استثناء ترجمة في تجربة حرجة؛ حد أدنى من الصيانة البصرية في أبغد شاشة؛ ولا يمكن اختبار النصوص آلياً.
- Recommended correction: انقل الملف إلى `lib/app/fallback/fallback_app.dart`؛ واستورد `AppTheme` فيه؛ واجعل العنوان والنصّين من `AppLocalizations`.
- Related files: `lib/main.dart:55-63`, `lib/app.dart:77,82-92`, `lib/core/theme/app_colors.dart:38,70`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-006: `app_feedback.dart` قناة إشعار موازية تتجاوز `snackBarTheme` وتستخدم حالة عامة ثابتة
- Severity: **MODERATE**
- Category: Design-system bypass / Global mutable state in presentation
- Location `lib/core/widgets/app_feedback.dart:11`, `:48`, `:67-79`, `:88-92`, `:109`
- Evidence code block:
```dart
11:   static OverlayEntry? _activeEntry;
```
```dart
47:          child: Padding(
48:            padding: const EdgeInsets.all(16.0),
```
```dart
67:                  child: Container(
68:                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
69:                    decoration: BoxDecoration(
70:                      color: color ?? const Color(0xFF323232),
71:                      borderRadius: BorderRadius.circular(8),
72:                      boxShadow: const [
73:                        BoxShadow(
74:                          color: Colors.black26,
75:                          blurRadius: 8,
76:                          offset: Offset(0, 4),
77:                        )
78:                      ],
79:                    ),
```
```dart
86:                          child: Text(
87:                            message,
88:                            style: const TextStyle(
89:                              color: Colors.white,
90:                              fontSize: 14,
91:                              fontWeight: FontWeight.w500,
92:                            ),
```
```dart
109:    Future.delayed(const Duration(seconds: 3), () {
```
- Current behavior:
  - **إجابة السؤال 4 (النصوص)**: الملف **لا يُشفّر أي نص مستخدم** — كل النصوص تمرّ كمعامل `message` (`:13-23`)، ومواضع الاستدعاء في `features` ترسل `context.loc.*`. فالجانب اللغوي سليم.
  - **لكنه يتجاوز نظام التصميم بالكامل**: `app_theme.dart:141-151` يعرّف `snackBarTheme` كاملة (خلفية `AppColors.secondary`، زوايا `AppRadius.card`، `SnackBarBehavior.floating`). و`AppFeedback` يبني واجهة **مختلفة تماماً** بقيم مُشفّرة: `0xFF323232` (70) قيمة خارج `AppColors`، و`radius: 8` (71) بدل `AppRadius.card = 12`، وظل `black26/blur 8/offset(0,4)` (73-77) نسخة مُكرَّرة من `AppShadows.raised` (`app_shadows.dart:21-27`)، و`fontSize: 14` (90) و`EdgeInsets.all(16.0)` (48) بدل رموز `AppSpacing`.
  - **حالة عامة ثابتة**: `static OverlayEntry? _activeEntry` (11) حالة قابلة للتغيير على مستوى التطبيق كله داخل صنف واجهة، بلا Riverpod ولا حقن ولا `dispose`.
- Why problematic:
  1. **قناتان للرسالة**: `snackBarTheme` مُعرَّف لكنه غير مستخدم من `AppFeedback`، فتوجد فجوة بصرية مقصودة غير موثّقة.
  2. **قاعدة `AppColors` مكسورة**: `app_colors.dart:13` ينصّ على عدم إنشاء `Color(0x…)` جديد في الواجهات — والمُنتَج هنا واجهة.
  3. **`Future.delayed` غير قابل للإلغاء** (109): لا `Timer` يمكن إلغاؤه، فالإزالة قد تتنافس مع `onTap` أو مع السحب؛ والحالة العامة تسرّب بين الاختبارات.
  4. مستهلكوه يمتدّ إلى **خدمة نظام**: `lib/app/services/push_notification_service.dart:125` يستدعي `AppFeedback.info(context, '$title\n$body')` — أي أن خدمة في `app` تعتمد على صنف في `core/widgets` لعرض الإشعارات.
- Violated principle: Open/Closed + Dependency Inversion — خدمة الواجهة يجب أن تعتمد على نظام التصميم لا أن تعيد تطبيقه.
- Current owner: `lib/core/widgets/app_feedback.dart` (كصنف عرض)
- Correct owner: طبقة `core/presentation/feedback` كمزوّد Riverpod يعتمد على `Theme.of(context)` / `SnackBarThemeData`، أو استخدام `ScaffoldMessenger` مع `snackBarTheme` المعرَّف أصلاً.
- Consequences: ازدواج في التصميم، حالة عابرة للتطبيق، صعوبة في الاختبار، وسلوك عرض غير متسق مع الثيم.
- Recommended correction: استبدل البناء اليدوي بـ`ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: ...))` مع `snackBarTheme`؛ أو على الأقل اسحب كل القيم من `AppColors` و`AppRadius` و`AppSpacing` و`AppShadows` و`AppTypography`، واستبدل `_activeEntry` بمزوّد Riverpod، واستبدل `Future.delayed` بـ`Timer`.
- Related files: `lib/core/theme/app_theme.dart:141-151`, `lib/core/theme/app_shadows.dart:21-27`, `lib/core/theme/app_radius.dart:24`, `lib/core/theme/app_spacing.dart:10`, `lib/app/services/push_notification_service.dart:125`, `lib/app.dart:57-60`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-007: `app_theme.dart` يحمل قيم `Color(0x...)` خارج `AppColors` — أحدها تكرار حرفي
- Severity: **MINOR**
- Category: Design-token rule violation / Duplication
- Location `lib/core/theme/app_theme.dart:175`, `:215`, `:220`
- Evidence code block:
```dart
170:    radioTheme: RadioThemeData(
171:      fillColor: WidgetStateProperty.resolveWith((states) {
172:        if (states.contains(WidgetState.selected)) {
173:          return AppColors.primaryGold;
174:        }
175:        return const Color(0xFFC7C7CC);
176:      }),
```
```dart
214:    dividerTheme: light.dividerTheme.copyWith(
215:      color: const Color(0xFF48484A),
216:    ),
...
220:    disabledColor: const Color(0xFF8E8E93),
```
- Current behavior: `app_colors.dart:3` يعلن صراحةً أنه **الملف الوحيد الذي يحمل قيمة `Color(0x...)`** ويكررها في السطر 13. ثلاثة انتهاكات في نفس الملف:
  - `:175` قيمة `0xFFC7C7CC` بلا اسم ولا معنى دلالي.
  - `:215` قيمة `0xFF48484A` — فاصل داكن بلا رمز (يقابله `AppColors.darkBorder` في `:147` و`AppColors.border` في `:67`).
  - `:220` قيمة `0xFF8E8E93` — **تكرار حرفي كامل** لـ`app_colors.dart:124`.
- Evidence for the duplication:
```dart
// lib/core/theme/app_colors.dart
124:   static const Color navBarInactive = Color(0xFF8E8E93);
```
- Why problematic: وجود قيمة واحدة بلا اسم دلالي (`disabledColor`) وأخرى باسمها (`navBarInactive`) في الملفين يجعل «المصدر الوحيد» غير صحيح؛ وتغيير لون معطّل واحد يجب أن يمرّ بمكانين.
- Violated principle: Single source of truth — القاعدة التي أعلنها المشروع نفسه.
- Current owner: `lib/core/theme/app_theme.dart`
- Correct owner: `lib/core/theme/app_colors.dart` بأسماء دلالية (`radioUnselected`, `darkDivider`, `disabledGrey`).
- Consequences: انجراف لوني صامت؛ استثناءات متكررة بنفس القيمة.
- Recommended correction: أضف `radioUnselected = Color(0xFFC7C7CC)` و`darkDivider = Color(0xFF48484A)` و`disabledGrey = Color(0xFF8E8E93)` في `AppColors`، واستبدل `:220` بـ`AppColors.navBarInactive`.
- Related files: `lib/core/theme/app_colors.dart:3,13,67,124,147`, `lib/core/theme/app_typography.dart:2`, `lib/core/theme/press_feedback.dart:32-33`, `lib/core/theme/app_shadows.dart:14,23`, `lib/core/widgets/app_feedback.dart:70`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-008: `app_theme_provider.dart` يحمل ترحيل بيانات من `SharedPreferences` ووسطي تخزين
- Severity: **MODERATE**
- Category: Misplaced responsibility / Legacy data migration in presentation state
- Location `lib/core/theme/app_theme_provider.dart:3-4`, `:20`, `:22-40`
- Evidence code block:
```dart
 1: import 'package:flutter/material.dart';
 2: import 'package:flutter_riverpod/flutter_riverpod.dart';
 3: import 'package:shared_preferences/shared_preferences.dart';
 4: import '../services/local_storage_service.dart';
```
```dart
20:   static const String _oldThemeKey = 'theme_mode';
21:
22:   Future<void> _loadThemeMode() async {
23:     // ترحيل من SharedPreferences القديم.
24:     final oldPrefs = await SharedPreferences.getInstance();
25:     if (oldPrefs.containsKey(_oldThemeKey)) {
26:       final oldIndex = oldPrefs.getInt(_oldThemeKey);
27:       if (oldIndex != null &&
28:           oldIndex >= 0 &&
29:           oldIndex < ThemeMode.values.length) {
30:         await _storage.setTheme(ThemeMode.values[oldIndex].name);
31:       }
32:       await oldPrefs.remove(_oldThemeKey);
33:     }
```
- Current behavior: صنف **حالة ثيم** يقوم بثلاثة أعمال: (أ) قراءة `ThemeMode`، (ب) **ترحيل بيانات من مستودع قديم إلى آخر**، (ج) **التعامل مع محرك تخزين ثانٍ مباشرة** عبر `SharedPreferences.getInstance()` في `:24`، رغم وجود `LocalStorageService` كمنفذ وحيد. كما يستخدم `StateNotifier` (واجهة Riverpod قديمة) بينما يستخدم المشروع `Notifier` في مواضع أخرى.
- Why problematic:
  1. **مسؤولية ترحيل بيانات** داخل طبقة حالة في `core/theme`؛ لا مكانها هنا.
  2. **اعتماد مزدوج على التخزين**: `SharedPreferences` (إضافة خارجية) + `LocalStorageService`. دورة حياة الإضافة не تُدار في هذا الملف.
  3. **`_loadThemeMode()` بلا حارس**: تُستدعى من المُنشئ (`:17`)، و`ThemeMode.values.firstWhere` في `:36-39` يكتب `state` قبل اكتمال التهيئة الأولى.
- Violated principle: Single Responsibility / Explicit dependency — لا استدعاء إضافة خارجية مباشرة من حامل حالة.
- Current owner: `lib/core/theme/app_theme_provider.dart`
- Correct owner: `lib/core/services/local_storage_service.dart` (عملية الترحيل) أو `lib/app/app_initializer.dart` (خطوة تهيئة).
- Consequences: اختبارات `ThemeModeNotifier` تتطلب محاكاة `SharedPreferences`؛ بقاء كود ترحيل عتيق في مسار حرج؛ ازدواج محركات تخزين.
- Recommended correction: انقل منطق الترحيل إلى `LocalStorageService.migrateLegacyTheme()` واستدعِه في `app_initializer`؛ واحذف الاستيراد المباشر لـ`shared_preferences`؛ وانتقل إلى `Notifier`.
- Related files: `lib/core/services/local_storage_service.dart`, `lib/app/app_initializer.dart`, `lib/app.dart:66,95-97`, `lib/main.dart:40-46`
- Confidence: **CONFIRMED** (تعدد المسؤوليات) / **POTENTIAL** (خطورة سلوك `firstWhere` عند تغيّر تسمية القيمة)

--------------------------------------------------
### ISSUE CUI-009: `eld_card.dart` يُعيد تعريف قيم `cardTheme` بدل استهلاك `AppDecorations.card`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/eld_card.dart:20-30`
- Evidence code block:
```dart
20:    return Card(
21:      clipBehavior: Clip.antiAlias,
22:      color: Theme.of(context).cardTheme.color ??
23:          Theme.of(context).colorScheme.surface,
24:      elevation: 0.5,
25:      shadowColor:
26:          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
27:      margin: EdgeInsets.zero,
28:      shape: RoundedRectangleBorder(
29:        borderRadius: BorderRadius.circular(AppRadius.card),
30:      ),
```
- Current behavior: **`eld_card.dart` يكرّر القيم الخمس نفسها حرفاً بحرف** كما في `app_theme.dart:50-58`:
```dart
50:    cardTheme: CardThemeData(
51:      color: AppColors.surface,
52:      elevation: 0.5,
53:      shadowColor: Colors.black.withValues(alpha: 0.05),
54:      shape: RoundedRectangleBorder(
55:        borderRadius: BorderRadius.circular(AppRadius.card),
56:      ),
57:      margin: EdgeInsets.zero,
58:    ),
```
  أي أن `eld_card.dart` **يلغي** ما عرّفه الثيم، ويجعل `shadowColor` مشتقاً من `onSurface` بدل `black` كما في الثيم.
- Why problematic: صنف في `core` يعيد تعريف نفس القيم الخمس؛ أي تعديل على `cardTheme` لن ينعكس على البطاقات الأكثر استخداماً.
- Violated principle: DRY / single source of truth for visual tokens.
- Current owner: `lib/core/widgets/eld_card.dart:20-30`
- Correct owner: `lib/core/theme/app_theme.dart:50-58` للقيم، و`lib/core/theme/app_decorations.dart:18-28` للزخرفة.
- Consequences: ازدواج بصري محتمل بين بطاقات `Card` وبطاقات `Container`.
- Recommended correction: احذف الصفات الخمس من `EldCard` واعتمد على `cardTheme`؛ أو استخدم `AppDecorations.card(context)` مع `Material`.
- Related files: `lib/core/theme/app_theme.dart:50-58`, `lib/core/theme/app_decorations.dart:18-28`, `lib/features/about/presentation/pages/about_page.dart:13`, `lib/features/settings/presentation/pages/settings_page.dart:11`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-010: نظام التصميم فيه بديلان متداخلان للشارة (`AppStatusBadge` و`AppStatusPill`)
- Severity: **MINOR**
- Category: Duplication inside core / Overlapping primitives
- Location `lib/core/widgets/app_status_pill.dart:28-51` و `lib/core/widgets/app_status_badge.dart:65-94`
- Evidence code block:
```dart
// lib/core/widgets/app_status_pill.dart
28:    return Container(
29:      padding: const EdgeInsets.symmetric(
30:        horizontal: AppSpacing.sm,
31:        vertical: 4,
32:      ),
33:      decoration: AppDecorations.tinted(color),
34:      child: Row(
35:        mainAxisSize: MainAxisSize.min,
36:        children: [
37:          if (icon != null) ...[
38:            Icon(icon, size: iconSize, color: color),
39:            const SizedBox(width: 6),
40:          ],
41:          Text(
42:            label,
43:            style: TextStyle(
44:              color: color,
45:              fontSize: 12,
46:              fontWeight: AppTypography.semiBold,
47:            ),
48:          ),
```
```dart
// lib/core/widgets/app_status_badge.dart
65:    return Container(
66:      padding: const EdgeInsets.symmetric(
67:        horizontal: AppSpacing.sm,
68:        vertical: AppSpacing.xs,
69:      ),
70:      decoration: BoxDecoration(
71:        color: _getBackgroundColor(brightness),
72:        borderRadius: BorderRadius.circular(AppRadius.badge),
73:      ),
74:      child: Row(
75:        mainAxisSize: MainAxisSize.min,
76:        children: [
77:          if (icon != null) ...[
78:            Icon(icon, size: 14, color: textColor),
```
- Current behavior: كلاهما: `Container` + `EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4)` + `Row(mainAxisSize: .min)` + أيقونة اختيارية + نص ملوّن. الفرق الوحيد: مصدر اللون (نوع محسوم داخلياً مقابل لون مُمرَّر) و`borderRadius` (`AppRadius.badge = 8` مقابل `AppRadius.pill = 999`).
- Why problematic: لا يوجد دليل في الملفات على أيّهما هو المعيار: `AppStatusPill` مُصدَّر من `core/design_system.dart:19` بينما `AppStatusBadge` لا. والاستهلاك في `features` منقسم: `app_status_badge` في أربعة ملفات، `app_status_pill` في ملف واحد (`features/dvir/presentation/pages/dvir_list_page.dart:11`).
- Violated principle: DRY / clear design-system API.
- Current owner: `lib/core/widgets/` (الاثنين)
- Correct owner: `lib/core/widgets/app_status_badge.dart` كوحيد، مع `variant: {pill, badge}`.
- Consequences: تباين بصري بين شارات في شاشات مختلفة؛ عبء معرفي للمطوّر.
- Recommended correction: ادمجهما في صنف واحد بأسلوب (`radius`) كمعامل؛ واحذف التصدير المفرد من `design_system.dart`.
- Related files: `lib/core/design_system.dart:19`, `lib/features/dvir/presentation/pages/dvir_list_page.dart:11,204`, `lib/features/vehicle/presentation/widget/vehicle_card.dart:4`, `lib/features/permissions/presentation/pages/permissions_page.dart:8`, `lib/features/codriver/presentation/pages/codriver_page.dart:7`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:5`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-011: `app_button.dart` يُعيد تنفيذ منطق الضغط بدل استهلاك `PressFeedback.pressed`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/app_button.dart:124-132` مقابل `lib/core/theme/press_feedback.dart:25-30`
- Evidence code block:
```dart
124:    final overlay = _isOutlined
125:        ? AppColors.primaryGold.withValues(alpha: 0.12)
126:        : (widget.type == EldButtonType.danger
127:            ? Colors.white.withValues(alpha: 0.28)
128:            : Colors.black.withValues(alpha: 0.24));
...
130:    final color = _pressed && _enabled
131:        ? (_isOutlined ? overlay : Color.alphaBlend(overlay, base))
132:        : base;
```
```dart
// lib/core/theme/press_feedback.dart
25:  static Color pressed(Color base, {bool onDark = false}) {
26:    return Color.alphaBlend(
27:      (onDark ? Colors.white : Colors.black).withValues(alpha: 0.20),
28:      base,
29:    );
30:  }
```
- Current behavior: `AppButton` يحمل حالته `_pressed` (`:51`) ويدمج `overlay` بنفسه بقيمة `alpha 0.24`، بينما `PressFeedback.pressed` تستخدم `0.20`. **قيمتان مختلفتان في ملفين لنفس التأثير**، و`app_button.dart` لا يستورد `press_feedback.dart` إطلاقاً رغم أنه في نفس `core`.
- Why problematic: صنفان في نفس المجلد يُعطيان استجابة ضغط مختلفة قليلاً، بينما الثيم كله يستورد `PressFeedback` (`app_theme.dart:32,70,81,89,99,108`).
- Violated principle: DRY / consistent color token.
- Current owner: `lib/core/widgets/app_button.dart:124-132`
- Correct owner: `lib/core/theme/press_feedback.dart:25-30`
- Consequences: تفاوت بصري بين أزرار `AppButton` وأزرار الثيم.
- Recommended correction: استدعِ `PressFeedback.pressed(base, onDark: ...)` واحذف الدمج اليدوي، أو وحّد قيمة `alpha` في مكان واحد.
- Related files: `lib/core/theme/press_feedback.dart:8-30`, `lib/core/theme/app_theme.dart:32-33,70-73`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-012: `app_signature_canvas.dart` يكسر الوضع الداكن بألوان خام وأحجام خطوط مُشفّرة
- Severity: **MINOR**
- Category: Theme-awareness defect / Design-token bypass
- Location `lib/core/widgets/app_signature_canvas.dart:71`, `:94`, `:137-138`, `:120`, `:157`
- Evidence code block:
```dart
70:            decoration: BoxDecoration(
71:              color: Colors.white,
72:              border: Border.all(
```
```dart
93:                          style: placeholderStyle ??
94:                              context.styles.subtitle.copyWith(fontSize: 16),
```
```dart
134:                      child: Text(
135:                        loc.clearSignature,
136:                        style: context.styles.body.copyWith(
137:                          fontSize: 14,
138:                          color: Colors.black,
139:                          decoration: TextDecoration.underline,
140:                          decorationStyle: TextDecorationStyle.dotted,
141:                        ),
142:                      ),
```
```dart
171:                      child: Text(
172:                        loc.clearSignature,
173:                        style: context.styles.subtitle.copyWith(
174:                          decoration: TextDecoration.underline,
175:                          decorationStyle: TextDecorationStyle.dotted,
176:                        ),
```
- Current behavior: اللوحة **بيضاء دائماً** (`:71`) لأن الحبر يجب أن يكون داكناً — وهو قرار عملي مشروع. لكن **رابط «مسح» في فرع `centerClear` يُكتب بـ`Colors.black` صراحةً** (`:138`) بينما النسخة الممتدة في `:173` تستخدم `context.styles.subtitle` — أي أن **فرعين من نفس الرابط ينتجان ألواناً مختلفة في الوضع الداكن**. كذلك `fontSize: 16` (`:94`) و`fontSize: 14` (`:137`) و`fontSize: 12` (`:120`, `:157`) تتجاوز رموز `AppTypography`.
- Why problematic: الملف موثّق في تروسته (`:9-10`) على أنه theme-aware، لكن هذا الفرع يكسر الوضع الداكن، والفرعان غير متسقين.
- Violated principle: Design-system consistency / Dark-mode correctness.
- Current owner: `lib/core/widgets/app_signature_canvas.dart:138`
- Correct owner: `context.styles.subtitle.color` أو رمز جديد في `AppColors` (على نمط `AppColors.checkSquare` في `app_colors.dart:106`).
- Consequences: نص أسود على خلفية داكنة في فرع واحد فقط.
- Recommended correction: استبدل `color: Colors.black` بـ`color: context.styles.subtitle.color`، واحذف أحجام `fontSize` الصريحة لصالح `AppStyles`.
- Related files: `lib/core/theme/app_typography.dart:11-18`, `lib/core/theme/app_colors.dart:104-106`, `lib/features/dvir/presentation/widgets/dvir_form_sections.dart:8`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:6`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-013: `duty_status_code.dart` يضع `Color` في `domain` بتعليقات مُضلِّلة لا تطابق `AppColors` فعلياً
- Severity: **MODERATE**
- Category: Domain pollution / False cross-reference / Duplication risk
- Location `lib/domain/duty_status/duty_status_code.dart:7`, `:74-88`
- Evidence code block:
```dart
7: import 'package:flutter/widgets.dart';
```
```dart
74:   /// UI Color representation mapping
75:   Color get displayColor {
76:     switch (this) {
77:       case DutyStatusCode.onDutyNotDriving:
78:       case DutyStatusCode.yardMove:
79:       case DutyStatusCode.personalConveyance:
80:         return const Color(0xFFFBBF24); // AppColors.primaryGold
81:       case DutyStatusCode.offDuty:
82:         return const Color(0xFF6B7280); // AppColors.textSecondary
83:       case DutyStatusCode.driving:
84:         return const Color(0xFF10B981); // AppColors.successGreen
85:       case DutyStatusCode.sleeperBerth:
86:         return const Color(0xFFF59E0B); // AppColors.warningYellow
87:     }
88:   }
```
- Current behavior: **إجابة دقيقة على السؤال 6 — لا يوجد تكرار حرفي، بل العكس: التعليقات الأربعة كلها تدّعي مساواة قيم `AppColors` وهي كاذبة.** جدول التحقق الكامل:

| السطر | القيمة في `duty_status_code.dart` | الرمز المذكور | القيمة الفعلية في `app_colors.dart` | مطابقة؟ |
|---|---|---|---|---|
| `:80` | `0xFFFBBF24` | `AppColors.primaryGold` | `0xFFD4AF37` (`app_colors.dart:21`) | لا |
| `:82` | `0xFF6B7280` | `AppColors.textSecondary` | `0xFF5C5C5C` (`app_colors.dart:73`) | لا |
| `:84` | `0xFF10B981` | `AppColors.successGreen` | `0xFF34C759` (`app_colors.dart:37`) | لا |
| `:86` | `0xFFF59E0B` | `AppColors.warningYellow` | `0xFFFF9500` (`app_colors.dart:39`) | لا |

  أضف إلى ذلك أن `domain` يستورد `package:flutter/widgets.dart` في السطر 7، وأن `duty_status_code.dart:8` يستورد `core/utils/logger.dart`.
- Why problematic:
  1. **`domain` يحمل `Color`** — ربط بالمكتبة البيانية داخل الطبقة الأعمق، ويجعل `domain` غير قابل لإعادة الاستخدام خارج Flutter.
  2. **ألوان مكرّرة بأسمائها**: المبرر يقول `AppColors.primaryGold` بينما القيمة مختلفة؛ أي مطوّر سيصلح السطر الناقص ظناً أنه تكرار.
  3. **تثليث خرائط الحالة إلى اللون** (انظر CUI-022).
- Violated principle: Dependency Rule — الـdomain لا يعتمد على إطار العمل ولا على الطبقة الخارجية.
- Current owner: `lib/domain/duty_status/duty_status_code.dart:75-88`
- Correct owner: `lib/core/theme/app_colors.dart` أو ملف `core/presentation/status_palette.dart`؛ ويبقى `domain` على `DutyStatusCode` فقط.
- Consequences: تلوين غير متسق بين الشاشات (لون من `displayColor` وآخر من `AppColors` لنفس الحالة)، ومبرِّر مضلِّل يُضلِّل الصيانة.
- Recommended correction: احذف `displayColor` و`import 'package:flutter/widgets.dart'`؛ وأنشئ `AppStatusPalette.forDutyStatus(DutyStatusCode)` في `core/` يُشير إلى `AppColors`، واستبدل كل `StatusColorHelper.getStatusColor(...)` به.
- Related files: `lib/core/theme/app_colors.dart:21,37,39,73`, `lib/core/utils/status_color_helper.dart:1-8`, `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286`, `lib/domain/duty_status/duty_status_code.dart:8`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-014: `eld_info_row.dart` يُعيد تنفيذ ألوان الضغط بدل `PressFeedback`
- Severity: **MINOR**
- Category: Design-system bypass / Hardcoded interaction colors
- Location `lib/core/widgets/eld_info_row.dart:23-26`
- Evidence code block:
```dart
23:    return InkWell(
24:      onTap: onTap,
25:      splashColor: Colors.black.withValues(alpha: 0.12),
26:      highlightColor: Colors.black.withValues(alpha: 0.06),
```
- Current behavior: قيم تفاعل مُشفّرة (0.12 و0.06)، بينما `PressFeedback.overlay()` في `press_feedback.dart:8-23` يقدّم 0.18 و0.06 — والدالة موجودة ومستخدمة في كل الثيم (`app_theme.dart:73,84,94,102,111,202`). والملف لا يستورد `press_feedback.dart`.
- Why problematic: صنف مشترك في `core` يخالف القاعدة التي يعلنها `app_shadows.dart:6-7` (عدم كتابة قيم التصميم مباشرة في الشاشات)، بمثلها في اللون.
- Violated principle: DRY / design-token adoption.
- Current owner: `lib/core/widgets/eld_info_row.dart:25-26`
- Correct owner: `lib/core/theme/press_feedback.dart:8-23`
- Consequences: تفاوت طفيف في الاستجابة بين الصفوف وبقية التطبيق.
- Recommended correction: احذف السطرين أو استخدم `PressFeedback.overlay()`.
- Related files: `lib/core/theme/press_feedback.dart:8-23`, `lib/core/theme/app_theme.dart:73`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-015: `dashed_line_painter.dart` لا يُعيد الرسم أبداً عند تغيّر اللون
- Severity: **MINOR**
- Category: Functional defect in design-system primitive
- Location `lib/core/widgets/dashed_line_painter.dart:4-5`, `:22-23`
- Evidence code block:
```dart
3: class DashedLinePainter extends CustomPainter {
4:   final Color color;
5:   DashedLinePainter({required this.color});
```
```dart
22:   @override
23:   bool shouldRepaint(CustomPainter oldDelegate) => false;
```
- Current behavior: `color` حقل `final` يُقرأ في `paint` (`:10`) لكن `shouldRepaint` يُرجع `false` دائماً. أي تغيير في اللون (فاتح/داكن/كيان مختلف) **لن يُعيد البناء البصري**؛ ستبقى الطبقة الملوّنة القديمة.
- Why problematic: أصل وظيفي في `core` مستهلك من `lib/features/logs/presentation/pages/edit_log_page.dart:20`.
- Violated principle: Correctness of a reusable design-system primitive.
- Current owner: `lib/core/widgets/dashed_line_painter.dart:23`
- Correct owner: نفس الملف (إصلاح)
- Consequences: خط متقطع بلون قديم بعد تبديل الوضع أو الكيان.
- Recommended correction: `bool shouldRepaint(covariant DashedLinePainter old) => old.color != color;`
- Related files: `lib/features/logs/presentation/pages/edit_log_page.dart:20`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-016: مواضع في `features/**` تُعيد تنفيذ ما تقدمه `core/widgets` (تكميم)
- Severity: **MODERATE**
- Category: Duplication / Shared-widget bypass
- Location المرجع: `lib/core/widgets/eld_retry_view.dart:22-50` مقابل خمسة مواضع في `features`
- Evidence code block:
```dart
// المرجع — lib/core/widgets/eld_retry_view.dart:36-45
36:            IconButton(
37:              tooltip: context.loc.retryButton,
38:              iconSize: 40,
39:              color: context.styles.gold.color,
40:              onPressed: onRetry,
41:              icon: Icon(
42:                Icons.refresh,
43:                color: context.styles.gold.color,
44:              ),
45:            ),
```
```dart
// إعادة تنفيذ 1 — lib/features/logs/presentation/pages/edit_log_page.dart:379-395
379:            : vehicleState.error != null && vehicles.isEmpty
380:                ? Column(
381:                    mainAxisSize: MainAxisSize.min,
382:                    children: [
383:                      Text(
384:                        vehicleState.error!,
385:                        style: context.styles.error,
386:                      ),
387:                      const SizedBox(height: 8),
388:                      TextButton(
389:                        onPressed: () => ref
390:                            .read(vehicleProvider.notifier)
391:                            .loadVehicles(forceRefresh: true),
392:                        child: Text(context.loc.retryButton),
393:                      ),
394:                    ],
395:                  )
```
```dart
// إعادة تنفيذ 2 — lib/features/logs/presentation/pages/unidentified_events_page.dart:247-258
247:                if (state.error != null)
248:                  MaterialBanner(
249:                    content: Text(state.error!, style: context.styles.error),
250:                    actions: [
251:                      TextButton(
252:                        onPressed: _load,
253:                        child: Text(
254:                          context.loc.retryButton,
255:                        ),
256:                      ),
257:                    ],
258:                  ),
```
- Current behavior: التكميم الكامل في القسم C. الخلاصة: **`EldRetryView` مُستخدم في ثمانية ملفات**، ومع ذلك **خمسة مواضع** في `features` تُصمّم واجهة «رسالة + إعادة محاولة» يدوياً.
- Why problematic: عدم اتساق في الشكل والحجم والموضع بين الشاشات؛ وصعوبة تطبيق أي تحسين مركزي.
- Violated principle: DRY / shared-component adoption.
- Current owner: الصفحات في `features`
- Correct owner: `lib/core/widgets/eld_retry_view.dart`
- Consequences: خمسة أنماط مختلفة للخطأ نفسه.
- Recommended correction: وحّد الاستخدام؛ واعتمد `AppStatusPill` أو `AppStatusBadge` بدلاً من البطاقات اليدوية في `active_defects_section.dart`.
- Related files: انظر جدول القسم C.
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-017: خمسة عناصر في `core/widgets` تحمل بادئة `Eld` دون أن تحمل مسؤولية ELD
- Severity: **MINOR**
- Category: Naming / cohesion (ليست مخالفة مسؤولية)
- Location `lib/core/widgets/eld_card.dart:5-6`, `eld_info_row.dart:4-5`, `eld_retry_view.dart:6-7`, `eld_date_paginator.dart:5`, `eld_events_table.dart:6-26`
- Evidence code block:
```dart
// lib/core/widgets/eld_card.dart
 5: /// بطاقة بيانات ELD - خلفية بيضاء مع ظل خفيف
 6: class EldCard extends StatelessWidget {
```
```dart
// lib/core/widgets/eld_info_row.dart
 4: /// صف معلومات - عنوان رمادي على اليسار، قيمة سوداء على اليمين
 5: class EldInfoRow extends StatelessWidget {
```
```dart
// lib/core/widgets/eld_retry_view.dart
 6: /// Empty/error placeholder: short message + circular retry.
 7: class EldRetryView extends StatelessWidget {
```
- Current behavior: **تأكيد صريح: هذه الملفات متوافقة.** `EldCard` هي `Card` مع `InkWell` (لا ELD)، و`EldInfoRow` صف عنوان وقيمة (لا ELD)، و`EldRetryView` خطأ وزر (لا ELD)، و`EldDatePaginator` تنقّل بين تاريخين (لا ELD). البادئة **تسمية زائفة فقط**؛ المسؤوليات كلها عرضية محضة.
- Why problematic: بادئة `Eld` داخل مجلد `core/` توحي بأن `core` مربوط بمجال ELD، وهو ما يفتح الباب أمام تسرّب مثل CUI-001 و CUI-004.
- Violated principle: Clear naming / cohesion signaling — ولا يُعد مخالفة تصميمية بحد ذاته.
- Current owner: `lib/core/widgets/*.dart`
- Correct owner: نفس الملفات بأسماء عامة (`AppCard`, `AppInfoRow`, `AppRetryView`, `AppDatePaginator`)؛ ويُبقي `EldEventsTable` و `EldGraphGrid` على حالهما لأنهما فعلاً تخصصيان.
- Consequences: الالتباس بين المعمارية والاسم.
- Recommended correction: إعادة تسمية تدريجية؛ ليست أولوية قصوى.
- Related files: `lib/core/widgets/eld_card.dart`, `lib/core/widgets/eld_info_row.dart`, `lib/core/widgets/eld_retry_view.dart`, `lib/core/widgets/eld_date_paginator.dart`
- Confidence: **CONFIRMED** (وقائعها) — **لا يُعد مخالفة مسؤولية**

--------------------------------------------------
### ISSUE CUI-018: قياسات ومقاسات مُشفّرة تتجاوز رموز `AppTypography` و `AppSpacing`
- Severity: **MINOR**
- Category: Design-token bypass
- Location `lib/core/theme/app_styles.dart:157`، `lib/core/widgets/app_status_badge.dart:84`، `app_status_pill.dart:21,31,45`
- Evidence code block:
```dart
// lib/core/theme/app_styles.dart
156:      number: TextStyle(
157:        fontSize: 18,
158:        fontWeight: AppTypography.bold,
```
```dart
// lib/core/widgets/app_status_badge.dart
81:          Text(
82:            label,
83:            style: const TextStyle(
84:              fontSize: 11,
85:              fontWeight: AppTypography.bold,
86:            ).copyWith(color: textColor),
```
```dart
// lib/core/widgets/app_status_pill.dart
21:    this.iconSize = 8.0,
...
29:      padding: const EdgeInsets.symmetric(
30:        horizontal: AppSpacing.sm,
31:        vertical: 4,
32:      ),
...
45:              fontSize: 12,
```
- Current behavior: `AppTypography` يعرّف سلماً كاملاً (`smallSize = 12.0` و `captionSize = 13.0` في `app_typography.dart:14-18`)، و`AppSpacing.xs = 4.0` في `app_spacing.dart:6`. ومع ذلك تُكتب `18` و`11` و`8.0` و`4` و`12` يدوياً.
- Why problematic: `11` و`12` و`8` تعني قياسات الشارات؛ لو أُضيف مقاس «شارة» للسلّم لبُني على `AppStyles` وحده.
- Violated principle: Design tokens.
- Current owner: الملفات المذكورة
- Correct owner: `AppTypography` و `AppSpacing`
- Consequences: صعوبة تغيير مقاس موحد للشارات.
- Recommended correction: أضف `badgeSize = 11.0` واستبدل؛ واستخدم `AppSpacing.xs` بدل `4`.
- Related files: `lib/core/theme/app_typography.dart:11-18`, `lib/core/theme/app_spacing.dart:6-10`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-019: `eld_events_table.dart` يثبت شكل جدول RODS داخل `core`
- Severity: **MINOR**
- Category: Presentation shape locked in shared layer
- Location `lib/core/widgets/eld_events_table.dart:6-24`, `:59-100`
- Evidence code block:
```dart
 6: class EldTableRow {
 7:   final String time;
 8:   final String status;
 9:   final String location;
10:   final String odom;
11:   final String eng;
12:   final String src;
13:   final Color? statusColor;
```
```dart
// lib/core/theme/app_colors.dart (للإشارة: شكل الورقة الرسمية)
108:  // ========== جدول رأس السجل اليومي RODS (شكل الورقة الرسمية) ==========
109:  static const Color rodsHeaderBg = Color(0xFFF2F2F2);
110:  static const Color rodsHeaderText = Color(0xFF222222);
111:  static const Color rodsHeaderSubtext = Color(0xFF333333);
```
- Current behavior: **مُجيب على السؤال 2: الملف لا يُعيد حساب أي شيء.** كل الحقول `String` جاهزة من المستدعي، ولا استيراد لأي `domain` أو `features`. لكنه يثبت **ستة أعمدة** (`time/status/location/odom/eng/src`) وعروضاً (`60/2/3/60/55/40`) داخل `core`. ويُستهلك من صفحتين: `inspection_active_view.dart:14` و `inspection_preview_page.dart:18`.
- Why problematic: جدول RODS ورسم معاينة التفتيش ليسا نفس النموذج؛ وتثبيت الأعمدة في `core` يمنع إضافة أعمدة دون تعديل مشترك.
- Violated principle: Open/Closed for shared components.
- Current owner: `lib/core/widgets/eld_events_table.dart`
- Correct owner: `lib/features/inspection/presentation/widgets/` كجدول تخصصي — إلا إذا كان `core` هو المكان المقصود مركزياً.
- Consequences: ترابط إجباري عند اختلاف الأعمدة.
- Recommended correction: اجعل الأعمدة `List<_ColumnSpec>` قابلة للتمرير، أو انقل الملف إلى `features/inspection/`.
- Related files: `lib/features/inspection/presentation/pages/inspection_active_view.dart:14`, `lib/features/inspection/presentation/pages/inspection_preview_page.dart:18`, `lib/core/theme/app_colors.dart:108-111`
- Confidence: **POTENTIAL** (لم يُحسم هل القالب مطلوب مركزياً أم خاص بصفحة)

--------------------------------------------------
### ISSUE CUI-020: رموز تصميمية ميتة وشيفرات توافق غير مستخدمة في `core/theme`
- Severity: **MINOR**
- Category: Dead code in design system
- Location `lib/core/theme/app_typography.dart:9`، `app_colors.dart:28-29,95,109-111`، `press_feedback.dart:33`، `app_styles.dart:174-178`
- Evidence code block:
```dart
// lib/core/theme/app_typography.dart
 9:   static const String fontFamilyIOS = 'SF Pro Text';
```
```dart
// lib/core/theme/app_styles.dart
173:   /// توافق خلفي — استخدم [AppStyles.fromBrightness].
174:   // ignore: deprecated_member_use_from_same_package
175:   static AppStyles light() => AppStyles.fromBrightness(Brightness.light);
176:
177:   /// توافق خلفي — استخدم [AppStyles.fromBrightness].
178:   static AppStyles dark() => AppStyles.fromBrightness(Brightness.dark);
```
- Current behavior: بحث على `lib/**/*.dart` أعطى:
  - `fontFamilyIOS` — **1** استخدام (التعريف نفسه).
  - `goldLight` — **1**، `goldDark` — **1**، `darkGoldBg` — **1**، `rodsHeaderBg` و `rodsHeaderText` و `rodsHeaderSubtext` — **1** لكل منها (تعريف فقط).
  - `inkOnDark` — **1** (تعريف فقط).
  - `AppStyles.light()` و `AppStyles.dark()` — **صفر** استدعاء في كامل المشروع.
  - كما أن `// ignore: deprecated_member_use_from_same_package` في `:174` **لا مبرر له**: لا يوجد رمز مهمَل في نفس الحزمة.
- Why problematic: واجهة نظام التصميم تعلن رموزاً غير مستخدمة، و`AppStyles.light()/dark()` موصوفة كـ«توافق خلفي» دون أي مستهلكين.
- Violated principle: YAGNI / accurate API surface.
- Current owner: الملفات المذكورة
- Correct owner: — (حذف)
- Consequences: فوضى في وثائق التصميم؛ وخطر استخدام رمز ميت لاحقاً.
- Recommended correction: احذف الرموز الميتة وشيفرة التوافق، أو وثّقها بوضوح كـ«reserved».
- Related files: `lib/core/design_system.dart:8-17`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-021: `eld_date_paginator.dart` يعتمد افتراضياً على رمز لوني مخصص لمعاينة التفتيش
- Severity: **MINOR**
- Category: Cohesion / design-token misuse
- Location `lib/core/widgets/eld_date_paginator.dart:31`
- Evidence code block:
```dart
29:  @override
30:  Widget build(BuildContext context) {
31:    final effectiveBgColor = backgroundColor ?? context.previewBand;
```
```dart
// lib/core/extensions/context_extensions.dart
110:  /// شريط رأس معاينة التفتيش — داكن في الوضعين بدرجة لكل وضع.
111:  Color get previewBand => isDark ? AppColors.darkBorder : AppColors.surfaceDark;
```
- Current behavior: widget عام في `core` ينسب خلفيته الافتراضية إلى رمز موصوف صراحةً بأنه «شريط رأس معاينة التفتيش»، وهو سياق صفحة واحدة من `features/inspection`. وقيمته داكنة في الوضعين.
- Why problematic: نقل رمز مخصص لصفحة إلى صنف مشترك يجعل تغيّر تصميم صفحة التفتيش يكسر التباين في الصفحات الأخرى التي تستخدم `EldDatePaginator` مثل `inspection_active_view.dart:13`.
- Violated principle: Correct token ownership / no page-specific tokens in shared widgets.
- Current owner: `lib/core/widgets/eld_date_paginator.dart:31`
- Correct owner: `lib/core/theme/app_colors.dart` برمز محايد، أو اجعل `backgroundColor` مطلوباً.
- Consequences: ارتباط غير مقصود.
- Recommended correction: مرّر اللون إجبارياً، أو عرّف رمزاً محايداً في `AppColors`.
- Related files: `lib/core/extensions/context_extensions.dart:102-111`, `lib/core/theme/app_colors.dart:98-101,147`, `lib/features/inspection/presentation/pages/inspection_active_view.dart:13`
- Confidence: **CONFIRMED**

--------------------------------------------------
### ISSUE CUI-022: `StatusColorHelper` في `core/utils` ثالث تنفيذ لخرائط الحالة إلى اللون
- Severity: **MINOR**
- Category: Triplicated mapping / Layer confusion
- Location `lib/core/utils/status_color_helper.dart:1-8`
- Evidence code block:
```dart
1: import 'package:flutter/material.dart';
2: import '../../domain/duty_status/duty_status_code.dart';
3:
4: class StatusColorHelper {
5:   static Color getStatusColor(String status) {
6:     return DutyStatusCode.fromAny(status).displayColor;
7:   }
8: }
```
- Current behavior: ثلاث خرائط مستقلة لنفس المعرفة:
  1. `lib/domain/duty_status/duty_status_code.dart:75-88` — `displayColor` بقيم مثل `0xFF10B981`.
  2. `lib/core/utils/status_color_helper.dart:5-7` — غلاف رقيق.
  3. `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286` — خريطة **مستقلة تماماً** بقيم مختلفة:
```dart
273:  Color _getStatusColor(BuildContext context, String? status) {
274:    switch (status) {
275:      case 'D':
276:        return AppColors.successGreen;
277:      case 'ON':
278:        return AppColors.warningYellow;
279:      case 'SB':
280:        return AppColors.infoBlue;
281:      case 'OFF':
282:        return AppColors.textSecondary;
283:      default:
284:        return AppColors.textPrimary;
285:    }
286:  }
```
  الخريطة (3) تعطي `D = 0xFF34C759` بينما الخريطة (1) تعطي `D = 0xFF10B981` — **لونان مختلفان لنفس الحالة في شاشتين**.
- Why problematic: `core/utils` ملف بلا مسؤولية واضحة (ليس util ولا widget ولا service)، ويؤسس نمط «طبقة ألوان» ثالثة.
- Violated principle: Single source of truth / clear module responsibility.
- Current owner: `lib/core/utils/status_color_helper.dart`
- Correct owner: خريطة واحدة في `core/presentation/` أو `lib/core/theme/` بعد إخراج اللون من `domain` (راجع CUI-013).
- Consequences: نفس الحالة تظهر بألوان مختلفة عبر التطبيق.
- Recommended correction: ادمج في خريطة واحدة؛ واحذف الملف أو اجعله طبقة رقيقة فوق `AppColors`.
- Related files: `lib/domain/duty_status/duty_status_code.dart:75-88`, `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286`
- Confidence: **CONFIRMED**

---

## C. Duplication table مع `lib/features/**`

| # | مكوّن `core/widgets` (المرجع) | إعادة التنفيذ في `features/**` | العدد | نوع التكرار |
|---|---|---|---|---|
| 1 | `eld_retry_view.dart:36-45` (رسالة + زر إعادة محاولة بـ`loc.retryButton`) | `logs/presentation/pages/edit_log_page.dart:379-395` | 1 | كامل |
| | | `logs/presentation/pages/unidentified_events_page.dart:247-258` | 2 | كامل |
| | | `logs/presentation/widgets/vehicle_picker_dialog.dart:153` | 3 | جزئي (زر فقط) |
| | | `logs/presentation/widgets/codriver_picker_dialog.dart:65` | 4 | جزئي |
| | | `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:131` | 5 | جزئي |
| | **مقابل: مستخدمو `EldRetryView` الصحيحين** | `logs_list_page.dart:9,71,78`، `status_dashboard_page.dart:5,113`، `recap_page.dart:8,72`، `dvir_list_page.dart:12,75`، `inspection_preview_page.dart:6,128`، `events_tab.dart:11,38,45`، `select_vehicle_page.dart:6`، `rules_page.dart:8` | **8** | مرجع |
| 2 | `app_status_pill.dart:28-51` و `app_status_badge.dart:65-94` (شارة بلون) | `dvir/presentation/widgets/active_defects_section.dart:65-87` (`_severityPill`) | 1 | كامل (يدوي) |
| | | `core/widgets/connection_status_indicator.dart:60-99` (CUI-002، داخل `core`) | 1 | كامل |
| 3 | `app_text_field.dart:64-122` (غلاف `TextFormField`) | `dvir/presentation/widgets/dvir_form_components.dart:124-160` (`DvirFlatTextField`) و `:162-198` (`DvirDropdownField`) | 2 | جزئي (مسطح) |
| 4 | `eld_card.dart` + `app_decorations.dart:18-28` + `app_theme.dart:50-58` | `dvir/presentation/widgets/dvir_form_components.dart:16-42,61-88,102-122` (حدود `Color(0xFFE0E0E0)` يدوية ثلاث مرات) | 3 | كامل |
| 5 | `eld_graph_grid.dart:330-338` + `:160` (ترتيب `OFF/SB/D/ON`) | `inspection/presentation/widgets/inspection_duty_graph.dart:130-162` (`_rowOf`) | 1 | كامل |
| | | `logs/presentation/widgets/log_graph.dart:46-53` (`normalized`) | 2 | كامل |
| 6 | خريطة الحالة إلى اللون | `domain/duty_status/duty_status_code.dart:75-88` + `core/utils/status_color_helper.dart:5-7` + `inspection_preview_page.dart:273-286` | 3 خرائط | خريطة لون |
| 7 | `app_button.dart` (زر موحد) | `codriver_page.dart` (FilledButton مرتين)، `permissions_page.dart:8`، `unidentified_events_page.dart`، `codriver_picker_dialog.dart`، `diagnostics_page.dart:9` (OutlinedButton)، `dvir_form_sections.dart` (ElevatedButton) | 6 مواضع | جزئي |
| 8 | قاعدة `app_colors.dart:12-14` (عدم إنشاء `Color(0x...)` خارجي) | `dvir_form_components.dart:20,65,106,153,189`، `dvir_form_sections.dart:404,469`، `main_circular_timer.dart:184-185` | 9 قيم | قاعدة مكسورة |

**الإجمالي: 25+ موضعاً في `lib/features/**` تعيد تنفيذ ما يقدمه `lib/core/widgets/**` و `lib/core/theme/**`.**

---

## D. قائمة الملفات المقروءة (بأعداد أسطر حقيقية) — إثبات التغطية

| # | المسار | الأسطر | غير الفارغ |
|---|---|---|---|
| 1 | `lib/core/theme/app_colors.dart` | **155** | 112 |
| 2 | `lib/core/theme/app_decorations.dart` | **71** | 64 |
| 3 | `lib/core/theme/app_radius.dart` | **31** | 22 |
| 4 | `lib/core/theme/app_shadows.dart` | **28** | 25 |
| 5 | `lib/core/theme/app_spacing.dart` | **18** | 16 |
| 6 | `lib/core/theme/app_styles.dart` | **244** | 234 |
| 7 | `lib/core/theme/app_theme.dart` | **222** | 211 |
| 8 | `lib/core/theme/app_theme_provider.dart` | **48** | 40 |
| 9 | `lib/core/theme/app_typography.dart` | **75** | 67 |
| 10 | `lib/core/theme/press_feedback.dart` | **34** | 30 |
| 11 | `lib/core/widgets/app_button.dart` | **194** | 174 |
| 12 | `lib/core/widgets/app_feedback.dart` | **116** | 104 |
| 13 | `lib/core/widgets/app_signature_canvas.dart` | **232** | 218 |
| 14 | `lib/core/widgets/app_status_badge.dart` | **96** | 89 |
| 15 | `lib/core/widgets/app_status_pill.dart` | **53** | 49 |
| 16 | `lib/core/widgets/app_text_field.dart` | **125** | 121 |
| 17 | `lib/core/widgets/connection_status_indicator.dart` | **101** | 92 |
| 18 | `lib/core/widgets/critical_error_app.dart` | **58** | 55 |
| 19 | `lib/core/widgets/dashed_line_painter.dart` | **24** | 21 |
| 20 | `lib/core/widgets/eld_card.dart` | **41** | 38 |
| 21 | `lib/core/widgets/eld_date_paginator.dart` | **73** | 69 |
| 22 | `lib/core/widgets/eld_events_table.dart` | **187** | 178 |
| 23 | `lib/core/widgets/eld_graph_grid.dart` | **348** | 289 |
| 24 | `lib/core/widgets/eld_info_row.dart` | **63** | 60 |
| 25 | `lib/core/widgets/eld_retry_view.dart` | **51** | 46 |

**المجموع: 2354 سطراً** — تمت قراءة كل ملف كاملاً (لا استنتاج من الاسم).

### ملفات داعمة قرئت أيضاً (للأدلة فقط، خارج نطاق التدقيق)
`lib/domain/duty_status/duty_status_code.dart` (99)، `lib/core/extensions/context_extensions.dart` (112)، `lib/core/utils/status_color_helper.dart` (8)، `lib/core/design_system.dart` (19)، `lib/routes.dart` (100)، `lib/routes/home_routes.dart`، `lib/core/events/eld_events_provider.dart` (18)، `lib/features/tracking/domain/entities/connection_status.dart` (8)، `lib/features/logs/presentation/widgets/log_graph.dart` (101)، `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176)، `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259)، `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46)، `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199)، `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257)، `lib/features/hos/presentation/pages/status_dashboard_page.dart` (118)، `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` (365)، `lib/features/logs/presentation/pages/{edit_log_page,unidentified_events_page,dvir_list_page,inspection_preview_page}.dart`، `lib/app.dart`، `lib/main.dart`.

### التحقق من دورة الـ 25 ملفاً (SCC)
حُسب المكوّن المترابط تسلكياً (Strongly Connected Component) آلياً بخوارزمية Tarjan على **408 ملفات Dart** داخل `lib/`:
- المكوّنات المترابطة بحجم أكبر من واحد: **5**، ومجموع عقدها **35**.
- المكوّن الأول بحجم **25 بالضبط**، وكل أعضائه مُدرجة في CUI-001، ويحتوي `core/widgets/connection_status_indicator.dart` كملف `core` وحيد.
- الثاني (4 ملفات): ملفات `l10n` المتبادلة فيما بينها.
- الثالث (ملفان): `core/services/local_storage_service.dart` و `core/services/tracking_config_storage_service.dart`.
- الرابع (ملفان): `backend/providers/backend_network_providers.dart` و `core/network/core_providers.dart`.
- الخامس (ملفان): `features/logs/data/providers/log_repository_providers.dart` و `features/logs/data/repositories/log_repository_impl.dart`.

### إجابات سريعة عن الأسئلة المفصلة
1. **هل يستورد `core/theme` أو `core/widgets` من `features` أو `app`؟** — نعم، **ملف واحد فقط**: `connection_status_indicator.dart:3` و `:7` (CUI-001، CONFIRMED، دورة من 25 ملفاً). الملفات الأربعة والعشرون الأخرى نقيّة من أي استيراد متعاكس.
2. **هل تتسرب قواعد ELD إلى widgets المشتركة؟** — `eld_card` و `eld_info_row` و `eld_retry_view` و `eld_date_paginator` و `eld_events_table`: **متوافقة (COMPLIANT)**، ترسم بيانات مُمررة فقط ولا تستورد `domain` ولا تحوي عتبات. الاستثناء الوحيد: `eld_graph_grid.dart` الذي يضمّن رموز `OFF/SB/D/ON` وترتيب الصفوف (CUI-004، MODERATE) — **ولا يحسب فترات HOS**؛ الحساب في `log_graph.dart:37-55` و `inspection_duty_graph.dart:19-51`.
3. **التكرار مع features** — 25+ موضعاً، موثق في القسم C (CUI-016).
4. **`app_feedback.dart`** — لا نصوص مشفرة (يمررها المستدعي)، **لكنه يتجاوز `snackBarTheme`** ويستخدم قيم `0xFF323232` و `8` و `black26` و `3 ثوان` مشفرة، ولديه `static OverlayEntry? _activeEntry` عام (CUI-006).
5. **`critical_error_app.dart`** — نعم: `lib/core/widgets/critical_error_app.dart:33` هو النص `'عذراً، حدث خطأ حرج'`، وعنوان ثابت إنجليزي في `:17` (CUI-005).
6. **`app_theme` و `app_styles` و `app_colors`** — **لا توجد أي نقطة نهاية ولا لون ذو دلالة تنظيمية ولا قيمة بيئة**؛ والـ`Color(0x...)` الوحيد خارج `AppColors` هو `:220` المكرر حرفيا عن `app_colors.dart:124` (CUI-007). وبخصوص `duty_status_code.dart:75-88`: **لا تكرار حرفي**، بل **أربع تعليقات مضللة** — كل قيمة تختلف عن الرمز الذي تدّعي مساواته (CUI-013).
7. **الترجمة** — مُعرَّفة في: `app_signature_canvas.dart:91,135,172`، `eld_events_table.dart:41,62,69,76,83,90,97`، `eld_retry_view.dart:37`، `connection_status_indicator.dart:51,55`. ومُتجاوَزة في: `critical_error_app.dart:17,33` و `eld_graph_grid.dart:104-106,160,177`.
8. **`app_signature_canvas.dart`** — **لا شيء خارج العرض**: لا قواعد عمل، ولا حفظ، ولا شبكة، ولا إدخال أو إخراج بيانات في الـ232 سطراً (CUI-012 — الألوان فقط).
9. **`app_theme_provider.dart`** — غير متماسك: حالة ثيم مع ترحيل بيانات ومحركَي تخزين (CUI-008).
10. **`eld_graph_grid.dart`** — **ثلاثة أصناف / إحدى عشرة دالة**؛ painter وgrid قابل لإعادة الاستخدام هندسياً، لكنه **يضمّن ترميز رموز الحالة التنظيمية وترتيب الصفوف** ولا يحسب فترات HOS (CUI-004).

> **ملاحظة منهجية**: لم يُبلَّغ عن عبارة «`core/widgets` يستورد `flutter/material`» — وهو نمط مشروع. كل مخالفة أعلاه مثبتة باقتباس حرفي ورقم سطر حقيقي.
