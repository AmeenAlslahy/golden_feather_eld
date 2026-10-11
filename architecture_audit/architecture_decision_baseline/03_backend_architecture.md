# 03 — بنية الخلفية (Backend Architecture)

## 1. ملكية العقود (`contracts/` — 15 ملفاً)

- العقود **مجردة فعلاً**: `abstract interface class` + `Result<T>` + `DriverId`/`DvirId` المميزة. لا Dio ولا `Response` ولا رموز HTTP في التواقيع.
- الاستثناءات الموثقة: استيراد DTO المحوّل في `daily_logs_backend:3-4` (V-BND-02)؛ `RawJson` في 6+ تواقيع؛ `expectedOwnerDriverId?` في 4 عقود (آلية أمان بأثر توقيعي).
- `contract_enums.dart`: قيم wire موثقة ("mirror the wire values") — قرار توثيقي مقصود، لا تسرب عفوي.

## 2. مسؤوليات المحوّلات (`adapters/`)

| المحوّل | المسؤولية الفعلية | الملاحظة |
|---|---|---|
| `EldEngineAdapter` | تجميع 13 sub-backend تشترك `ApiClient` واحداً (`late final` كسول) | نقي ("No business logic") — ملتزَم به |
| `sub/eld_*` (13) | HTTP + تحليل جزئي + `mapDioException` في `catch` | `eld_auth_backend` يبني URL مطلقاً ويتجاوز `ApiClient.get` (يستخدم `dio.post` مباشرة) |
| `mappers/` (5) | تحويل wire→كيان عالي الجودة (`json['driver']?['id']` عبر `asInt`) | لكن `fallback: 0` يمحو التمييز مفقود/صفر |
| `models/` (5 DTOs) | نماذج النقل | `DvirDto.fromJson/toJson` يحمل منطق إعادة كتابة حقول (BACK-006 سابقاً) |
| `MockAdapter` | تجميع 13 mock | تعليق قديم ("17 contracts" مقابل 22 موقعاً مقاساً)؛ `mock_rules_screen_backend` يستورد من `eld_engine` (الموك ليس مستقلاً) |

## 3. ملكية HTTP (`http/`)

- `ApiClient`: Dio واحد + `LenientJsonTransformer` + مهلات + إعادة GET (2 + 400ms) — **لا اعتراضات داخلية**؛ تُركَّب في `backend_network_providers` (Auth epoch-tagged + RequestLogger/debug + TimeDrift).
- `EldEndpoints`: ثوابت مسارات (`/eld/dot-inspection…`) — مرجع واحد.
- `api_config.dart` + `api_response.dart` الخلفيان: **معلّقان بالكامل** (DEPRECATED → core) بلا مستوردين — ميتان.
- تطبيع URL في 4 مواضع (`backend_identity`, `server_config`, `api_config.normalized`, مزود الشبكة) — طبقات مختلفة (هوية/إعداد/عميل) لا نسخاً حرفية بالضرورة؛ تُسجَّل كملاحظة لا خرق.

## 4. آلية الاختيار (`providers/`)

```
AppEnvironmentConfig.current + savedServerUrl + savedBackendType
  → resolveRuntimeBackend() → choice{useMock, serverUrl}
    → useMock ? MockAdapter() : EldEngineAdapter.create(baseUrl, apiClient)
      → activeBackendProvider → 15 مزود عقد → features
```

- الاختيار مركزي وحقيقي (mock للبيئة/التطوير فقط؛ الإنتاج يتجاهل flag الموك).
- `traccarNativeClientProvider`: mock/حقيقي حسب البيئة — **لكن** `app_initializer` يبني `TraccarNativeClientImpl()` يدوياً متجاوزاً إياه (V-BND-01).
- `unauthenticatedEventProvider` (`StreamController<int>` بالـ epoch): فصل 401 عن `AuthState` مباشرة — تصميم سليم.

## 5. اتساق mock/حقيقي

| البعد | الحالة |
|---|---|
| تغطية الموك | جزئية (22 `UnimplementedError` من ~60) — تعليق "17" قديم |
| تطابق الأشكال | **غير مضمون**: `{'reports': []}` مقابل `rawJson['data']` (BACK-008)؛ الموك يختم `driverId ?? 101` بينما الحقيقي قد يعيد 0/مفقوداً |
| القاعدة | `MockAdapter`: "No network/timers/channels" — ملتزَم به |

## 6. حدود تحويل الأخطاء

- `mapDioException`: نقطة الترجمة الوحيدة المعلنة (timeouts/connection/certificates/cancel…) → `AppError` مع `context` يحمل `statusCode` غالباً.
- الاستثناء: `eld_auth_backend` يبني `ServerError` يدوياً مع `context.statusCode` — متسق.
- **الفجوة**: `duty_status_tracker:370-374` يقرأ `error.context?['statusCode']` لا الحقل المسمّى — أي `ServerError` بلا `context` يُصنَّف شبكياً (مُثبت باختبار فاشل).

## 7. تتبع عملية تمثيلية: تسجيل الدخول

```
auth_page → authStateProvider.login()
  → LoginUseCase (تحقق شكلي)
    → AuthRepositoryImpl.login() [serverUrl؟ guardedNetwork؟]
      → AuthBackend.login (عقد)
        → EldAuthBackend.login [URL مطلق + form-urlencoded + plain + redirect off]
          → Dio → POST {baseUrl}/api/session
      → AuthSessionDto → saveSession + saveUser
  → SessionEpoch.bump()
```

المسار **مطابق للمتوقع** طبقة بطبقة. الانحرافات: (أ) تجاوز `ApiClient.get` في `eld_auth_backend` (يستخدم `dio` مباشرة)؛ (ب) `LoginUseCase` تحقق مكرر مع النموذج.

## 8. هل مستودعات الميزات زائدة؟ (الحكم المطلوب صراحة)

**لا — مع استثناءات.** بالأدلة:

| المستودع | ما يضيفه فوق التفويض | الحكم |
|---|---|---|
| `AuthRepositoryImpl` (177) | عناوين + `guardedNetwork` + ترجمة 401 + DTO→كيان + تخزين جلسة/مستخدم | **جوهري** |
| `LogRepositoryImpl` (501) | مصادر محلية + طابور + سلطة زمنية + تجميع نماذج | **جوهري** (مكتظ — يحتاج تقسيماً لا حذفاً) |
| `InspectionRepositoryImpl` (504) | ملكية + epoch + بوابة FMCSA + حذف ملفات | **جوهري** (بعد EC-0.2a) |
| `DvirRepositoryImpl` (368) | خرائط + طابور + قواعد DVIR-09 | **جوهري غالباً** |
| `StatusDashboardRepositoryImpl` (108) | تمرير شبه صرف؟ (لم يُقرأ كاملاً — يُسجَّل غير متحقق) | **UNKNOWN** |
| `SyncRepositoryImpl` (156) | طابور SharedPreferences موازٍ لـ `SyncEngine` | **مكرر وظيفياً** (حي لكن مزدوج) |
| `TrackingRepositoryImpl` (222) | تنسيق service/local/native + صلاحيات | **جوهري** (متضخم بالصلاحيات) |
| `CoDriverRepositoryImpl` (136) | كاش static + تنسيق | **جوهري ناقص** (بلا إبطال) |
| `VehicleRepositoryImpl` (74) | تمرير رفيع | **رفيع لكن مشروع** (نقطة حقن + `guardedNetwork`) |

القاعدة: المستودع الرفيع **ليس** زائداً إذا كان نقطة حقن/اختبار مستقرة. الزائد الحقيقي الوحيد المرشح: `vehicleBackendProviderAlias` (تمرير أعمى) — لا المستودعات.
