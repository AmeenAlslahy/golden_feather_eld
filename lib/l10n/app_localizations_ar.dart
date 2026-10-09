// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get auditTrail => 'سجل التدقيق';

  @override
  String get auditTrailNote =>
      'يؤكد هذا السجل حفظ كل إجراء مع المستخدم والوقت والقيم السابقة والجديدة. لا يمكن تعديل هذا السجل أو حذفه.';

  @override
  String get auditNoRecords => 'لا توجد سجلات';

  @override
  String get auditLoadFailed => 'تعذر تحميل سجل التدقيق.';

  @override
  String get vehicleStatusOutOfService => 'خارج الخدمة';

  @override
  String get vehicleStatusRestricted => 'مقيّدة';

  @override
  String get vehicleStatusAvailable => 'متاحة';

  @override
  String get driverName => 'اسم السائق';

  @override
  String get driverId => 'معرف السائق';

  @override
  String get license => 'الرخصة';

  @override
  String get licenseState => 'ولاية الرخصة';

  @override
  String get exemptDriver => 'حالة الإعفاء';

  @override
  String get unidentifiedDriving => 'قيادة غير محددة';

  @override
  String get coDriverId => 'معرف المساعد';

  @override
  String get logDate => 'تاريخ السجل';

  @override
  String get displayDate => 'تاريخ العرض';

  @override
  String get displayLocation => 'موقع العرض';

  @override
  String get eldRegId => 'معرف تسجيل ELD';

  @override
  String get eldIdentifier => 'معرف ELD';

  @override
  String get provider => 'المزود';

  @override
  String get periodStart => 'بداية الفترة';

  @override
  String get dataDiag => 'تشخيص البيانات';

  @override
  String get deviceMalf => 'أعطال الجهاز';

  @override
  String get vin => 'رقم الهيكل';

  @override
  String get carrier => 'الناقل';

  @override
  String get mainOffice => 'المكتب الرئيسي';

  @override
  String get homeTerminal => 'المحطة الرئيسية';

  @override
  String get insertDutyStatus => 'إدخال حالة';

  @override
  String get addButton => 'إضافة';

  @override
  String get eventAddedSuccess => 'تمت إضافة الحدث بنجاح';

  @override
  String get appName => 'Golden Feather ELD';

  @override
  String get appSlogan => 'الريشة الذهبية - تتبع الامتثال الميداني';

  @override
  String get trackingTitle => 'التتبع';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get statusTitle => 'الحالة';

  @override
  String get saveButton => 'حفظ';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get okButton => 'موافق';

  @override
  String get deleteButton => 'حذف';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get shareButton => 'مشاركة';

  @override
  String get clearButton => 'مسح';

  @override
  String get refreshButton => 'تحديث';

  @override
  String get locationButton => 'إرسال الموقع';

  @override
  String get statusButton => 'عرض الحالة';

  @override
  String get settingsButton => 'تغيير الإعدادات';

  @override
  String get invalidValue => 'قيمة غير صالحة';

  @override
  String get disabledValue => 'معطل';

  @override
  String get idLabel => 'معرّف الجهاز';

  @override
  String get urlLabel => 'عنوان الخادم';

  @override
  String get accuracyLabel => 'دقة الموقع';

  @override
  String get highestAccuracyLabel => 'أعلى';

  @override
  String get highAccuracyLabel => 'عالية';

  @override
  String get mediumAccuracyLabel => 'متوسطة';

  @override
  String get lowAccuracyLabel => 'منخفضة';

  @override
  String get intervalLabel => 'الفاصل الزمني (ثوانٍ)';

  @override
  String get fastestIntervalLabel => 'أسرع فاصل زمني (ثوانٍ)';

  @override
  String get distanceLabel => 'المسافة (أمتار)';

  @override
  String get angleLabel => 'الزاوية (درجات)';

  @override
  String get heartbeatLabel => 'نبض الثبات (ثوانٍ)';

  @override
  String get bufferLabel => 'تخزين مؤقت دون اتصال';

  @override
  String get wakelockLabel => 'قفل التنبيه';

  @override
  String get stopDetectionLabel => 'اكتشاف التوقف';

  @override
  String get preferPlatformProvidersLabel => 'استخدام مزودي الموقع الأصليين';

  @override
  String get serverNotConfigured => 'إعدادات الخادم مفقودة';

  @override
  String get trackingLabel => 'تتبع مستمر';

  @override
  String get advancedLabel => 'إعدادات متقدمة';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get optimizationMessage =>
      'لضمان تتبع موثوق، يرجى تعطيل تحسين البطارية لهذا التطبيق.';

  @override
  String get passwordError => 'كلمة المرور خاطئة';

  @override
  String get disclosureMessage =>
      'يقوم هذا التطبيق بجمع بيانات الموقع والنشاط في الخلفية وإرسالها إلى الخادم المحدد.';

  @override
  String get configurationMessage => 'هل تريد تطبيق الإعدادات الجديدة؟';

  @override
  String get startAction => 'بدء';

  @override
  String get stopAction => 'إيقاف الخدمة';

  @override
  String get sosAction => 'ارسال استغاثة';

  @override
  String get home => 'الرئيسية';

  @override
  String get inspection => 'التفتيش';

  @override
  String get checklist => 'قائمة التحقق';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get startInspection => 'بدء التفتيش';

  @override
  String get stopInspection => 'إيقاف التفتيش';

  @override
  String get pauseInspection => 'إيقاف مؤقت';

  @override
  String get resumeInspection => 'استئناف';

  @override
  String get submitReport => 'إرسال التقرير';

  @override
  String get saveDraft => 'حفظ كمسودة';

  @override
  String get discardDraft => 'تجاهل المسودة';

  @override
  String get inspectionTitle => 'عنوان التفتيش';

  @override
  String get inspectionLocation => 'موقع التفتيش';

  @override
  String get inspectionDate => 'تاريخ التفتيش';

  @override
  String get inspectionTime => 'وقت التفتيش';

  @override
  String get inspectionDuration => 'مدة التفتيش';

  @override
  String get inspectorName => 'اسم المفتش';

  @override
  String get inspectionStatus => 'حالة التفتيش';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusFailed => 'فشل';

  @override
  String get statusRequiresReview => 'يحتاج مراجعة';

  @override
  String get statusScheduled => 'مجدول';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get checklistTitle => 'عنوان القائمة';

  @override
  String get checklistCategory => 'تصنيف القائمة';

  @override
  String get addChecklist => 'إضافة قائمة';

  @override
  String get editChecklist => 'تعديل القائمة';

  @override
  String get deleteChecklist => 'حذف القائمة';

  @override
  String get checklistItems => 'عناصر القائمة';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get removeItem => 'إزالة عنصر';

  @override
  String get itemTypeText => 'نص';

  @override
  String get itemTypeNumber => 'رقم';

  @override
  String get itemTypeYesNo => 'نعم / لا';

  @override
  String get itemTypeMultipleChoice => 'اختيار من متعدد';

  @override
  String get itemTypePhoto => 'صورة';

  @override
  String get itemTypeSignature => 'توقيع';

  @override
  String get itemTypeDate => 'تاريخ';

  @override
  String get itemTypeTime => 'وقت';

  @override
  String get itemTypeBarcode => 'باركود';

  @override
  String get photoRequired => 'الصورة مطلوبة';

  @override
  String get signatureRequired => 'التوقيع مطلوب';

  @override
  String get notesRequired => 'الملاحظات مطلوبة';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get retakePhoto => 'إعادة التصوير';

  @override
  String get photoPreview => 'معاينة الصورة';

  @override
  String get signHere => 'وقع هنا';

  @override
  String get clearSignature => 'مسح التوقيع';

  @override
  String get signaturePreview => 'معاينة التوقيع';

  @override
  String get addNote => 'إضافة ملاحظة';

  @override
  String get editNote => 'تعديل الملاحظة';

  @override
  String get deleteNote => 'حذف الملاحظة';

  @override
  String get syncStatus => 'حالة المزامنة';

  @override
  String get synced => 'متزامن';

  @override
  String get syncing => 'جاري المزامنة...';

  @override
  String syncPending(String count) {
    return '$count معلقة';
  }

  @override
  String syncFailed(String count) {
    return '$count فشلت';
  }

  @override
  String get offline => 'غير متصل';

  @override
  String get lastSync => 'آخر مزامنة';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get autoSync => 'مزامنة تلقائية';

  @override
  String get errorMessage => 'حدث خطأ ما';

  @override
  String get successMessage => 'تمت العملية بنجاح';

  @override
  String get warningMessage => 'تحذير';

  @override
  String get infoMessage => 'معلومة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get permissionDenied => 'تم رفض الإذن';

  @override
  String get locationPermissionDenied => 'يرجى منح إذن الوصول إلى الموقع';

  @override
  String get cameraPermissionDenied => 'يرجى منح إذن الوصول إلى الكاميرا';

  @override
  String get storagePermissionDenied => 'يرجى منح إذن الوصول إلى التخزين';

  @override
  String get confirmDelete => 'هل أنت متأكد من الحذف؟';

  @override
  String get confirmLogout => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get confirmSubmit => 'هل أنت متأكد من إرسال التقرير؟';

  @override
  String get confirmDiscard => 'هل أنت متأكد من تجاهل التغييرات؟';

  @override
  String get unsavedChanges => 'لديك تغييرات غير محفوظة';

  @override
  String get changesWillBeLost => 'سيتم فقدان التغييرات إذا واصلت';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get systemMode => 'وضع النظام';

  @override
  String get themeLabel => 'المظهر';

  @override
  String get aboutLabel => 'حول التطبيق';

  @override
  String get versionLabel => 'الإصدار';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get help => 'المساعدة';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get qrCodeScanner => 'مسح الرمز';

  @override
  String get scanQRCode => 'مسح رمز QR';

  @override
  String get scanningInstructions => 'وجه الكاميرا نحو رمز QR';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get sort => 'ترتيب';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortByName => 'الاسم';

  @override
  String get sortByDate => 'التاريخ';

  @override
  String get sortByStatus => 'الحالة';

  @override
  String get exportPDF => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير Excel';

  @override
  String get print => 'طباعة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get newInspectionAssigned => 'تم تعيين تفتيش جديد';

  @override
  String get inspectionReminder => 'تذكير بالتفتيش';

  @override
  String get inspectionOverdue => 'تفتيش متأخر';

  @override
  String get syncComplete => 'اكتملت المزامنة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get na => 'غير متاح';

  @override
  String get pass => 'ناجح';

  @override
  String get fail => 'راسب';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get unableToConnect => 'تعذر الاتصال بجهاز ELD بالعنوان';

  @override
  String get verifyFollowingItems => 'يرجى التحقق من العناصر التالية:';

  @override
  String get macEnteredCorrectly => 'تم إدخال عنوان MAC بشكل صحيح.';

  @override
  String get hardwareProperlyInstalled => 'تم تركيب جهاز ELD بشكل صحيح.';

  @override
  String get vehiclePowerOn => 'طاقة المركبة قيد التشغيل.';

  @override
  String get bluetoothEnabled => 'البلوتوث مفعل في الجهاز المحمول.';

  @override
  String get gpsEnabled => 'نظام تحديد المواقع GPS مفعل في الجهاز المحمول.';

  @override
  String get enterMacAddress =>
      'أدخل عنوان MAC الخاص بـ ELD والموجود على الجهاز:';

  @override
  String get connect => 'اتصال';

  @override
  String get continueDisconnected => 'متابعة بدون اتصال';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get hoursRecap => 'ملخص الساعات';

  @override
  String get suggestedEvents => 'الأحداث المقترحة';

  @override
  String get unidentifiedEvents => 'الأحداث غير المحددة';

  @override
  String get unclaimed => 'غير مطالب بها';

  @override
  String get rejected => 'مرفوضة';

  @override
  String get noRecords => 'لا توجد سجلات';

  @override
  String get drawSignatureHere => 'ارسم توقيعك هنا';

  @override
  String get fillFormFirst => 'يجب تعبئة النموذج وحفظه أولاً.';

  @override
  String get formLabel => 'النموذج';

  @override
  String get certifyLabel => 'التوثيق';

  @override
  String get editDutyStatus => 'تعديل حالة الخدمة';

  @override
  String get startTime => 'وقت البداية';

  @override
  String get duration => 'المدة';

  @override
  String get status => 'الحالة';

  @override
  String get vehicle => 'المركبة';

  @override
  String get location => 'الموقع';

  @override
  String get manualLocation => 'موقع يدوي';

  @override
  String get events => 'الأحداث';

  @override
  String get form => 'النموذج';

  @override
  String get certify => 'التوثيق';

  @override
  String get driver => 'السائق';

  @override
  String get vehicles => 'المركبات';

  @override
  String get trailers => 'المقطورات';

  @override
  String get shippingDocuments => 'وثائق الشحن';

  @override
  String get coDriver => 'سائق مساعد';

  @override
  String get imageNotAvailable => 'الصورة غير متاحة';

  @override
  String get certifyDeclaration =>
      'أشهد بموجب هذا أن بياناتي وسجل حالة الخدمة خلال فترة 24 ساعة هذه صحيحة ومضبوطة.';

  @override
  String get notReady => 'غير جاهز';

  @override
  String get agree => 'موافق';

  @override
  String get timeline24h => 'المخطط الزمني 24 ساعة';

  @override
  String get settingsAppliedSuccess => '✅ تم تطبيق الإعدادات بنجاح';

  @override
  String get deviceInformation => 'معلومات الجهاز';

  @override
  String get confirmClearLogs => 'هل تريد مسح جميع السجلات؟';

  @override
  String get trackingStatus => 'حالة التتبع';

  @override
  String get activeStatus => 'نشط';

  @override
  String get stoppedStatus => 'متوقف';

  @override
  String get coordinatesLabel => 'الإحداثيات';

  @override
  String get lastUpdateLabel => 'آخر تحديث';

  @override
  String get locationDisabled => 'الموقع غير مفعل';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get remainingLabel => 'متبقي';

  @override
  String get available => 'المتاح';

  @override
  String get recap => 'الملخص';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get errorCannotChangeStatusWhileMoving =>
      'لا يمكن تغيير الحالة أثناء حركة المركبة.';

  @override
  String get customLocation => 'موقع مخصص';

  @override
  String get notes => 'ملاحظات';

  @override
  String get updateButton => 'تحديث';

  @override
  String get offDuty => 'خارج الخدمة';

  @override
  String get sleeperBerth => 'النوم';

  @override
  String get drivingStatus => 'القيادة';

  @override
  String get onDuty => 'في الخدمة';

  @override
  String get personalUse => 'استخدام شخصي';

  @override
  String get yardMoves => 'تحركات الساحة';

  @override
  String get confirmTitle => 'تأكيد';

  @override
  String get qrScannerTitle => 'مسح رمز QR';

  @override
  String get qrScannerInstructions => 'وجه الكاميرا نحو رمز QR';

  @override
  String get logsTitle => 'السجلات';

  @override
  String get total => 'الإجمالي';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get hoursWorkedToday => 'ساعات العمل اليوم';

  @override
  String get hoursAvailableToday => 'الساعات المتاحة اليوم';

  @override
  String get hoursAvailableTomorrow => 'الساعات المتاحة غداً';

  @override
  String get registerAction => 'إنشاء حساب';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginHere => 'سجل دخولك هنا';

  @override
  String get resetPassword => 'استعادة كلمة المرور';

  @override
  String get email => 'بريد إلكتروني';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get invalidEmailFormat => 'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get sendResetLink => 'إرسال رابط الاستعادة';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get notImplemented => 'هذه الميزة غير متوفرة بعد';

  @override
  String get dvirTitle => 'فحص المركبة (DVIR)';

  @override
  String get inspectionType => 'نوع الفحص';

  @override
  String get vehicleInfo => 'معلومات المركبة';

  @override
  String get mechanicalChecklist => 'قائمة الفحص الميكانيكي';

  @override
  String get additionalNotes => 'ملاحظات إضافية';

  @override
  String get vehicleCondition => 'تقييم حالة المركبة';

  @override
  String get driverSignature => 'توقيع السائق';

  @override
  String get saveReport => 'حفظ التقرير';

  @override
  String get updateReport => 'تحديث التقرير';

  @override
  String get newReport => 'تقرير فحص جديد';

  @override
  String get editReport => 'تعديل التقرير';

  @override
  String get noDvirReports => 'لا توجد تقارير فحص';

  @override
  String get createNewReport => 'إنشاء تقرير جديد';

  @override
  String get reportSavedSuccess => 'تم حفظ تقرير الفحص بنجاح';

  @override
  String get defectsFound => 'أعطال مكتشفة';

  @override
  String get submitted => 'مقدم';

  @override
  String get draft => 'مسودة';

  @override
  String get trailer => 'المقطورة';

  @override
  String get odometerReading => 'عداد المسافات';

  @override
  String get dtcCodes => 'رموز أعطال المحرك (DTC)';

  @override
  String get notesHint => 'أي ملاحظات إضافية عن حالة المركبة...';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get selectVehicle => 'اختيار المركبة';

  @override
  String get searchVehicle => 'بحث عن مركبة...';

  @override
  String get noVehiclesFound => 'لا توجد مركبات متاحة';

  @override
  String get vehicleSelected => 'تم اختيار المركبة';

  @override
  String get unassigned => 'غير مسندة';

  @override
  String get underDevelopment => 'قيد التطوير...';

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';

  @override
  String get miles => 'ميل';

  @override
  String get hour => 'ساعة';

  @override
  String get minute => 'دقيقة';

  @override
  String get newInspectionReport => 'تقرير فحص جديد';

  @override
  String get editInspectionReport => 'تعديل التقرير';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'متوقف';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get deviceInfo => 'معلومات الجهاز';

  @override
  String get account => 'الحساب';

  @override
  String get rules => 'القواعد';

  @override
  String get infoPacket => 'الوثائق';

  @override
  String get odometer => 'وحدة المسافة';

  @override
  String get engineHours => 'ساعات المحرك';

  @override
  String get offlineMode => 'وضع غير متصل';

  @override
  String get dotInspection => 'تفتيش DOT';

  @override
  String get setInspectionPin => 'تعيين رمز التفتيش';

  @override
  String get enter4DigitPin => 'أدخل رمز من 4 أرقام';

  @override
  String get confirmPin => 'تأكيد الرمز';

  @override
  String get enterPinToUnlock => 'أدخل الرمز لفك القفل';

  @override
  String get unlock => 'فك القفل';

  @override
  String get dotInspectionMode => 'وضع تفتيش DOT';

  @override
  String get screenLockedForOfficer => 'الشاشة مقفلة لمراجعة الضابط';

  @override
  String get unlockDriverOnly => 'فك القفل (للسائق فقط)';

  @override
  String get sendLogs => 'إرسال السجلات';

  @override
  String get emailLogs => 'بريد السجلات';

  @override
  String get endInspection => 'إنهاء التفتيش';

  @override
  String get certified => 'معتمد';

  @override
  String get eldReport => 'تقرير ELD';

  @override
  String get hosReport => 'تقرير HOS';

  @override
  String get compliant => 'ممتثل';

  @override
  String get nonCompliant => 'غير ممتثل';

  @override
  String get work => 'العمل';

  @override
  String get rest => 'الراحة';

  @override
  String get break_ => 'الاستراحة';

  @override
  String get distance => 'المسافة';

  @override
  String get malfunctionAlerts => 'تنبيهات الأعطال';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get pdfExportedSuccess => 'تم تصدير PDF بنجاح';

  @override
  String get userManual => 'دليل المستخدم';

  @override
  String get instructions => 'التعليمات';

  @override
  String get malfunctionManual => 'دليل الأعطال';

  @override
  String get viewUserManual => 'عرض دليل المستخدم';

  @override
  String get viewInstructions => 'عرض التعليمات';

  @override
  String get viewMalfunctionManual => 'عرض دليل الأعطال';

  @override
  String get legalNotice =>
      'هذه الوثائق مطلوبة ضمن معايير إدارة الأساطيل المعتمدة. يجب أن تكون متاحة في جميع الأوقات أثناء تشغيل المركبة التجارية.';

  @override
  String get gettingStarted => 'بدء الاستخدام';

  @override
  String get connectingToVehicle => 'الاتصال بالمركبة';

  @override
  String get changingDutyStatus => 'تغيير حالة السائق';

  @override
  String get viewingLogs => 'عرض السجلات والتصديق';

  @override
  String get vehicleInspection => 'فحص المركبة (DVIR)';

  @override
  String get roadsideInspection => 'التفتيش الميداني';

  @override
  String get continueWithout => 'متابعة بدون';

  @override
  String get grant => 'منح';

  @override
  String get time => 'الوقت';

  @override
  String get odom => 'العداد';

  @override
  String get eng => 'المحرك';

  @override
  String get src => 'المصدر';

  @override
  String get noManualModifications =>
      'لم يتم العثور على تعديلات يدوية لهذا التاريخ.';

  @override
  String get failedToLoadAudits => 'فشل تحميل السجلات';

  @override
  String get exportErods => 'تصدير ملف eRODS';

  @override
  String get requiredForFmcsa => 'مطلوب لتفتيش FMCSA';

  @override
  String changeStatusTo(String status) {
    return 'تغيير الحالة إلى $status';
  }

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get noRecordsToday => 'لا توجد سجلات لهذا اليوم';

  @override
  String get trackingNotStarted => 'لم يبدأ التتبع بعد';

  @override
  String get gpsDisabled => 'GPS غير مفعل';

  @override
  String get notConnectedToServer => 'غير متصل بالخادم';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get loadingRecords => 'جاري تحميل السجلات...';

  @override
  String get defectsTitle => 'الأعطال';

  @override
  String get vehicleConditionSatisfactory => 'حالة المركبة مرضية';

  @override
  String auditReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String auditStatusChange(String oldStatus, String newStatus) {
    return '$oldStatus -> $newStatus';
  }

  @override
  String get calculatingLocation => 'جاري حساب الموقع...';

  @override
  String get driveLimitTitle => 'القيادة';

  @override
  String get driveLimitDesc => 'حد 11 ساعة للقيادة';

  @override
  String get shiftLimitTitle => 'الوردية';

  @override
  String get shiftLimitDesc => 'حد 14 ساعة للعمل';

  @override
  String get breakLimitTitle => 'الاستراحة';

  @override
  String get breakLimitDesc => 'استراحة 30 دقيقة';

  @override
  String get cycleLimitTitle => 'الدورة';

  @override
  String get cycleLimitDesc => 'USA 70/8';

  @override
  String get hoursOfService => 'ساعات الخدمة';

  @override
  String get sessionExpired => 'انتهت صلاحية الجلسة';

  @override
  String get invalidConfiguration => 'إعدادات الخادم غير صالحة';

  @override
  String get invalidCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String get sessionMissing => 'الجلسة غير موجودة، يرجى تسجيل الدخول';

  @override
  String get interfaceLanguage => 'لغة الواجهة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get serverUrl => 'عنوان الخادم';

  @override
  String get enterServerUrl => 'أدخل عنوان الخادم.';

  @override
  String get invalidServerUrl =>
      'عنوان غير صالح. مثال: https://server.example.com';

  @override
  String get serverUrlSaved => 'تم حفظ عنوان الخادم.';

  @override
  String get formIncomplete =>
      'البيانات غير مكتملة، يرجى ملء جميع الحقول أولاً.';

  @override
  String get sixteenHourCondition =>
      'لا يمكن تفعيل استثناء 16 ساعة إلا إذا تحققت شروطه.';

  @override
  String get rulesUpdated => 'تم تحديث القواعد.';

  @override
  String get allowed => 'مسموح';

  @override
  String get forbidden => 'ممنوع';

  @override
  String get notProvidedByServer => 'غير متوفرة من الخادم';

  @override
  String get ruleSource => 'مصدر القاعدة';

  @override
  String get cycleRule => 'قاعدة الدورة';

  @override
  String get cargoType => 'نوع الحمولة';

  @override
  String get restartRule => 'إعادة التشغيل';

  @override
  String get restBreakRule => 'الاستراحة';

  @override
  String get sixteenHourException => 'استثناء 16 ساعة';

  @override
  String get dailyLimits => 'الحدود اليومية';

  @override
  String get drivingLimit => 'القيادة';

  @override
  String get shiftWindowLimit => 'نافذة العمل';

  @override
  String get cycleLimit => 'دورة العمل';

  @override
  String get hourAbbr => 'ساعة';

  @override
  String get minAbbr => 'د';

  @override
  String get contactFleetManager => 'تواصل مع مدير الأسطول للمزيد.';

  @override
  String get personalConveyance => 'الاستخدام الشخصي';

  @override
  String get unlimitedTrailers => 'مقطورات غير محدودة';

  @override
  String get unlimitedShippingDocs => 'مستندات شحن غير محدودة';

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String get applicationInfo => 'معلومات التطبيق';

  @override
  String get appNameLabel => 'الاسم';

  @override
  String get appVersionLabel => 'الإصدار';

  @override
  String get appPackageLabel => 'معرّف الحزمة';

  @override
  String get deviceIdLabel => 'معرّف الجهاز';

  @override
  String get diagnosticsAndConnection => 'التشخيص والاتصال';

  @override
  String get centralServer => 'الخادم المركزي';

  @override
  String get locationService => 'خدمة الموقع (GPS)';

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'معطّل';

  @override
  String get hardwareAlerts => 'تنبيهات الجهاز';

  @override
  String get noActiveAlerts => 'لا توجد تنبيهات';

  @override
  String get activeAlerts => 'يوجد تنبيهات';

  @override
  String get technicalInfo => 'المعلومات التقنية';

  @override
  String get eldEngineVersion => 'إصدار محرك ELD';

  @override
  String get hardwareVersion => 'إصدار الجهاز';

  @override
  String get lastDataReceived => 'توقيت آخر بيانات';

  @override
  String get eldConnectionStatus => 'حالة اتصال ELD';

  @override
  String get refresh => 'تحديث';

  @override
  String get supportText =>
      'للدعم الفني يرجى تزويد فريق الدعم بمعرّف الجهاز ورقم الإصدار أعلاه.';

  @override
  String get noVehiclesAssigned => 'لا توجد مركبات معيّنة';

  @override
  String get vehiclesAssignedViaPortal => 'تُعيَّن المركبات عبر البوابة. ';

  @override
  String get viewMyVehicles => 'عرض مركباتي';

  @override
  String get viewAllVehicles => 'عرض كل المركبات';

  @override
  String vehicleSelectedConnect(String name) {
    return 'تم اختيار $name. اتصل بجهاز ELD لتشغيلها. لم تُنقل ساعات الخدمة.';
  }

  @override
  String get inUse => 'قيد الاستخدام';

  @override
  String get viewOnly => 'عرض فقط';

  @override
  String get assignedToYou => 'معيّنة لك';

  @override
  String get errMotionUnknown =>
      'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.';

  @override
  String get errVehicleMoving =>
      'لا يمكن تبديل المركبة وهي تتحرك. لم تُنقل الساعات.';

  @override
  String get errIdentifierMissing =>
      'الخادم لم يُرجع معرف المركبة. لن يُخترع معرف.';

  @override
  String get errThresholdMissing => 'عتبة الحركة غير متوفرة من الإعداد.';

  @override
  String get errUnauthorized => 'غير مصرح لك بتشغيل هذه المركبة.';

  @override
  String get errUnavailable => 'المركبة غير متاحة.';

  @override
  String get errInUse => 'المركبة قيد الاستخدام.';

  @override
  String get errRejected => 'رفض الخادم تشغيل المركبة.';

  @override
  String get errListUnreadable => 'تعذر قراءة قائمة المركبات.';

  @override
  String get nA => 'غير متوفر';

  @override
  String get email1 => 'البريد الإلكتروني';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get mainOfficeAddress => 'المكتب الرئيسي';

  @override
  String get homeTerminalAddress => 'المحطة الرئيسية';

  @override
  String get timeZone => 'المنطقة الزمنية';

  @override
  String get language => 'لغة التطبيق';

  @override
  String get languageUpdatedSuccessfully => 'تم تحديث اللغة بنجاح';

  @override
  String get odometerUnitUpdatedSuccessfull => 'تم تحديث وحدة المسافة بنجاح';

  @override
  String get pleaseContactYourFleetManagerT =>
      'يرجى الاتصال بمدير الأسطول لتغيير معلومات الحساب.';

  @override
  String get thePacketIsIncomplete => 'الحزمة غير مكتملة.';

  @override
  String get inspectionMode => 'وضع التفتيش';

  @override
  String get dataTransferInstructionSheet => 'ورقة تعليمات نقل البيانات';

  @override
  String get malfunctionManual39534 => 'دليل الأعطال (395.34)';

  @override
  String get goldenFeatherEldInspectionMode =>
      'وضع التفتيش لـ Golden Feather ELD';

  @override
  String get tapDotInspectionInTheMenuPress =>
      'اضغط \"وضع التفتيش\" في القائمة واضغط \"بدء التفتيش\". دع الضابط يعرض السجلات من جهازك. اعرض بطاقة التعليمات هذه إذا طلب.';

  @override
  String get anInspectorMayPressArrowsToVie =>
      'يمكن للمفتش الضغط على الأسهم لعرض السجلات السابقة أو التالية.';

  @override
  String get theOfficerCannotLeaveInspectio =>
      'لا يخرج المفتش من وضع التفتيش. يخرج السائق بزر خروج السائق بعد إدخال كلمة مرور حسابه.';

  @override
  String get goldenFeatherEldIsCapableOfPro =>
      'جهاز Golden Feather ELD قادر على إنتاج ونقل سجلات ELD عبر طرق النقل التليماتية: الويب اللاسلكي والبريد الإلكتروني. لإرسال السجلات عبر الويب، اضغط زر \"DOT Inspection\" ثم \"Send Logs\". لإرسالها عبر البريد، اختر \"Email Logs\" وأدخل البريد.';

  @override
  String get goldenFeatherEldMalfunctionMan =>
      'دليل الأعطال لـ Golden Feather ELD';

  @override
  String get inAccordanceWithTheGuidelinesS =>
      'وفقاً للإرشادات المحددة في 395.34';

  @override
  String get malfunctionIndication => 'مؤشر العطل';

  @override
  String get immediatelyContactTheSupportIf =>
      'اتصل بالدعم فوراً إذا انطفأ ضوء LED عند التوصيل بالمركبة أو إذا أبلغ التطبيق عن عطل.';

  @override
  String get noteTheMalfunction => 'تسجيل العطل';

  @override
  String get noteTheMalfunctionAndProvideAW =>
      'سجل العطل وقدم إشعاراً خطياً لشركتك خلال 24 ساعة.';

  @override
  String get switchToPaperLogs => 'التبديل للسجلات الورقية';

  @override
  String get k8DaysRule => 'قاعدة 8 أيام';

  @override
  String get contactTheSupportTeamAtTopceld =>
      'تواصل مع الدعم عبر topceld@gmail.com';

  @override
  String get eldUserManual => 'دليل المستخدم';

  @override
  String get features => 'الميزات';

  @override
  String get installationAndSetup => 'التثبيت والإعداد';

  @override
  String get logManagement => 'إدارة السجلات';

  @override
  String get roadsideInspections => 'تفتيش الطريق';

  @override
  String get electronicDriverVehicleInspect => 'تقارير فحص المركبة (DVIR)';

  @override
  String get fleetManagerPortal => 'بوابة مدير الأسطول';

  @override
  String get electronicLoggingDeviceEld => 'جهاز التسجيل الإلكتروني (ELD)';

  @override
  String get recordsOfNdutyStatus => 'سجلات حالة الخدمة';

  @override
  String get easilyManageYourDutyStatusChan =>
      'إدارة الحالات بسهولة مع إمكانية عرض، وتعديل، وتوقيع السجلات بدقة.';

  @override
  String get availableHoursAndNrequiredBrea =>
      'الساعات المتاحة\\nوالفترات المطلوبة';

  @override
  String get stayInformedAboutYourAvailable =>
      'ابقَ على اطلاع بساعات القيادة المتاحة وفترات الراحة الإلزامية لضمان الامتثال.';

  @override
  String get interAndIntrastateNhosRules => 'قواعد HOS';

  @override
  String get ourAppSupportsBothInterAndIntr =>
      'يدعم تطبيقنا قواعد القيادة بين الولايات وداخلها.';

  @override
  String get roadsideInspectionNfunction => 'تفتيش الطريق';

  @override
  String get duringRoadsideInspectionsUseTh =>
      'أثناء التفتيش الأمني، استخدم وضع التفتيش في التطبيق لمشاركة السجلات.';

  @override
  String get vehicleInspectionNreports => 'تقارير فحص المركبة';

  @override
  String get generatePreOrPostTripDvirsWith =>
      'أنشئ تقارير DVIR قبل أو بعد الرحلة لإشعار الميكانيكيين بأي أعطال فوراً.';

  @override
  String get onlineFleetNmanagerPortal => 'بوابة مدير الأسطول';

  @override
  String get accessTheFleetManagerPortalToM =>
      'الوصول لبوابة المدير لمراقبة الامتثال وعرض البيانات في الوقت الفعلي.';

  @override
  String get gpsTracking => 'تتبع GPS';

  @override
  String get trackYourVehicle =>
      'تتبع موقع مركبتك في الوقت الفعلي لتحسين الإدارة والأمان.';

  @override
  String get iftaCalculations => 'حسابات IFTA';

  @override
  String get automaticallyCalculateIftaData =>
      'حساب بيانات IFTA آلياً لتبسيط تقارير ضرائب الوقود.';

  @override
  String get setUpFleetNmanagerPortal => 'إعداد البوابة';

  @override
  String get useYourCredentialsToSignIntoTh =>
      'استخدم بيانات الدخول للوصول إلى البوابة وتوفير معلومات شركتك والسائقين.';

  @override
  String get monitorHosAndNfmcsaCompliance => 'مراقبة الامتثال';

  @override
  String get stayOnTopOfDrivers =>
      'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.';

  @override
  String get preconfiguredStatuses => 'حالات مسبقة الإعداد';

  @override
  String get customizeDutyStatusesAccessByS =>
      'تخصيص الوصول للحالات عبر تفعيل تحرك الساحة والاستخدام الشخصي كخيارات متاحة.';

  @override
  String get driverAndVehicleInformation => 'معلومات السائق والمركبة';

  @override
  String get trackYourDrivers =>
      'تتبع موقع السائقين الحالي أو الأخير، المركبة، ومعلومات الاتصال بسهولة.';

  @override
  String get downloadAndTransferLogs => 'تحميل ونقل السجلات';

  @override
  String get downloadAnyDrivers =>
      'حمل أي سجل للسائقين بصيغة PDF بنقرات قليلة. في حال التفتيش يمكن إرسالها بسهولة للضابط.';

  @override
  String get filterLogs => 'تصفية السجلات';

  @override
  String get saveTimeByQuicklyFindingLogsBy =>
      'وفر الوقت بإيجاد السجلات بسرعة حسب التاريخ، السائق، أو المركبة باستخدام خيار التصفية.';

  @override
  String get installEldHardware => 'تثبيت الجهاز';

  @override
  String get beginByLocatingTheEcmDiagnosti =>
      'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:\\n\\n• وصلة 6-pin\\n• وصلة 9-pin\\n• وصلة OBDII\\n\\nبمجرد تحديد الوصلة، ركب الجهاز وثبته بإحكام.';

  @override
  String get installEldSoftware => 'تثبيت البرنامج';

  @override
  String get beforeYouStartUsingTheEldEnsur =>
      'تأكد من أن جهازك متصل بالإنترنت والبلوتوث مفعل.\\n\\n• قم بتثبيت التطبيق.\\n• سجل الدخول ببياناتك.\\n• زامن الجهاز من خلال اختيار مركبتك من القائمة.';

  @override
  String get hoursOfService1 => 'ساعات الخدمة';

  @override
  String get onceTheEldIsSetUpItAutomatical =>
      'بمجرد الإعداد، يسجل الجهاز وقت القيادة آلياً، ويحسب الساعات المتاحة وفترات الراحة.';

  @override
  String get accessingLogs => 'الوصول للسجلات';

  @override
  String get logInToTheEldAppWithYourUnique =>
      'سجل الدخول وانتقل لقسم \"السجلات\" للوصول للبيانات.';

  @override
  String get viewingLogs1 => 'عرض السجلات';

  @override
  String get viewDetailedRodsForDifferentDa =>
      'شاهد التفاصيل اليومية لكل تغيير حالة يتضمن الوقت والمدة والمكان.';

  @override
  String get editingLogs => 'تعديل السجلات';

  @override
  String get editDutyStatusEntriesExceptFor =>
      'عدّل الإدخالات (باستثناء وقت القيادة الآلي). اضغط على التاريخ وعدل واحفظ.';

  @override
  String get certifyingLogs => 'توقيع السجلات';

  @override
  String get certifyingLogsEndYourShiftByDi =>
      'أنهِ ورديتك بتوقيع سجلاتك رقمياً للتأكيد على دقتها والامتثال بضغطة زر.';

  @override
  String get duringARoadsideInspectionFollo =>
      'أثناء التفتيش الأمني، اتبع الخطوات:\\n\\n• ادخل لوضع تفتيش DOT من القائمة الرئيسية.\\n• اضغط \"بدء التفتيش\" لعرض سجلات (RODS) للضابط.\\n• استخدم أسهم التنقل لمراجعة السجلات حسب التاريخ.\\n• إذا طلب منك، أرسل السجلات عبر الويب أو البريد.\\n• بعد الانتهاء، اضغط \"رجوع\" للعودة.';

  @override
  String get hosComplianceAlerts => 'تنبيهات الامتثال';

  @override
  String get stayCompliantWithHosRegulation =>
      'ابقَ ممتثلاً لمراقبة التنبيهات:\\n\\n• على شاشة السجلات الرئيسية، راقب الأيقونة الحمراء التي تشير لمخالفة HOS أو تحذير النموذج.\\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل عبر الضغط عليها.';

  @override
  String get createDvir => 'إنشاء فحص';

  @override
  String get createANewInspectionReportNNAc =>
      'إنشاء تقرير فحص جديد:\\n\\n• افتح القائمة واختر DVIR.\\n• اضغط على علامة الزائد لبدء فحص جديد.\\n• راجع المكونات وحدد أي أعطال.\\n• أضف ملاحظات إذا لزم الأمر.\\n• اضغط توقيع للحفظ في السجل.';

  @override
  String get editDvir => 'تعديل الفحص';

  @override
  String get editAnExistingReportNNGoToDvir =>
      'تعديل تقرير سابق:\\n\\n• اذهب للسجل واختر التقرير.\\n• اضغط زر التعديل لإجراء التغييرات.';

  @override
  String get deleteDvir => 'حذف الفحص';

  @override
  String get deleteAnExistingReportNNInDvir =>
      'حذف تقرير سابق:\\n\\n• اذهب للسجل واختر التقرير.\\n• اضغط زر الحذف وتأكد.';

  @override
  String get infoPacketManualBlurb =>
      'يجوز أن يكون دليل المستخدم وورقة التعليمات وورقة تعليمات الأعطال بصيغة إلكترونية، وفق السجل الفيدرالي بعنوان \"إرشاد تنظيمي بشأن التوقيعات والمستندات الإلكترونية\" (76 FR 411).';

  @override
  String get infoPacketInstructionsBlurb =>
      'بالإضافة إلى ما سبق، يجب أن تكون في المركبة التجارية نماذج فارغة لسجلات حالة الخدمة (RODS) تكفي لتسجيل حالة السائق والمعلومات ذات الصلة لمدة لا تقل عن 8 أيام.';

  @override
  String packetIncompleteMissing(String missing) {
    return 'الحزمة غير مكتملة: $missing';
  }

  @override
  String get recordsOfDutyStatus => 'سجلات حالة الخدمة';

  @override
  String get availableHoursAndRequiredBreaks =>
      'الساعات المتاحة\nوالفترات المطلوبة';

  @override
  String get interAndIntrastateHosRules => 'قواعد HOS';

  @override
  String get roadsideInspectionFunction => 'تفتيش الطريق';

  @override
  String get vehicleInspectionReports => 'تقارير فحص المركبة';

  @override
  String get onlineFleetManagerPortal => 'بوابة مدير الأسطول';

  @override
  String get trackYourVehicleSLocationIn =>
      'تتبع موقع مركبتك في الوقت الفعلي لتحسين الإدارة والأمان.';

  @override
  String get setUpFleetManagerPortal => 'إعداد البوابة';

  @override
  String get monitorHosAndFmcsaCompliance => 'مراقبة الامتثال';

  @override
  String get stayOnTopOfDriversDuty =>
      'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.';

  @override
  String get trackYourDriversCurrentOrLast =>
      'تتبع موقع السائقين الحالي أو الأخير، المركبة، ومعلومات الاتصال بسهولة.';

  @override
  String get downloadAnyDriversLogsInPdf =>
      'حمل أي سجل للسائقين بصيغة PDF بنقرات قليلة. في حال التفتيش يمكن إرسالها بسهولة للضابط.';

  @override
  String get beginByLocatingTheEcmDiagnostic =>
      'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:\n\n• وصلة 6-pin\n• وصلة 9-pin\n• وصلة OBDII\n\nبمجرد تحديد الوصلة، ركب الجهاز وثبته بإحكام.';

  @override
  String get beforeYouStartUsingTheEld =>
      'تأكد من أن جهازك متصل بالإنترنت والبلوتوث مفعل.\n\n• قم بتثبيت التطبيق.\n• سجل الدخول ببياناتك.\n• زامن الجهاز من خلال اختيار مركبتك من القائمة.';

  @override
  String get onceTheEldIsSetUp =>
      'بمجرد الإعداد، يسجل الجهاز وقت القيادة آلياً، ويحسب الساعات المتاحة وفترات الراحة.';

  @override
  String get duringARoadsideInspectionFollowThese =>
      'أثناء التفتيش الأمني، اتبع الخطوات:\n\n• ادخل لوضع تفتيش DOT من القائمة الرئيسية.\n• اضغط \"بدء التفتيش\" لعرض سجلات (RODS) للضابط.\n• استخدم أسهم التنقل لمراجعة السجلات حسب التاريخ.\n• إذا طلب منك، أرسل السجلات عبر الويب أو البريد.\n• بعد الانتهاء، اضغط \"رجوع\" للعودة.';

  @override
  String get stayCompliantWithHosRegulationsBy =>
      'ابقَ ممتثلاً لمراقبة التنبيهات:\n\n• على شاشة السجلات الرئيسية، راقب الأيقونة الحمراء التي تشير لمخالفة HOS أو تحذير النموذج.\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل عبر الضغط عليها.';

  @override
  String get createANewInspectionReportAccess =>
      'إنشاء تقرير فحص جديد:\n\n• افتح القائمة واختر DVIR.\n• اضغط على علامة الزائد لبدء فحص جديد.\n• راجع المكونات وحدد أي أعطال.\n• أضف ملاحظات إذا لزم الأمر.\n• اضغط توقيع للحفظ في السجل.';

  @override
  String get editAnExistingReportGoTo =>
      'تعديل تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر التعديل لإجراء التغييرات.';

  @override
  String get deleteAnExistingReportInDvir =>
      'حذف تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر الحذف وتأكد.';

  @override
  String get pleaseContactYourFleetManagerTo =>
      'يرجى الاتصال بمدير الأسطول لتغيير معلومات الحساب.';

  @override
  String todayLogDate(Object date) {
    return 'اليوم - $date';
  }

  @override
  String get enterTheTrailerNumber => 'أدخل رقم المقطورة.';

  @override
  String get trailerNumberMustBeLettersNumbers =>
      'رقم المقطورة: أحرف وأرقام وشرطات فقط (حتى 50).';

  @override
  String get enterTheDocumentNumber => 'أدخل رقم المستند.';

  @override
  String get shippingDocumentNumberIsTooLong =>
      'رقم مستند الشحن طويل جداً (حتى 100).';

  @override
  String get enterOneDocumentAtATime =>
      'أدخل مستنداً واحداً في كل مرة (بدون فاصلة).';

  @override
  String get reasonForChange => 'سبب التعديل';

  @override
  String get enterReasonRequired => 'أدخل السبب (مطلوب)';

  @override
  String get aReasonForTheChangeIs => 'سبب التعديل مطلوب.';

  @override
  String get cannotSaveDriverSessionNotFound =>
      'جلسة السائق غير موجودة. لا يمكن الحفظ.';

  @override
  String get automaticDrivingTimeCannotBeShortened =>
      'لا يمكن تقصير أو حذف وقت القيادة الآلي.';

  @override
  String get eventSavedSuccessfully => 'تم حفظ الحدث بنجاح';

  @override
  String get reCertificationRequiredEditsWereMade =>
      'يلزم إعادة الاعتماد: حدثت تعديلات بعد آخر توقيع.';

  @override
  String get typeHere => 'اكتب هنا';

  @override
  String get noDocumentsAdded => 'لا توجد مستندات';

  @override
  String get delete => 'حذف';

  @override
  String get carrierProposedEdits39530Are =>
      'تعديلات الناقل المقترحة (§395.30) تُراجَع داخل كل سجل في تبويب Certify (قبول / رفض).';

  @override
  String get unidentifiedDrivingIsReviewedInUnidentified =>
      'القيادة غير المحددة تُراجَع في شاشة الأحداث غير المحددة.';

  @override
  String get noTrailersAdded => 'لا توجد مقطورات';

  @override
  String get noVehicleIsSelected => 'لا توجد مركبة محددة.';

  @override
  String get anAnnotationIsRequired => 'التعليق مطلوب.';

  @override
  String get yourRecordWasUpdatedReviewThe =>
      'تم تحديث سجلك. راجع السجل اليومي؛ قد يلزم إعادة التصديق.';

  @override
  String get assume => 'افتراض';

  @override
  String get requiredAnnotationThisTimeIsAssumed =>
      'التعليق مطلوب. تُحتسب هذه المدة قيادة.';

  @override
  String get notMine => 'ليست لي';

  @override
  String get requiredRejectionReason => 'سبب الرفض مطلوب';

  @override
  String get overdue => 'متأخر';

  @override
  String get originalRecordPreserved => 'النسخة الأصلية محفوظة';

  @override
  String get byDate => 'حسب التاريخ…';

  @override
  String get currentVehicleOnly => 'المركبة الحالية فقط';

  @override
  String get clearFilters => 'مسح التصفية';

  @override
  String get currentVehicle => 'المركبة الحالية';

  @override
  String get responseWasInterrupted => 'انقطعت العملية. أعد المحاولة.';

  @override
  String get pleaseDrawASignatureFirst => 'ارسم التوقيع أولاً.';

  @override
  String get logSuccessfullyCertified => 'تم اعتماد السجل.';

  @override
  String get notReadyForCertification => 'غير جاهز للاعتماد';

  @override
  String get pleaseResolveTheFollowingIssuesBefore =>
      'عالج النواقص التالية قبل اعتماد السجل:';

  @override
  String get carrierEditsMustBeAcceptedOr =>
      'تعديلات الناقل بانتظار ردك قبل الاعتماد.';

  @override
  String get carrierEditAcceptedReCertifyThe =>
      'تم قبول تعديل الناقل. أعد التصديق.';

  @override
  String get carrierEditRejected => 'تم رفض تعديل الناقل.';

  @override
  String get sessionMissingPleaseLogInAgain =>
      'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get carrierProposedEdit => 'تعديل من الناقل';

  @override
  String get reject => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get selectAVehicleBeforeSavingThe =>
      'يرجى اختيار المركبة قبل حفظ النموذج.';

  @override
  String get coDriverMustBeAServer =>
      'يجب أن يكون السائق المساعد صالحاً قبل الحفظ.';

  @override
  String get keepAPaperLogForThatDayAndUnti =>
      'احتفظ بسجل ورقي لذلك اليوم وحتى يتم إصلاح الجهاز. في حال التفتيش، اعرض الأيام السبعة السابقة من التطبيق.';

  @override
  String get inTheEventOfAnEldMalfunctionTh =>
      'في حال عطل ELD، يجب على الشركة اتخاذ إجراءات لإصلاح العطل خلال 8 أيام من اكتشافه.';

  @override
  String get anInspectorMayViewTheLogFormTh =>
      'يمكن للمفتش عرض نموذج السجل، المخطط الشبكي، والأحداث مع الملاحظات.';

  @override
  String get theEventCouldNotBeSaved => 'تعذر حفظ الحدث.';

  @override
  String get theEventWasSavedButThe => 'حُفظ الحدث لكن تعذر تسجيل سبب التعديل.';

  @override
  String get transferAuditTitle => 'سجل نقل السجلات';

  @override
  String get noTransfersFromServer => 'لا توجد عمليات نقل في رد الخادم.';

  @override
  String transferAuditNotLoaded(Object error) {
    return 'تعذر قراءة سجل النقل: $error';
  }

  @override
  String get driving24h => 'قيادة 24 ساعة';

  @override
  String pendingDays(Object days) {
    return 'معلّق $days يوم';
  }

  @override
  String get enterTrailerNumber => 'أدخل رقم المقطورة.';

  @override
  String get trailerNumberFormatError =>
      'رقم المقطورة: أحرف وأرقام وشرطات فقط (حتى 50).';

  @override
  String get enterDocumentNumber => 'أدخل رقم المستند.';

  @override
  String get documentNumberTooLong => 'رقم مستند الشحن طويل جداً (حتى 100).';

  @override
  String get oneDocumentAtATime =>
      'أدخل مستنداً واحداً في كل مرة (بدون فاصلة).';

  @override
  String get selectVehicleBeforeSavingForm =>
      'يرجى اختيار المركبة قبل حفظ النموذج.';

  @override
  String get coDriverMustBeServerId =>
      'يجب أن يكون السائق المساعد صالحاً قبل الحفظ.';

  @override
  String get serverSavedFormIncomplete => 'حفظ الخادم النموذج وتركه غير مكتمل.';

  @override
  String get serverSavedFormNoStatus =>
      'حفظ الخادم النموذج ولم يُرجع حالة الاكتمال.';

  @override
  String get responseInterrupted => 'انقطعت العملية. أعد المحاولة.';

  @override
  String get drawSignatureFirst => 'ارسم التوقيع أولاً.';

  @override
  String get drawYourSignatureHere => 'ارسم توقيعك هنا';

  @override
  String get certifyLegalStatement =>
      'أشهد بموجب هذا أن إدخالات بياناتي وسجل حالة الواجب الخاص بي لمدة 24 ساعة صحيحة ودقيقة.';

  @override
  String get errNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.';

  @override
  String get errRequestFailed => 'تعذر إكمال الطلب. أعد المحاولة.';

  @override
  String get errRequestFailedNetwork =>
      'تعذر إكمال الطلب. تحقق من الشبكة ثم أعد المحاولة.';

  @override
  String get errCannotReachServer =>
      'تعذر الاتصال بالخادم. تحقق من الشبكة ثم أعد المحاولة.';

  @override
  String get errServerRejected => 'الخادم رفض الطلب.';

  @override
  String get errSessionExpiredAction => 'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get errPermissionDenied => 'ليست لديك صلاحية لهذا الإجراء.';

  @override
  String get errNotFound => 'العنصر غير موجود على الخادم.';

  @override
  String get errServerError => 'حدث خطأ في الخادم. أعد المحاولة.';

  @override
  String get errGeneric => 'تعذر إكمال الطلب.';

  @override
  String get enterAReasonForManualRecording => 'اكتب سبب التسجيل اليدوي.';

  @override
  String get couldNotUpdateManualRecordingM =>
      'تعذر تحديث وضع التسجيل اليدوي. أعد المحاولة.';

  @override
  String get unableToConnectToEld => 'تعذر الاتصال بجهاز ELD.';

  @override
  String get checkBluetoothAndRetry =>
      'تحقق من تشغيل الجهاز والبلوتوث ثم أعد المحاولة.';

  @override
  String get checkNetworkAndRetry => 'تحقق من الشبكة والجهاز ثم أعد المحاولة.';

  @override
  String get driverSessionMissingSignIn =>
      'جلسة السائق غير موجودة. سجّل الدخول قبل التفتيش.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingTitle1 => 'ساعاتك تُسجَّل تلقائياً';

  @override
  String get onboardingBody1 =>
      'يتتبع جهاز ELD حالة قيادتك مقابل حدود FMCSA لحظة تحرك المركبة — بلا أوراق وبلا تخمين.';

  @override
  String get onboardingTitle2 => 'افحص مركبتك بثقة';

  @override
  String get onboardingBody2 =>
      'فحص يومي قبل وبعد الرحلة، تتبع العيوب مع شهادات الإصلاح، ومراجعة §396.13 — كل ذلك في مكان واحد.';

  @override
  String get onboardingTitle3 => 'جاهز للمفتش دائماً';

  @override
  String get onboardingBody3 =>
      'سجلاتك وحزمتك القانونية وخيارات النقل على متن الجهاز — حتى بلا إنترنت على الطريق.';

  @override
  String startedOnDate(Object date) {
    return 'بدأ: $date';
  }

  @override
  String get tableTimeEt => 'الوقت ET';

  @override
  String certEventStatus(Object status) {
    return 'اعتماد · $status';
  }

  @override
  String eventCodeNote(Object code) {
    return 'الرمز: $code';
  }

  @override
  String originNote(Object origin) {
    return 'المصدر: $origin';
  }

  @override
  String notesNote(Object notes) {
    return 'ملاحظات: $notes';
  }

  @override
  String get inspectionCommentErrorLength =>
      'يجب أن يكون التعليق بين 4 و60 حرفاً.';

  @override
  String get enterValidEmail => 'أدخل بريداً صالحاً.';

  @override
  String get transferAccepted => 'قبل الخادم طلب النقل.';

  @override
  String get sendLogsViaEmail => 'إرسال السجلات عبر البريد';

  @override
  String get send8Logs => 'إرسال 8 سجلات';

  @override
  String get recipientEmail => 'بريد المستلم';

  @override
  String get comment => 'تعليق';

  @override
  String get dataTransferType => 'نوع نقل البيانات';

  @override
  String get sendAction => 'إرسال';

  @override
  String get inspectLogs24 =>
      'افحص سجلات فترة 24 ساعة والأيام السابقة لدورة واحدة';

  @override
  String get setPinGuidance => 'اختر «بدء التفتيش» وسلّم الجهاز للضابط';

  @override
  String get eldCertifies =>
      'يشهد التطبيق أن استخدامه مع الجهاز يستوفي متطلبات ELD في 49 CFR part 395 Subpart B.';

  @override
  String get notAllowedByServer => 'غير متاح لهذا الحساب حسب الخادم.';

  @override
  String get startInspectionUpper => 'بدء التفتيش';

  @override
  String get serverDoesNotAllow => 'الخادم لا يسمح ببدء التفتيش الآن.';

  @override
  String get sendLogsFor24 =>
      'أرسل السجلات لفترة 24 ساعة والأيام السابقة لدورة واحدة';

  @override
  String get sendLogsToOfficer => 'أرسل سجلاتك للضابط إذا طلب ذلك';

  @override
  String get sendLogsUpper => 'إرسال السجلات';

  @override
  String get emailLogs24Pdf =>
      'أرسل السجلات بالبريد لفترة 24 ساعة والأيام السابقة كملف PDF';

  @override
  String get emailLogsPdf => 'أرسل سجلاتك بصيغة PDF';

  @override
  String get emailLogsUpper => 'بريد السجلات';

  @override
  String get infoPacketUpper => 'حزمة المعلومات';

  @override
  String get inspectionPinTitle => 'رمز التفتيش';

  @override
  String get enter4Digits => 'الرمز يجب أن يكون 4 أرقام.';

  @override
  String get pinsDoNotMatch => 'الرمزان غير متطابقين.';

  @override
  String get pinLabel => 'الرمز';

  @override
  String get confirmPinLabel => 'تأكيد الرمز';

  @override
  String get cancelAction => 'إلغاء';

  @override
  String get enterInspectionPin => 'أدخل رمز التفتيش.';

  @override
  String get incorrectPin => 'الرمز غير صحيح.';

  @override
  String get driverExit => 'خروج السائق';

  @override
  String get exitAction => 'خروج';

  @override
  String get enterNewPinOfficer =>
      'أدخل رمز التفتيش الجديد الذي سيتم إعطاؤه للضابط';

  @override
  String get enterSamePinToExit => 'أدخل الرمز نفسه للخروج من وضع التفتيش';

  @override
  String get setPinGuidanceDialog =>
      'عيّن رمزاً من 4 أرقام لقفل الشاشة. المفتش يرى السجلات فقط ولا يخرج إلا بكلمة مرور السائق.';

  @override
  String get enterPinToExitGuidance =>
      'أدخل رمز التفتيش الذي عيّنته عند البدء. المفتش لا يخرج من هنا.';

  @override
  String get menuTitle => 'القائمة';

  @override
  String get vehicleInMotionTitle => 'المركبة في حالة حركة';

  @override
  String get vehicleInMotionDesc =>
      'التزاماً بقواعد السلامة المرورية ولوائح FMCSA، يتم حظر استخدام التطبيق أثناء القيادة. ستتم استعادة الواجهة فور توقف المركبة.';

  @override
  String get weakConnectionDelayedData =>
      'الاتصال ضعيف. قد تتأخر بعض البيانات.';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get connectionStatusUnknown => 'حالة الاتصال غير معروفة.';

  @override
  String driveLimitFormat(String drive) {
    return 'حد القيادة $drive ساعة';
  }

  @override
  String shiftLimitFormat(String shift) {
    return 'حد الخدمة $shift ساعة';
  }

  @override
  String breakLimitFormat(String rest) {
    return 'استراحة $rest دقيقة';
  }

  @override
  String usedFormat(String description) {
    return '$description · مستخدم';
  }

  @override
  String get noticeTitle => 'تنبيه';

  @override
  String get gpsTurnedOff => 'نظام تحديد المواقع مغلق.';

  @override
  String get serverReportsEldAlert =>
      'الخادم يبلّغ عن تنبيه تشغيلي في جهاز ELD. افتح شاشة الاتصال للتفاصيل.';

  @override
  String get operationalAlertTooltip => 'تنبيه تشغيلي';

  @override
  String get noInternetBanner =>
      'لا يوجد إنترنت. يمكنك المتابعة وعرض البيانات المحفوظة.';

  @override
  String get dvirSatisfactory => 'حالة المركبة مرضية';

  @override
  String get dvirHasDefects => 'توجد عيوب';

  @override
  String get dvirDefectsCorrected => 'تم إصلاح العيوب';

  @override
  String get dvirDefectsNotCorrected => 'العيوب لا تستوجب الإصلاح';

  @override
  String get dvirDefectRecorded => '— يوجد عيب مسجّل';

  @override
  String get dvirNoRepairCert => 'لا يوجد تصديق إصلاح بعد';

  @override
  String get dvirSetByCarrier => 'يحدّدها الناقل لا السائق';

  @override
  String get dvirTimeUnavailable => 'وقت الفحص غير متاح. اتصل ثم أعد المحاولة.';

  @override
  String get dvirSavedCannotEdit => 'لا يمكن تعديل تقرير محفوظ من هذا الجهاز.';

  @override
  String get dvirSignatureRequired => 'التوقيع مطلوب.';

  @override
  String get dvirDriverSessionMissing =>
      'جلسة السائق مفقودة. سجّل الدخول مجدداً قبل التوقيع.';

  @override
  String get dvirVehicleIdMissing =>
      'معرّف المركبة مفقود. اختر مركبة قبل التوقيع.';

  @override
  String get dvirPrevNoServerId =>
      'التقرير السابق بلا معرّف خادم ولا يمكن مراجعته.';

  @override
  String get dvirPreviousInspection => 'الفحص السابق';

  @override
  String get dvirReviewBeforeDriving =>
      'راجع التقرير السابق ووقّع عليه قبل القيادة.';

  @override
  String get dvirRecordedDefects => 'العيوب المسجّلة:';

  @override
  String get dvirNone => 'لا توجد عيوب.';

  @override
  String get dvirRepairStatus => 'حالة الإصلاح: ';

  @override
  String get dvirReviewed => 'تمت المراجعة';

  @override
  String get dvirLocationUnavailable => 'الموقع غير متاح';

  @override
  String get dvirCompanyUnavailable => 'الشركة غير متاحة';

  @override
  String get dvirTimeUnavailableShort => 'الوقت غير متاح';

  @override
  String get dvirInsertDvir => 'إدراج تقرير فحص (DVIR)';

  @override
  String get dvirPreviousReviewNotice =>
      'مراجعة التقرير السابق — فتح التقرير لا يعد مراجعة له.';

  @override
  String get dvirTimeET => 'الوقت';

  @override
  String get dvirOdometerMi => 'المسافة';

  @override
  String get dvirOdometerHint => 'المسافة';

  @override
  String get company => 'الشركة';

  @override
  String get remarks => 'ملاحظات';

  @override
  String get dvirImageNotAvailable => 'الصورة غير متاحة';

  @override
  String get dvirClearSignature => 'مسح التوقيع';

  @override
  String get dvirSigned => 'تم التوقيع';

  @override
  String get dvirSign => 'توقيع';

  @override
  String get removeAction => 'إزالة';

  @override
  String get addDefects => 'إضافة عيوب';

  @override
  String get dvirDefects396_11 => 'العيوب (§396.11)';

  @override
  String get dvirLoadDefectsFail => 'تعذر تحميل قائمة العيوب من الخادم.';

  @override
  String get retryAction => 'إعادة المحاولة';

  @override
  String get dvirCatalogEmpty => 'القائمة فارغة.';

  @override
  String get dvirSafetyAffecting => 'يؤثر على السلامة';

  @override
  String get dvirDescriptionOptional => 'وصف (اختياري)';

  @override
  String get eldDiagnosticReading => 'جارٍ قراءة حالة الاتصال...';

  @override
  String eldDiagnosticDiagnosticFormat(String diagnostics) {
    return 'تشخيص: $diagnostics';
  }

  @override
  String eldDiagnosticMalfunctionFormat(String malfunctions) {
    return 'عطل: $malfunctions';
  }

  @override
  String eldDiagnosticLastValidDataFormat(String lastHeartbeat) {
    return 'آخر بيانات صالحة: $lastHeartbeat';
  }

  @override
  String eldDiagnosticDataAgeFormat(String dataAgeSeconds) {
    return 'عمر البيانات: $dataAgeSeconds ثانية';
  }

  @override
  String get eldDiagnosticNotReady => 'غير جاهز للتشغيل الطبيعي.';

  @override
  String get eldDiagnosticDataNotReliable => 'البيانات غير موثوقة.';

  @override
  String get eldDiagnosticConnected => 'متصل';

  @override
  String get eldDiagnosticDisconnected => 'غير متصل';

  @override
  String get eldDiagnosticUnavailable => 'غير متاح';

  @override
  String get eldDiagnosticMalfunction => 'عطل';

  @override
  String get eldDiagnosticNoConnectionStatus => 'الخادم لم يُرجع حالة اتصال.';

  @override
  String get eldReadinessTitle => 'جاهزية ما قبل التشغيل';

  @override
  String get eldReadinessChecking => 'جارٍ فحص الجاهزية...';

  @override
  String get eldReadinessReady => 'جاهز للتشغيل';

  @override
  String get eldReadinessNotReady => 'غير جاهز للتشغيل';

  @override
  String eldReadinessRecommendedActionFormat(String action) {
    return 'الإجراء المقترح: $action';
  }

  @override
  String get eldReadinessDevicePaired => 'الجهاز مقترن';

  @override
  String get eldReadinessConnectionActive => 'الاتصال نشط';

  @override
  String get eldReadinessMotionData => 'بيانات الحركة';

  @override
  String get eldReadinessLocationData => 'بيانات الموقع';

  @override
  String get eldReadinessEngineTelemetry => 'بيانات المحرك (ECM)';

  @override
  String get eldMalfunctionTitle => 'في حال العطل (§395.34)';

  @override
  String get eldMalfunctionStep1 =>
      'دوّن العطل وأبلغ الناقل كتابياً خلال 24 ساعة.';

  @override
  String get eldMalfunctionStep2 =>
      'أعد بناء سجل 24 ساعة الحالية والأيام السبعة السابقة على الورق إن لم تكن متاحة من الجهاز.';

  @override
  String get eldMalfunctionStep3 => 'استمر بالتسجيل الورقي حتى إصلاح الجهاز.';

  @override
  String get notifyCarrier => 'إخطار الناقل';

  @override
  String get requestExtension => 'طلب تمديد';

  @override
  String get simulateMalfunction => 'محاكاة عطل';

  @override
  String get simulateMalfunctionDebug => 'محاكاة عطل (تصحيح)';

  @override
  String get simulatedMalfunctionRecorded => 'تم تسجيل عطل محاكى (تصحيح فقط)';

  @override
  String get inspectionLogsTitle => 'سجلات التفتيش';

  @override
  String get dvirActiveDefectsTitle => 'العيوب النشطة لمركبتك';

  @override
  String get dvirDefectDetailsTitle => 'تفاصيل العيب';

  @override
  String get dvirDefectSeverity => 'الخطورة';

  @override
  String get dvirDefectStage => 'المرحلة';

  @override
  String get dvirDefectOutOfService => 'المركبة متوقفة عن الخدمة';

  @override
  String get dvirDefectRepairs => 'سجل الإصلاحات';

  @override
  String get dvirDefectNoRepairs => 'لا إصلاحات مسجلة بعد';

  @override
  String get dvirDefectCertifications => 'اعتمادات الناقل';

  @override
  String get dvirDefectNoCertifications => 'لا اعتمادات بعد';

  @override
  String get eldMalfunctionManualActive => 'التسجيل اليدوي مفعّل حالياً.';

  @override
  String eldMalfunctionManualActiveWithReason(String reason) {
    return 'التسجيل اليدوي مفعّل حالياً — $reason.';
  }

  @override
  String get eldMalfunctionEndManual => 'إنهاء التسجيل اليدوي';

  @override
  String get eldMalfunctionServerNotAllow =>
      'الخادم لا يسمح بالتحويل إلى التسجيل اليدوي لهذه المركبة.';

  @override
  String get eldMalfunctionStartManual => 'بدء التسجيل اليدوي';

  @override
  String get eldMalfunctionStartSuccess =>
      'تم تسجيل بداية فترة التسجيل اليدوي على الخادم.';

  @override
  String get eldMalfunctionEndSuccess =>
      'تم إنهاء التسجيل اليدوي والعودة إلى التسجيل الإلكتروني.';

  @override
  String get eldMalfunctionReasonStart => 'سبب التسجيل اليدوي';

  @override
  String get eldMalfunctionReasonEnd => 'سبب إنهاء التسجيل اليدوي';

  @override
  String get eldMalfunctionHintStart => 'مثال: انقطاع الاتصال بالجهاز';

  @override
  String get eldMalfunctionHintEnd => 'مثال: عاد اتصال الجهاز';

  @override
  String get dvirListNoRecords => 'لا توجد سجلات';

  @override
  String get dvirListTotal => 'إجمالي';

  @override
  String get dvirListOpen => 'عيوب مفتوحة';

  @override
  String get dvirListSigned => 'موقّعة';

  @override
  String get dvirListOos => 'خارج الخدمة';

  @override
  String get serverAcceptedDisconnected =>
      'قبل الخادم المتابعة دون اتصال. لم يُنشأ حدث واجب محلي.';

  @override
  String get macAddressRequired => 'عنوان MAC مطلوب.';

  @override
  String get coDriverSelectLabel => 'اختر مساعد السائق';

  @override
  String get coDriverSelectHint => 'الرجاء اختيار مساعد السائق الخاص بك';

  @override
  String get coDriverSwitchDrivers => 'تبديل الأدوار';

  @override
  String get coDriverSwitchHint => 'ستصبح السائق المساعد. سيبقى مساعدك سائقاً.';

  @override
  String get coDriverSwitching => 'جاري التبديل...';

  @override
  String get coDriverSwitchAction => 'تبديل';

  @override
  String get coDriverConfirmSwitchTitle => 'تأكيد التبديل';

  @override
  String get coDriverConfirmSwitchBody =>
      'يطلب التبديل من الخادم فقط. لن تُنقل ساعات الخدمة ولن تتغير حالة الواجب.';

  @override
  String get coDriverRolesSwitchedTitle => 'تم تبديل الأدوار';

  @override
  String coDriverRolesSwitchedBody(String newPrimary) {
    return 'أنت الآن السائق المساعد.\n$newPrimary هو الآن السائق الأساسي.\n\nلم تُنقل الساعات ولم تتغير حالة الواجب. يضبط السائق الجديد حالته قبل الحركة.';
  }

  @override
  String get coDriverDefaultNewPrimary => 'السائق المساعد';

  @override
  String get coDriverNone => 'لا سائق مساعد';

  @override
  String get coDriverRefusalSessionMissing =>
      'جلسة السائق غير موجودة. سجّل الدخول قبل التبديل.';

  @override
  String get coDriverRefusalStillDriving =>
      'غيّر حالة الواجب قبل التسليم. التبديل لا يغيّر الحالة.';

  @override
  String get coDriverRefusalMotionUnknown =>
      'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.';

  @override
  String get coDriverRefusalThresholdMissing =>
      'عتبة الحركة غير متوفرة من الإعداد.';

  @override
  String get coDriverRefusalVehicleMoving =>
      'لا يمكن تبديل الأدوار والمركبة تتحرك.';

  @override
  String get coDriverRefusalCoDriverMissing =>
      'اختر سائقاً مساعداً قبل التبديل.';

  @override
  String get coDriverRefusalSameDriver =>
      'لا يمكن اختيار الحساب الحالي سائقاً مساعداً.';

  @override
  String get coDriverLinkedTitle => 'المساعد المرتبط';

  @override
  String get coDriverLinkNotRead => 'لم يُقرأ الارتباط بعد.';

  @override
  String get coDriverLinkNone => 'لا سائق مساعد مرتبط.';

  @override
  String get coDriverTeamDrivingActive => 'قيادة جماعية نشطة';

  @override
  String get coDriverTeamDrivingInactive => 'قيادة جماعية غير نشطة';

  @override
  String get coDriverHosIsolationReadError => 'تعذر قراءة حالة عزل سجلات HOS.';

  @override
  String get coDriverHosIsolated => 'سجلات HOS معزولة';

  @override
  String get coDriverHosNotIsolated => 'سجلات HOS غير معزولة';

  @override
  String get coDriverVehicleMissing => 'اختر مركبة قبل ربط السائق المساعد.';

  @override
  String get dvirDefectsNone => 'لا توجد عيوب للتقرير عنها.';

  @override
  String dvirDefectsCount(int defectCount) {
    return 'تم تحديد $defectCount عيوب.';
  }

  @override
  String get languageSpanish => 'الإسبانية';

  @override
  String get reCertificationRequiredMsg =>
      'يلزم إعادة الاعتماد: حدثت تعديلات بعد آخر توقيع.';

  @override
  String get statusOff => 'خارج الخدمة';

  @override
  String get statusSb => 'مقصورة النوم';

  @override
  String get statusD => 'قيادة';

  @override
  String get statusOn => 'في الخدمة';

  @override
  String get statusPc => 'استخدام شخصي';

  @override
  String get statusYm => 'حركة ساحة';

  @override
  String get dvirPreTrip => 'قبل الرحلة';

  @override
  String get dvirPostTrip => 'بعد الرحلة';

  @override
  String get dvirSafeToDrive => 'آمنة للقيادة';

  @override
  String get dvirNeedsRepair => 'تتطلب صيانة';

  @override
  String get dvirUnsafe => 'غير آمنة';

  @override
  String get dvirBrakes => 'المكابح';

  @override
  String get dvirTires => 'الإطارات';

  @override
  String get dvirLights => 'الإضاءة';

  @override
  String get dvirSteering => 'أجهزة التوجيه';

  @override
  String get dvirTrailerCoupling => 'وصلات المقطورة';

  @override
  String get dvirEmergencyEquipment => 'معدات الطوارئ';

  @override
  String get dvirEngine => 'المحرك';

  @override
  String get dvirFuelSystem => 'نظام الوقود';

  @override
  String get dvirExhaustSystem => 'نظام العادم';

  @override
  String get dvirSuspension => 'نظام التعليق';

  @override
  String get dvirMirrors => 'المرايا';

  @override
  String get dvirWindshield => 'الزجاج الأمامي';

  @override
  String get routingCode => 'رمز التوجيه';

  @override
  String get routingCodeHint => 'أدخل رمز التوجيه من المفتش';

  @override
  String get tooManyPinAttempts =>
      'محاولات خاطئة كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String get reviewedBy => 'باسم مُراجِع التقرير';

  @override
  String get companyName => 'الشركة';

  @override
  String get edit => 'تعديل';

  @override
  String get diagnosticsScreen => 'التشخيصات';

  @override
  String get diagnosticEvents => 'أحداث تشخيص البيانات';

  @override
  String get formSavedOffline =>
      'حُفظ النموذج محلياً — سيُزامن عند عودة الاتصال.';

  @override
  String get transferMethodWebServices => 'خدمات الويب';

  @override
  String get transferMethodEmail => 'البريد الإلكتروني';

  @override
  String get dvirRepairCert => 'شهادة إصلاح';

  @override
  String get dvirReviewed39613 => 'تمت مراجعة §396.13';

  @override
  String get dvirReportId => 'معرّف التقرير';

  @override
  String get dvirRetentionUntil => 'الاحتفاظ حتى (§396.11)';

  @override
  String get dvirPrevReviewSection => 'مراجعة تقرير الفحص السابق (§396.13)';

  @override
  String get offlineEldGeneratedTitle =>
      'تم توليد ملف ELD بنجاح في وضع عدم الاتصال';

  @override
  String get offlineEldGeneratedDesc =>
      'تم إنشاء الملف محلياً بصيغة CSV وفق معايير FMCSA (49 CFR § 395). تم جدولة إرسال السجلات للسيرفر فور عودة الاتصال، ويمكنك مشاركة الملف مباشرة مع ضابط التفتيش الآن.';

  @override
  String get shareOrExportCsv => 'مشاركة / حفظ ملف CSV';

  @override
  String get dutyChangeTimeUnavailable =>
      'لم يُسجل الواجب لأن وقت الخادم غير متاح.';

  @override
  String get dutyChangeNotReady => 'حالة الواجب غير جاهزة.';

  @override
  String get dutyChangeUnmapped => 'حالة الواجب غير معروفة.';

  @override
  String get dutyChangeServerRejected =>
      'لم يقبل الخادم تغيير الحالة. تحقق من الاتصال وحاول مجدداً.';

  @override
  String get dutyChangeAccepted => 'قبل الخادم تغيير حالة الواجب.';

  @override
  String get annotationRequiredForPcYm =>
      'يجب كتابة ملاحظة للقيادة الشخصية أو حركة الساحة.';
}
