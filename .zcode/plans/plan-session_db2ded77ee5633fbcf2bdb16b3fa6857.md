تنفيذ المرحلة الأولى فقط من خطة إصلاح DVIR: تصحيح Models/DTOs/Mappers — بلا commit، بلا أي أمر Git يغيّر الحالة، بلا لمس ملفات WIP الخاصة بك (edit_log_*، time_picker_sheet، l10n، اختبارات logs)، بلا تعديل تصميم.

التعديلات الثلاثة (ملفات lib الثلاثة المطلوبة):

1) lib/features/dvir/domain/entities/dvir_report.dart — fromWire:
إضافة جواز تصفية ثانية تطبّع الصيغة التعدادية (استبدال "_" بمسافة ثم مقارنة غير حساسة لحالة الأحرف): HAS_DEFECTS → hasDefects، VEHICLE_CONDITION_SATISFACTORY → satisfactory، وكذلك DEFECTS_CORRECTED / DEFECTS_NEED_NOT_BE_CORRECTED. الصيغة النصية الحالية تبقى كما هي، وغير المطابق يبقى unknown (لا satisfactory صامتة أبداً).

2) lib/features/dvir/data/mappers/dvir_mappers.dart — buildDvirCreateBody:
- الموقع: إرسال location كنص كما كتبه السائق دائماً (عقد openapi: location string) بدل إسقاطه إن لم يكن "lat, lon"، مع latitude/longitude كحقول عُليا رقمية فقط حين يُحلل النص كزوج إحداثيات كامل (زوج ناقص = لا إحداثيات، لا اختراع).
- extractDetects: تضمين itemCode في العيوب المتداخلة المرسلة (موجود في DvirDefectItem بالعقد) — كود العيب لم يكن يصل في الشكل المتداخل.
- لا مساس بـ syncStatus/trailerNumbers/deviceId-query في هذه المرحلة — تُحسم في المرحلة 3 مع جسم الإنشاء الكامل.

3) lib/backend/adapters/eld_engine/models/dvir_dto.dart:
- DvirDefectDto: إضافة id اختياري يُقرأ من صفوف defects/detects ويُحفظ في toJson (حالياً يضيع معرف العيب القادم من الخادم).
- إصلاح قراءة location: الخريطة {latitude, longitude} تُقرأ "lat, lon" (الفرع الحالي ميت لأن toString على Map غير null) — والنص يمر كما هو.

اختبارات (ملفات الاختبار الثلاثة القائمة فقط، بأسلوبها):
- dvir_fixes_verification_test.dart: مجموعة حالات الصيغة التعدادية + بقاء غير المعروف unknown.
- dvir_submission_test.dart: نص حر يُرسل كما هو بلا إحداثيات؛ زوج إحداثيات كامل يضيف latitude/longitude مع حفظ النص؛ زوج ناقص بلا إحداثيات؛ فارغ بلا حقول؛ itemCode في detects المتداخلة.
- dvir_dto_test.dart: بقاء id من flat/nested/trailers؛ null عند غيابه؛ قراءة location كخريطة وكنص.

البوابة بعد التنفيذ: flutter analyze على المشروع + flutter test على test/features/dvir وtest/audit_task05/dvir_vehicle_scope_test.dart فقط (كلها Mock — صفر طلبات لإنتاج snsoft.cloud). أخطاء Logs/l10n الظاهرة من WIP الخاص بك تُوثَّق كما هي دون تعديل.

ثم تقرير المرحلة الأولى بالعربية بالأدلة (قبل/بعد لكل mapping) وانتظار موافقتك على المرحلة الثانية (Pagination). لا commit ولا push.