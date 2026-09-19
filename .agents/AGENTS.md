## قاعدة إلزامية — قبل أي commit

1. flutter analyze  → يجب 0 errors، 0 warnings جديدة
2. flutter test     → كل الاختبارات تمر
3. bash scripts/check_architecture.sh (على Linux/Mac) أو powershell -ExecutionPolicy Bypass -File scripts/check_architecture.ps1 (على Windows)

**لا commit بدون هذه الثلاثة.**

## ممنوع — production code للتكيّف مع اختبارات

❌ إضافة شرط `if (AppEnvironment.mock) return;` في production provider.
❌ إضافة `if (kDebugMode)` لحل مشكلة اختبار.
❌ `@visibleForTesting` فقط للـ helpers الصغيرة، لا لتغيير السلوك.

✅ الترتيب الصحيح:
   1. الاختبار يستخدم `ProviderContainer(dispose)`.
   2. أو يُتجاوِز provider بـ fake.
   3. أو `fakeAsync` للـ timer-based logic.

**عند مواجهة Test Leak:**
- أرسل الخطأ.
- لا تُعدِّل production code.
- انتظر قرار المالك.
