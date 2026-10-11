# 08 — التحقق من الحدود الاعتمادية (Dependency Validation)

> كل حافة أدناه من مخطط مُعاد بناؤه (1,726 حافة). التصنيف: VALID / CONFIRMED_VIOLATION / CONTEXT_DEPENDENT / NEEDS_MORE_EVIDENCE. العقدة العامة تُحكم لا الاستهلاك.

## 1. `core → features` (7 حواف)

| المصدر → الهدف | النوع | الغرض | التبرير | الخطر | التصنيف | الثقة |
|---|---|---|---|---|---|---|
| `core/di/app_providers.dart` → `auth/domain+data` (3) | تركيب | حقن مستودع auth | معلن (`ONLY ALLOWED`) وجذر وحيد من نوعه | منخفض | **CONTEXT_DEPENDENT** | عالية |
| `core/events/eld_events_provider` → tracking datasource + entity (2) | بث أحداث | فصل HOS/Sync عن المصدر | **يفشل**: يستورد الملموس لا عقداً | متوسط | **CONFIRMED_VIOLATION** | عالية |
| `core/providers/driver_rules_provider` → account presentation (1) | اشتقاق حالة | قواعد السائق | **يفشل**: core يراقب presentation + عمر autoDispose تابع لصفحة | متوسط | **CONFIRMED_VIOLATION** | عالية |
| `core/widgets/connection_status_indicator` → `routes.dart` (1) | ملاحة | `context.push(AppRoutes.connection)` | **يفشل**: مكوّن core يعرف app + عضو دورة | منخفض | **CONFIRMED_VIOLATION** | عالية |

## 2. `backend → features` (9 حواف)

| المصدر → الهدف | النوع | الغرض | التبرير | الخطر | التصنيف | الثقة |
|---|---|---|---|---|---|---|
| contracts/mapper/eld/mock → `account/application/models` (4) | نموذج مشترك | قراءة/كتابة/تعريف الشاشة | **يفشل**: النموذج في ميزة يستهلكها 4 ملفات بنية | عالٍ (نقل النموذج يكسر 4) | **CONFIRMED_VIOLATION** | عالية |
| `auth_interceptor` → auth data+domain (2) | جلسة/كيان | إرفاق الكوكي + قراءة الجلسة | مقبول وظيفياً (المعترض يحتاج الجلسة)؛ **موضعه** بنية تحتية تعرف تفاصيل ميزة | متوسط | **CONTEXT_DEPENDENT** | متوسطة |
| `backend_network_providers` → traccar_sdk ×3 | تنفيذ أصلي | اختيار mock/حقيقي | مقبول (تركيب بيئة)؛ **موضعه** في backend بدل tracking | منخفض | **CONTEXT_DEPENDENT** | متوسطة |

## 3. `domain → data` و`domain → presentation`

| الاتجاه | النتيجة |
|---|---|
| `lib/domain/*` → بيانات/عرض | **صفر حواف** — نظيف (يستورد نفسه فقط) |
| `features/*/domain` → بيانات/عرض الميزة | **صفر حواف** — نظيف |
| الاستثناءان الحقيقيان | `hos/domain → logs/domain` (عقد ميزة أخرى) + `hos/domain → backend contract + core service` — **خرق نقاء لا اتجاه طبقي** (يُسجَّل في 05/11 لا هنا) |

## 4. `presentation → data` (20 حافة)

**الحكم العام: VALID مع 3 استثناءات.** الـ17 استهلاك مزودات تركيب (`data/providers`) — نمط Riverpod طبيعي؛ المشكلة **موضع تعريف المزود** لا الاستهلاك.

| الاستثناء | المصدر → الهدف | التصنيف |
|---|---|---|
| صفحة connection تستهلك تركيب tracking | `eld_connection_page → tracking/data/providers` | **CONFIRMED_VIOLATION** (عبور ميزة لتركيب ميزة) |
| مزود hos يركّب logs+sync | `hos_engine_provider → log/sync data/providers` | **CONTEXT_DEPENDENT** (تنسيق معلن، لكنه coupling) |
| صفحة inspection تستهلك تركيب logs | `send_logs_page → logs/data/providers` | **CONTEXT_DEPENDENT** (حاجة عرضية مشروعة، بلا عقد) |

## 5. `feature → feature` (عبر presentation أساساً)

| المصدر → الهدف | النوع | التصنيف |
|---|---|---|
| logs → home (كتابة dashboard ×5) | حالة مشتركة | **CONFIRMED_VIOLATION** |
| dvir → vehicle/home (قراءة + كتابة) | هوية المركبة/اللوحة | **CONFIRMED_VIOLATION** (كتابة) / VALID (قراءة هوية) |
| codriver → HOS/tracking (5 ملفات لحارس) | منطق حراسة | **CONFIRMED_VIOLATION** (استيراد تنفيذ لا عقد) |
| inspection → logs (تركيب) | قراءة سجلات | CONTEXT_DEPENDENT |
| connection → vehicle (كيان + مزود) | اختيار المركبة | VALID (كيان عام + قراءة) |
| account/codriver/settings → home (`eld_drawer`) | shell مشترك | **CONFIRMED_VIOLATION** (الموضع لا الاستهلاك) |
| `sync_providers` → auth presentation + logs data | تركيب | **CONFIRMED_VIOLATION** |

## 6. `routes ↔ pages`

| الاتجاه | الحكم |
|---|---|
| `*_routes → pages` (تسجيل) | VALID (وظيفة التسجيل) |
| `pages → routes.dart` (ملاحة/مفتاح) | VALID منفردة، **مكونة للدورة مجتمعة** |
| الدورة 25 ملفاً | **CONFIRMED_VIOLATION** هيكلي (C1) — حميد تشغيلياً، قاتل للعزل |
| `home_page ↔ driving_lock_screen` | **CONFIRMED_VIOLATION** (تبادل مباشر؛ السبب مزود واحد misplaced) |

## 7. خلاصة التصنيف

| التصنيف | العدد |
|---|---|
| VALID | الغالبية الساحقة (~1,650 حافة) |
| CONFIRMED_VIOLATION | 12 بنداً (مسرودة أعلاه، بلا تكرار) |
| CONTEXT_DEPENDENT | 7 بنود |
| NEEDS_MORE_EVIDENCE | 1 (ترتيب تهيئة C4) |
