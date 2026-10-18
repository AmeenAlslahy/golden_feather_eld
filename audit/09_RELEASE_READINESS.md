# تقرير 09 — جاهزية الإصدار (Release Readiness)

**المنهجية:** فحص إعدادات البناء والتوقيع وأوامر البناء الآمنة المنفَّذة فعلياً. أي بند لم يُنفَّذ وُسم بوضوح.

---

## 1. تنفيذ البناء (Executed Commands — سجل موثق)

| الأمر | النتيجة | التصنيف |
|---|---|---|
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | **No issues found** | VERIFIED |
| `flutter test` | **1035 نجاح + 2 تخطٍ** | VERIFIED |
| `flutter build apk --debug` (محاولة 1) | فشل: `Java heap space` في JetifyTransform | بيئة/إعادة إنتاجية |
| `flutter build apk --debug` (محاولة 2 بعد إيقاف daemons) | **نجاح** — `build/app/outputs/flutter-apk/app-debug.apk` (165.56 MB) | VERIFIED |
| `flutter build apk --release` / `appbundle` | **لم يُنفَّذ** — لا keystore إنتاجي، والاهتمام بتجنب بناء نسخة موقعة بمفاتيح debug يُخفي غياب التوقيع الحقيقي | NOT TESTED |
| `flutter build ios` | لم يُنفَّذ (بيئة Windows) | NOT TESTED |

## 2. إعداد التوقيع (Signing)

| # | البند | الحالة | الدليل |
|---|---|---|---|
| REL-A1 | **`android/key.properties` غير موجود** → أي release build يسقط تلقائياً على **مفاتيح debug** | ❌ **حاجز إصدار** | `build.gradle.kts:50-68`؛ `Test-Path` = False |
| REL-A2 | قالب `key.properties.example` جاهز (untracked) | ✅ | `android/key.properties.example` |
| REL-A3 | لا keystore في المستودع، لا تسريب أسرار توقيع | ✅ | `.gitignore` |
| REL-A4 | إضافة `com.google.firebase.crashlytics` Gradle plugin **غائبة** (لا رفع mapping/NDK) | ❌ | `build.gradle.kts:4-11` |
| REL-A5 | Play App Signing / upload key strategy غير موثقة | ⚠️ | لا وثائق |

## 3. إعداد Android

| البند | القيمة | التقييم |
|---|---|---|
| `applicationId` | `com.goldenfeather.golden_feather_eld` | ✅ مقبول (يستحسن تقصيره بلا `_` لاحقاً — تجميلي) |
| `android:label` | **`golden_feather_eld`** (الاسم الداخلي!) | ❌ **عيب واجهة متجر** — يجب أن يكون "Golden Feather ELD" |
| `compileSdk` | 36 | ✅ |
| `minSdk` / `targetSdk` | Flutter defaults (غير مثبتين صراحةً) | ⚠️ يجب تثبيتهما وقفلهما للإنتاج + التحقق من متطلبات Play (target حديث إلزامي) |
| `allowBackup` | false | ✅ |
| الأذونات | INTERNET, FINE/COARSE/BACKGROUND_LOCATION, FOREGROUND_SERVICE(_LOCATION), REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, BLUETOOTH(_SCAN/CONNECT), POST_NOTIFICATIONS | ⚠️ كلها مبرَّرة وظيفياً، لكنها **أذونات Play الحساسة**: موقع خلفي + استثناء البطارية يتطلبان إقرارات مراجعة وسياسة خصوصية ومقطع شرح — لا شيء منها مهيأ |
| أيقونات | مولّدة (adaptive + iOS) | ✅ |
| بناء Debug ناجح | ✅ | موثق أعلاه |
| تحذيرات Kotlin | APIs Bluetooth مهجورة | منخفضة |

## 4. إعداد iOS

| البند | الحالة |
|---|---|
| Bundle ID / توقيع / Provisioning | غير مُتحقق منه (خارج بيئة Windows) — NOT TESTED |
| Privacy strings (Location/Bluetooth) | ✅ موجودة بالعربية غير مطلوبة — نصوص إنجليزية واضحة |
| UIBackgroundModes + BGTask IDs | ✅ معرّفة |
| اتجاهات الشاشة | Portrait + Landscape (بينما التطبيق يقفل Portrait برمجياً في `main.dart`) — تعارض تجميلي ⚠️ |
| Info.plist: `CFBundleDisplayName` = "Golden Feather Eld" | ✅ أفضل من Android، لكن inconsistent مع "ELD" |
| App Store Privacy Nutrition Labels + مراجعة الموقع الخلفي | ❌ غير مهيأ |

## 5. الإصدارات وإعادة الإنتاجية (Versioning & Reproducibility)

| البند | التقييم |
|---|---|
| `version: 1.0.0+1` في pubspec | ✅ مقروء من Flutter Gradle |
| سياسة ترقيم versionCode لكل رفع متجر | غير موثقة ⚠️ |
| Toolchain: محلي Flutter 3.47.2، CI مثبت 3.41.9، pubspec يسمح `>=3.32.0` | ⚠️ عدم تطابق (ARC-07) يهدد إعادة الإنتاج |
| `pubspec.lock` مُلتزم | ✅ |
| `shared_preferences_android: any` | ⚠️ بلا قيد |
| لا سكربتات نشر/إصدار في `scripts/` | ✅ `scripts/` موجود لكن لا pipeline إصدار |
| لا tag/release في Git محلياً | غير مُتحقق من الريموت |

## 6. CI/CD

| البند | الحالة |
|---|---|
| Analyze + Test + Debug APK + Coverage | ✅ يعمل على كل الفروع والـ PRs |
| بناء Release / AAB | ❌ غير موجود |
| نشر إلى Play/TestFlight | ❌ غير موجود |
| فحص تبعيات/ثغرات | ❌ غير موجود |
| توقيع آمن عبر Secrets في CI | ❌ غير موجود |
| بوابات جودة إلزامية (lint gate) | جزئي: `dart format` (gate)، analyze بـ `--no-fatal-infos --no-fatal-warnings` (متساهل) |

## 7. المراقبة والحوادث (Ops)

| البند | الحالة |
|---|---|
| Crash reporting يعمل فعلياً | ❌ نصف مهيأ (REL-01/02) — لا رؤية لأخطاء Dart |
| Analytics | ❌ غائب |
| Feature flags / Remote kill-switch | ❌ غائب (أُزيل استدعاء config سابقاً) |
| Force-update mechanism | ❌ غائب |
| Rollback procedure (تطبيق) | غير موثقة — والتراجع في المتجر لا ينزل على الأجهزة القديمة تلقائياً |
| مراقبة خادم/SLA | خارج نطاق المستودع |

## 8. فجوات الجاهزية للإصدار — قائمة تدقيق قبل الرفع للمتجر

- [ ] إنشاء keystore إنتاجي (Play App Signing) + `key.properties` خارج git + بناء **AAB** موقّع ناجح
- [ ] تثبيت `minSdk/targetSdk` صراحةً + تأكيد متطلبات Play للفئة العمرية والـ target
- [ ] تصحيح `android:label` إلى "Golden Feather ELD"
- [ ] إضافة crashlytics Gradle plugin + ربط أخطاء Dart (REL-01/02)
- [ ] توفير Privacy Policy منشورة + تنقّل داخلي إليها + ملء Data Safety في Play وNutrition Labels في App Store (خصوصاً الموقع الخلفي)
- [ ] إقرار Play لـ"الموقع في الخلفية" + مقطع شرح لماذا + تبرير `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- [ ] `--split-per-abi` (+تقييم `--obfuscate --split-debug-info` مع رفع symbols إلى Crashlytics) لضبط الحجم والمرونة
- [ ] بوابة بناء release في CI (توقيع من Secrets) + فحص تبعيات مجدول
- [ ] تجميد إصدار Flutter موحّداً (CI = محلي = وثيقة الإصدار)
- [ ] مسار تجريبي TestFlight/Internal Testing + قائمة Smoke (READY_CHECK الحالية مرجع)

## 9. الحكم على جاهزية الإصدار

**FAIL / UNVERIFIED:** لا يوجد أي مخرج إصدار موقّع حقيقي (لا keystore، لا AAB، لا مسار نشر)، وعدة إعدادات متجر حاسمة ناقصة. Debug build الناجح يثبت سلامة المشروع التقني، **ولا يثبت الجاهزية للإصدار**.
