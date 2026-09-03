1. نظرة عامة
توفر هذه المجموعة من نقاط النهاية واجهة كاملة لإدارة المستخدمين والصلاحيات والاشتراكات في خادم Traccar. تشمل العمليات إنشاء المستخدمين، تحديثهم، حذفهم، والاستعلام عنهم، بالإضافة إلى إدارة صلاحياتهم واشتراكاتهم في النظام.

2. الفوائد والميزات
إدارة المستخدمين الشاملة: إنشاء، تحديث، حذف، واستعلام المستخدمين مع دعم البحث المتقدم.
صلاحيات دقيقة: التحكم في صلاحيات المستخدمين على مستوى الموارد والأجهزة والمجموعات.
اشتراكات مرنة: إدارة اشتراكات المستخدمين في الأجهزة والمجموعات.
سمات مخصصة: إضافة سمات مخصصة لكل مستخدم لتخزين معلومات إضافية.
أمان متقدم: دعم المصادقة وإدارة الجلسات.
3.1.1. الحصول على قائمة المستخدمين
GET /users

الوصف: الحصول على قائمة بجميع المستخدمين المسجلين في النظام مع إمكانية البحث.

معاملات Query
المعامل	النوع	الإلزامية	الوصف	القيمة الافتراضية
search	string	لا	بحث في اسم المستخدم أو البريد الإلكتروني	-
limit	integer	لا	الحد الأقصى لعدد النتائج	100
offset	integer	لا	الإزاحة للترقيم	0
الاستجابة
الحقل	النوع	الوصف
id	integer	معرف المستخدم
name	string	اسم المستخدم
email	string	البريد الإلكتروني
phone	string	رقم الهاتف
admin	boolean	هل المستخدم مشرف؟
map	string	خريطة المستخدم المفضلة (osm, google, bing)
language	string	لغة المستخدم (ar, en, fr, إلخ)
attributes	object	سمات إضافية
مثال
الطلب:

GET /api/v1/tracker/traccar/users?search=admin
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": [
        {
            "id": 1,
            "name": "Admin User",
            "email": "admin@example.com",
            "phone": "+966501234571",
            "admin": true,
            "map": "osm",
            "language": "ar",
            "attributes": {
                "theme": "dark",
                "department": "IT"
            }
        },
        {
            "id": 2,
            "name": "Ahmed Mohamed",
            "email": "ahmed@example.com",
            "phone": "+966501234572",
            "admin": false,
            "map": "osm",
            "language": "ar",
            "attributes": {
                "theme": "light",
                "department": "Logistics"
            }
        }
    ],
    "meta": {
        "total": 2,
        "limit": 100,
        "offset": 0
    }
}
3.1.2. الحصول على مستخدم محدد
GET /users/{id}

الوصف: الحصول على معلومات مستخدم محدد بواسطة معرفه.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
id	integer	نعم	معرف المستخدم
مثال
الطلب:

GET /api/v1/tracker/traccar/users/2
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": {
        "id": 2,
        "name": "Ahmed Mohamed",
        "email": "ahmed@example.com",
        "phone": "+966501234572",
        "admin": false,
        "map": "osm",
        "language": "ar",
        "attributes": {
            "theme": "light",
            "department": "Logistics",
            "employeeId": "EMP-001"
        }
    }
}
3.1.3. إنشاء مستخدم جديد
POST /users

الوصف: إنشاء مستخدم جديد في النظام.

معاملات Body (JSON)
المعامل	النوع	الإلزامية	الوصف	القيمة الافتراضية
name	string	نعم	اسم المستخدم	-
email	string	نعم	البريد الإلكتروني (يجب أن يكون فريداً)	-
phone	string	لا	رقم الهاتف	null
admin	boolean	لا	هل المستخدم مشرف؟	false
map	string	لا	خريطة المستخدم المفضلة	'osm'
language	string	لا	لغة المستخدم	'en'
attributes	object	لا	سمات إضافية	{}
مثال
الطلب:

POST /api/v1/tracker/traccar/users
Authorization: Bearer <your_access_token>
Content-Type: application/json

{
  "name": "Khalid Omar",
  "email": "khalid@example.com",
  "phone": "+966501234574",
  "admin": false,
  "map": "osm",
  "language": "ar",
  "attributes": {
    "department": "Fleet Management",
    "employeeId": "EMP-002"
  }
}
الاستجابة:

{
    "code": 201,
    "status": true,
    "message": "تم إنشاء المستخدم بنجاح",
    "data": {
        "id": 4,
        "name": "Khalid Omar",
        "email": "khalid@example.com",
        "phone": "+966501234574",
        "admin": false,
        "map": "osm",
        "language": "ar",
        "attributes": {
            "department": "Fleet Management",
            "employeeId": "EMP-002"
        }
    }
}
3.1.4. تحديث مستخدم
PUT /users/{id}

الوصف: تحديث معلومات مستخدم موجود.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
id	integer	نعم	معرف المستخدم
معاملات Body (JSON)
المعامل	النوع	الإلزامية	الوصف
name	string	لا	اسم المستخدم الجديد
email	string	لا	البريد الإلكتروني الجديد
phone	string	لا	رقم الهاتف الجديد
admin	boolean	لا	صلاحية الإشراف
map	string	لا	خريطة المستخدم المفضلة
language	string	لا	لغة المستخدم
attributes	object	لا	سمات إضافية جديدة
مثال
الطلب:

PUT /api/v1/tracker/traccar/users/4
Authorization: Bearer <your_access_token>
Content-Type: application/json

{
  "name": "Khalid Omar - Updated",
  "phone": "+966501234575",
  "attributes": {
    "department": "Fleet Management",
    "employeeId": "EMP-002",
    "position": "Fleet Manager"
  }
}
الاستجابة:

{
    "code": 200,
    "status": true,
    "message": "تم تحديث المستخدم بنجاح",
    "data": {
        "id": 4,
        "name": "Khalid Omar - Updated",
        "email": "khalid@example.com",
        "phone": "+966501234575",
        "admin": false,
        "map": "osm",
        "language": "ar",
        "attributes": {
            "department": "Fleet Management",
            "employeeId": "EMP-002",
            "position": "Fleet Manager"
        }
    }
}
3.1.5. حذف مستخدم
DELETE /users/{id}

الوصف: حذف مستخدم موجود من النظام.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
id	integer	نعم	معرف المستخدم
مثال
الطلب:

DELETE /api/v1/tracker/traccar/users/4
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "message": "تم حذف المستخدم بنجاح"
}
3.2.1. الحصول على صلاحيات المستخدم
GET /permissions/{userId}

الوصف: الحصول على صلاحيات مستخدم محدد.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
userId	integer	نعم	معرف المستخدم
الاستجابة
الحقل	النوع	الوصف
userId	integer	معرف المستخدم
deviceIds	array	قائمة معرفات الأجهزة التي يمكن للمستخدم الوصول إليها
groupId	integer	معرف المجموعة التي يمكن للمستخدم الوصول إليها
مثال
الطلب:

GET /api/v1/tracker/traccar/permissions/2
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": {
        "userId": 2,
        "deviceIds": [
            101,
            102
        ],
        "groupId": 5
    }
}
3.2.2. تحديث صلاحيات المستخدم
PUT /permissions/{userId}

الوصف: تحديث صلاحيات مستخدم محدد.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
userId	integer	نعم	معرف المستخدم
معاملات Body (JSON)
المعامل	النوع	الإلزامية	الوصف
deviceIds	array	لا	قائمة معرفات الأجهزة الجديدة
groupId	integer	لا	معرف المجموعة الجديد
مثال
الطلب:

PUT /api/v1/tracker/traccar/permissions/2
Authorization: Bearer <your_access_token>
Content-Type: application/json

{
  "deviceIds": [101, 102, 103],
  "groupId": 5
}
الاستجابة:

{
    "code": 200,
    "status": true,
    "message": "تم تحديث الصلاحيات بنجاح",
    "data": {
        "userId": 2,
        "deviceIds": [
            101,
            102,
            103
        ],
        "groupId": 5
    }
}
3.3.1. الحصول على اشتراكات المستخدم
GET /users/{userId}/subscriptions

الوصف: الحصول على قائمة اشتراكات المستخدم في الأجهزة والمجموعات.

معاملات المسار
المعامل	النوع	الإلزامية	الوصف
userId	integer	نعم	معرف المستخدم
مثال
الطلب:

GET /api/v1/tracker/traccar/users/2/subscriptions
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": {
        "devices": [
            101,
            102
        ],
        "groups": [
            5
        ]
    }
}
3.3.2. إضافة اشتراك للمستخدم
POST /subscriptions

الوصف: إضافة اشتراك جديد لمستخدم في جهاز أو مجموعة.

معاملات Body (JSON)
المعامل	النوع	الإلزامية	الوصف
userId	integer	نعم	معرف المستخدم
deviceId	integer	لا	معرف الجهاز (إذا كان الاشتراك لجهاز)
groupId	integer	لا	معرف المجموعة (إذا كان الاشتراك لمجموعة)
مثال
الطلب:

POST /api/v1/tracker/traccar/subscriptions
Authorization: Bearer <your_access_token>
Content-Type: application/json

{
  "userId": 2,
  "deviceId": 104
}
الاستجابة:

{
    "code": 201,
    "status": true,
    "message": "تم إضافة الاشتراك بنجاح",
    "data": {
        "userId": 2,
        "deviceId": 104,
        "groupId": null
    }
}
3.4.1. الحصول على سمات المستخدمين
GET /attributes/user

الوصف: الحصول على قائمة بجميع سمات المستخدمين المستخدمة في النظام.

مثال
الطلب:

GET /api/v1/tracker/traccar/attributes/user
Authorization: Bearer <your_access_token>
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": [
        "theme",
        "department",
        "employeeId",
        "position",
        "timezone"
    ]
}
4.1. التحقق من صحة بيانات المستخدم
POST /users/validate

الوصف: التحقق من صحة بيانات المستخدم قبل الإنشاء أو التحديث.

معاملات Body (JSON)
المعامل	النوع	الإلزامية	الوصف
name	string	نعم	اسم المستخدم
email	string	نعم	البريد الإلكتروني
مثال
الطلب:

POST /api/v1/tracker/traccar/users/validate
Authorization: Bearer <your_access_token>
Content-Type: application/json

{
  "name": "Test User",
  "email": "test@example.com",
}
الاستجابة:

{
    "code": 200,
    "status": true,
    "data": {
        "valid": true,
        "message": "بيانات المستخدم صالحة"
    }
}
5. التنبيهات والتوصيات
التنبيه	الوصف
تفرد البريد الإلكتروني	يجب أن يكون البريد الإلكتروني فريداً لكل مستخدم. تكراره سيؤدي إلى فشل الإنشاء.
كلمة المرور	تأكد من استخدام كلمات مرور قوية (8 أحرف على الأقل، أحرف كبيرة وصغيرة، أرقام، رموز).
صلاحيات الإشراف	فقط المستخدمون المشرفون (admin=true) يمكنهم الوصول إلى جميع البيانات وإدارة المستخدمين الآخرين.
الاشتراكات	يمكن للمستخدم الوصول فقط إلى الأجهزة والمجموعات المشترك فيها.
حذف المستخدمين	حذف المستخدم نهائي ولا يمكن استعادته. تأكد من نسخ البيانات احتياطياً قبل الحذف.
الأمان	لا تقم بتخزين كلمات المرور في الكود أو السجلات. استخدم متغيرات البيئة أو نظام الإعدادات.
6. الخاتمة
تغطي هذه المجموعة جميع عمليات إدارة المستخدمين والصلاحيات والاشتراكات الأساسية والمتقدمة. توفر نقاط النهاية المرونة اللازمة لبناء أنظمة إدارة أسطول آمنة وقابلة للتوسع مع تحكم دقيق في الوصول.

الملف التالي: 06-events-and-notifications.md – يغطي إدارة الأحداث والإشعارات.