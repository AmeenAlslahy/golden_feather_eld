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

## DRIVER APP SCOPE RULE

This Flutter application is a **DRIVER application**. It MUST implement only functionality that the authenticated DRIVER is allowed to view or perform.

Do NOT implement Carrier, Fleet Manager, Administrator, Mechanic, Dispatcher, or back-office management functionality inside the driver application.

For every requirement and endpoint, classify it first as:
- `DRIVER_VIEW`
- `DRIVER_ACTION`
- `DRIVER_RESPONSE_TO_EXTERNAL_ACTION`
- `CARRIER_ACTION` (Out of Scope)
- `ADMIN_ACTION` (Out of Scope)
- `BACKEND_ONLY` (Out of Scope)
- `SHARED` (Only the driver side of the workflow is in scope)

When auditing requirements:
- Do not mark a Carrier/Admin/Backend requirement as "Missing". Mark it as **OUT OF DRIVER APP SCOPE**.
- Backend authorization remains authoritative for security. Hiding a carrier action in Flutter is not sufficient; do not build the action at all.
- Do not integrate management endpoints unless the driver's workflow explicitly requires them.
