import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @auditTrail.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get auditTrail;

  /// No description provided for @auditTrailNote.
  ///
  /// In ar, this message translates to:
  /// **'يؤكد هذا السجل حفظ كل إجراء مع المستخدم والوقت والقيم السابقة والجديدة. لا يمكن تعديل هذا السجل أو حذفه.'**
  String get auditTrailNote;

  /// No description provided for @auditNoRecords.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات'**
  String get auditNoRecords;

  /// No description provided for @auditLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل سجل التدقيق.'**
  String get auditLoadFailed;

  /// No description provided for @vehicleStatusOutOfService.
  ///
  /// In ar, this message translates to:
  /// **'خارج الخدمة'**
  String get vehicleStatusOutOfService;

  /// No description provided for @vehicleStatusRestricted.
  ///
  /// In ar, this message translates to:
  /// **'مقيّدة'**
  String get vehicleStatusRestricted;

  /// No description provided for @vehicleStatusAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاحة'**
  String get vehicleStatusAvailable;

  /// No description provided for @driverName.
  ///
  /// In ar, this message translates to:
  /// **'اسم السائق'**
  String get driverName;

  /// No description provided for @driverId.
  ///
  /// In ar, this message translates to:
  /// **'معرف السائق'**
  String get driverId;

  /// No description provided for @license.
  ///
  /// In ar, this message translates to:
  /// **'الرخصة'**
  String get license;

  /// No description provided for @licenseState.
  ///
  /// In ar, this message translates to:
  /// **'ولاية الرخصة'**
  String get licenseState;

  /// No description provided for @exemptDriver.
  ///
  /// In ar, this message translates to:
  /// **'حالة الإعفاء'**
  String get exemptDriver;

  /// No description provided for @unidentifiedDriving.
  ///
  /// In ar, this message translates to:
  /// **'قيادة غير محددة'**
  String get unidentifiedDriving;

  /// No description provided for @coDriverId.
  ///
  /// In ar, this message translates to:
  /// **'معرف المساعد'**
  String get coDriverId;

  /// No description provided for @logDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ السجل'**
  String get logDate;

  /// No description provided for @displayDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ العرض'**
  String get displayDate;

  /// No description provided for @displayLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع العرض'**
  String get displayLocation;

  /// No description provided for @eldRegId.
  ///
  /// In ar, this message translates to:
  /// **'معرف تسجيل ELD'**
  String get eldRegId;

  /// No description provided for @eldIdentifier.
  ///
  /// In ar, this message translates to:
  /// **'معرف ELD'**
  String get eldIdentifier;

  /// No description provided for @provider.
  ///
  /// In ar, this message translates to:
  /// **'المزود'**
  String get provider;

  /// No description provided for @periodStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية الفترة'**
  String get periodStart;

  /// No description provided for @dataDiag.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص البيانات'**
  String get dataDiag;

  /// No description provided for @deviceMalf.
  ///
  /// In ar, this message translates to:
  /// **'أعطال الجهاز'**
  String get deviceMalf;

  /// No description provided for @vin.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهيكل'**
  String get vin;

  /// No description provided for @carrier.
  ///
  /// In ar, this message translates to:
  /// **'الناقل'**
  String get carrier;

  /// No description provided for @mainOffice.
  ///
  /// In ar, this message translates to:
  /// **'المكتب الرئيسي'**
  String get mainOffice;

  /// No description provided for @homeTerminal.
  ///
  /// In ar, this message translates to:
  /// **'المحطة الرئيسية'**
  String get homeTerminal;

  /// No description provided for @insertDutyStatus.
  ///
  /// In ar, this message translates to:
  /// **'إدخال حالة'**
  String get insertDutyStatus;

  /// No description provided for @addButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addButton;

  /// No description provided for @eventAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الحدث بنجاح'**
  String get eventAddedSuccess;

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'Golden Feather ELD'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In ar, this message translates to:
  /// **'الريشة الذهبية - تتبع الامتثال الميداني'**
  String get appSlogan;

  /// No description provided for @trackingTitle.
  ///
  /// In ar, this message translates to:
  /// **'التتبع'**
  String get trackingTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @statusTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusTitle;

  /// No description provided for @saveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @okButton.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get okButton;

  /// No description provided for @deleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteButton;

  /// No description provided for @retryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryButton;

  /// No description provided for @closeButton.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get closeButton;

  /// No description provided for @shareButton.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get shareButton;

  /// No description provided for @clearButton.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearButton;

  /// No description provided for @refreshButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refreshButton;

  /// No description provided for @locationButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الموقع'**
  String get locationButton;

  /// No description provided for @statusButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض الحالة'**
  String get statusButton;

  /// No description provided for @settingsButton.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الإعدادات'**
  String get settingsButton;

  /// No description provided for @invalidValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة غير صالحة'**
  String get invalidValue;

  /// No description provided for @disabledValue.
  ///
  /// In ar, this message translates to:
  /// **'معطل'**
  String get disabledValue;

  /// No description provided for @idLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الجهاز'**
  String get idLabel;

  /// No description provided for @urlLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخادم'**
  String get urlLabel;

  /// No description provided for @accuracyLabel.
  ///
  /// In ar, this message translates to:
  /// **'دقة الموقع'**
  String get accuracyLabel;

  /// No description provided for @highestAccuracyLabel.
  ///
  /// In ar, this message translates to:
  /// **'أعلى'**
  String get highestAccuracyLabel;

  /// No description provided for @highAccuracyLabel.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get highAccuracyLabel;

  /// No description provided for @mediumAccuracyLabel.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get mediumAccuracyLabel;

  /// No description provided for @lowAccuracyLabel.
  ///
  /// In ar, this message translates to:
  /// **'منخفضة'**
  String get lowAccuracyLabel;

  /// No description provided for @intervalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل الزمني (ثوانٍ)'**
  String get intervalLabel;

  /// No description provided for @fastestIntervalLabel.
  ///
  /// In ar, this message translates to:
  /// **'أسرع فاصل زمني (ثوانٍ)'**
  String get fastestIntervalLabel;

  /// No description provided for @distanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'المسافة (أمتار)'**
  String get distanceLabel;

  /// No description provided for @angleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الزاوية (درجات)'**
  String get angleLabel;

  /// No description provided for @heartbeatLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبض الثبات (ثوانٍ)'**
  String get heartbeatLabel;

  /// No description provided for @bufferLabel.
  ///
  /// In ar, this message translates to:
  /// **'تخزين مؤقت دون اتصال'**
  String get bufferLabel;

  /// No description provided for @wakelockLabel.
  ///
  /// In ar, this message translates to:
  /// **'قفل التنبيه'**
  String get wakelockLabel;

  /// No description provided for @stopDetectionLabel.
  ///
  /// In ar, this message translates to:
  /// **'اكتشاف التوقف'**
  String get stopDetectionLabel;

  /// No description provided for @preferPlatformProvidersLabel.
  ///
  /// In ar, this message translates to:
  /// **'استخدام مزودي الموقع الأصليين'**
  String get preferPlatformProvidersLabel;

  /// No description provided for @serverNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الخادم مفقودة'**
  String get serverNotConfigured;

  /// No description provided for @trackingLabel.
  ///
  /// In ar, this message translates to:
  /// **'تتبع مستمر'**
  String get trackingLabel;

  /// No description provided for @advancedLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات متقدمة'**
  String get advancedLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @optimizationMessage.
  ///
  /// In ar, this message translates to:
  /// **'لضمان تتبع موثوق، يرجى تعطيل تحسين البطارية لهذا التطبيق.'**
  String get optimizationMessage;

  /// No description provided for @passwordError.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور خاطئة'**
  String get passwordError;

  /// No description provided for @disclosureMessage.
  ///
  /// In ar, this message translates to:
  /// **'يقوم هذا التطبيق بجمع بيانات الموقع والنشاط في الخلفية وإرسالها إلى الخادم المحدد.'**
  String get disclosureMessage;

  /// No description provided for @configurationMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تطبيق الإعدادات الجديدة؟'**
  String get configurationMessage;

  /// No description provided for @startAction.
  ///
  /// In ar, this message translates to:
  /// **'بدء'**
  String get startAction;

  /// No description provided for @stopAction.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الخدمة'**
  String get stopAction;

  /// No description provided for @sosAction.
  ///
  /// In ar, this message translates to:
  /// **'ارسال استغاثة'**
  String get sosAction;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @inspection.
  ///
  /// In ar, this message translates to:
  /// **'التفتيش'**
  String get inspection;

  /// No description provided for @checklist.
  ///
  /// In ar, this message translates to:
  /// **'قائمة التحقق'**
  String get checklist;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @username.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get username;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @startInspection.
  ///
  /// In ar, this message translates to:
  /// **'بدء التفتيش'**
  String get startInspection;

  /// No description provided for @stopInspection.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التفتيش'**
  String get stopInspection;

  /// No description provided for @pauseInspection.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pauseInspection;

  /// No description provided for @resumeInspection.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get resumeInspection;

  /// No description provided for @submitReport.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقرير'**
  String get submitReport;

  /// No description provided for @saveDraft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كمسودة'**
  String get saveDraft;

  /// No description provided for @discardDraft.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل المسودة'**
  String get discardDraft;

  /// No description provided for @inspectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التفتيش'**
  String get inspectionTitle;

  /// No description provided for @inspectionLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع التفتيش'**
  String get inspectionLocation;

  /// No description provided for @inspectionDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التفتيش'**
  String get inspectionDate;

  /// No description provided for @inspectionTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التفتيش'**
  String get inspectionTime;

  /// No description provided for @inspectionDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدة التفتيش'**
  String get inspectionDuration;

  /// No description provided for @inspectorName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المفتش'**
  String get inspectorName;

  /// No description provided for @inspectionStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة التفتيش'**
  String get inspectionStatus;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل'**
  String get statusFailed;

  /// No description provided for @statusRequiresReview.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج مراجعة'**
  String get statusRequiresReview;

  /// No description provided for @statusScheduled.
  ///
  /// In ar, this message translates to:
  /// **'مجدول'**
  String get statusScheduled;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @checklistTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان القائمة'**
  String get checklistTitle;

  /// No description provided for @checklistCategory.
  ///
  /// In ar, this message translates to:
  /// **'تصنيف القائمة'**
  String get checklistCategory;

  /// No description provided for @addChecklist.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قائمة'**
  String get addChecklist;

  /// No description provided for @editChecklist.
  ///
  /// In ar, this message translates to:
  /// **'تعديل القائمة'**
  String get editChecklist;

  /// No description provided for @deleteChecklist.
  ///
  /// In ar, this message translates to:
  /// **'حذف القائمة'**
  String get deleteChecklist;

  /// No description provided for @checklistItems.
  ///
  /// In ar, this message translates to:
  /// **'عناصر القائمة'**
  String get checklistItems;

  /// No description provided for @addItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنصر'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In ar, this message translates to:
  /// **'إزالة عنصر'**
  String get removeItem;

  /// No description provided for @itemTypeText.
  ///
  /// In ar, this message translates to:
  /// **'نص'**
  String get itemTypeText;

  /// No description provided for @itemTypeNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم'**
  String get itemTypeNumber;

  /// No description provided for @itemTypeYesNo.
  ///
  /// In ar, this message translates to:
  /// **'نعم / لا'**
  String get itemTypeYesNo;

  /// No description provided for @itemTypeMultipleChoice.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من متعدد'**
  String get itemTypeMultipleChoice;

  /// No description provided for @itemTypePhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get itemTypePhoto;

  /// No description provided for @itemTypeSignature.
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get itemTypeSignature;

  /// No description provided for @itemTypeDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ'**
  String get itemTypeDate;

  /// No description provided for @itemTypeTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت'**
  String get itemTypeTime;

  /// No description provided for @itemTypeBarcode.
  ///
  /// In ar, this message translates to:
  /// **'باركود'**
  String get itemTypeBarcode;

  /// No description provided for @photoRequired.
  ///
  /// In ar, this message translates to:
  /// **'الصورة مطلوبة'**
  String get photoRequired;

  /// No description provided for @signatureRequired.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع مطلوب'**
  String get signatureRequired;

  /// No description provided for @notesRequired.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات مطلوبة'**
  String get notesRequired;

  /// No description provided for @takePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get chooseFromGallery;

  /// No description provided for @retakePhoto.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التصوير'**
  String get retakePhoto;

  /// No description provided for @photoPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الصورة'**
  String get photoPreview;

  /// No description provided for @signHere.
  ///
  /// In ar, this message translates to:
  /// **'وقع هنا'**
  String get signHere;

  /// No description provided for @clearSignature.
  ///
  /// In ar, this message translates to:
  /// **'مسح التوقيع'**
  String get clearSignature;

  /// No description provided for @signaturePreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة التوقيع'**
  String get signaturePreview;

  /// No description provided for @addNote.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة'**
  String get deleteNote;

  /// No description provided for @syncStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة المزامنة'**
  String get syncStatus;

  /// No description provided for @synced.
  ///
  /// In ar, this message translates to:
  /// **'متزامن'**
  String get synced;

  /// No description provided for @syncing.
  ///
  /// In ar, this message translates to:
  /// **'جاري المزامنة...'**
  String get syncing;

  /// No description provided for @syncPending.
  ///
  /// In ar, this message translates to:
  /// **'{count} معلقة'**
  String syncPending(String count);

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'{count} فشلت'**
  String syncFailed(String count);

  /// No description provided for @offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get offline;

  /// No description provided for @lastSync.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة'**
  String get lastSync;

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الآن'**
  String get syncNow;

  /// No description provided for @autoSync.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة تلقائية'**
  String get autoSync;

  /// No description provided for @errorMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get errorMessage;

  /// No description provided for @successMessage.
  ///
  /// In ar, this message translates to:
  /// **'تمت العملية بنجاح'**
  String get successMessage;

  /// No description provided for @warningMessage.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get warningMessage;

  /// No description provided for @infoMessage.
  ///
  /// In ar, this message translates to:
  /// **'معلومة'**
  String get infoMessage;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @noInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get noInternet;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @permissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الإذن'**
  String get permissionDenied;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يرجى منح إذن الوصول إلى الموقع'**
  String get locationPermissionDenied;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يرجى منح إذن الوصول إلى الكاميرا'**
  String get cameraPermissionDenied;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يرجى منح إذن الوصول إلى التخزين'**
  String get storagePermissionDenied;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get confirmDelete;

  /// No description provided for @confirmLogout.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تسجيل الخروج؟'**
  String get confirmLogout;

  /// No description provided for @confirmSubmit.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إرسال التقرير؟'**
  String get confirmSubmit;

  /// No description provided for @confirmDiscard.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تجاهل التغييرات؟'**
  String get confirmDiscard;

  /// No description provided for @unsavedChanges.
  ///
  /// In ar, this message translates to:
  /// **'لديك تغييرات غير محفوظة'**
  String get unsavedChanges;

  /// No description provided for @changesWillBeLost.
  ///
  /// In ar, this message translates to:
  /// **'سيتم فقدان التغييرات إذا واصلت'**
  String get changesWillBeLost;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageLabel;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع النظام'**
  String get systemMode;

  /// No description provided for @themeLabel.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutLabel;

  /// No description provided for @versionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get versionLabel;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ar, this message translates to:
  /// **'شروط الخدمة'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بنا'**
  String get contactUs;

  /// No description provided for @help.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة'**
  String get faq;

  /// No description provided for @qrCodeScanner.
  ///
  /// In ar, this message translates to:
  /// **'مسح الرمز'**
  String get qrCodeScanner;

  /// No description provided for @scanQRCode.
  ///
  /// In ar, this message translates to:
  /// **'مسح رمز QR'**
  String get scanQRCode;

  /// No description provided for @scanningInstructions.
  ///
  /// In ar, this message translates to:
  /// **'وجه الكاميرا نحو رمز QR'**
  String get scanningInstructions;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get sortByName;

  /// No description provided for @sortByDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get sortByDate;

  /// No description provided for @sortByStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get sortByStatus;

  /// No description provided for @exportPDF.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPDF;

  /// No description provided for @exportExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير Excel'**
  String get exportExcel;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @newInspectionAssigned.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين تفتيش جديد'**
  String get newInspectionAssigned;

  /// No description provided for @inspectionReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بالتفتيش'**
  String get inspectionReminder;

  /// No description provided for @inspectionOverdue.
  ///
  /// In ar, this message translates to:
  /// **'تفتيش متأخر'**
  String get inspectionOverdue;

  /// No description provided for @syncComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت المزامنة'**
  String get syncComplete;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @na.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get na;

  /// No description provided for @pass.
  ///
  /// In ar, this message translates to:
  /// **'ناجح'**
  String get pass;

  /// No description provided for @fail.
  ///
  /// In ar, this message translates to:
  /// **'راسب'**
  String get fail;

  /// No description provided for @monday.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In ar, this message translates to:
  /// **'يناير'**
  String get january;

  /// No description provided for @february.
  ///
  /// In ar, this message translates to:
  /// **'فبراير'**
  String get february;

  /// No description provided for @march.
  ///
  /// In ar, this message translates to:
  /// **'مارس'**
  String get march;

  /// No description provided for @april.
  ///
  /// In ar, this message translates to:
  /// **'أبريل'**
  String get april;

  /// No description provided for @may.
  ///
  /// In ar, this message translates to:
  /// **'مايو'**
  String get may;

  /// No description provided for @june.
  ///
  /// In ar, this message translates to:
  /// **'يونيو'**
  String get june;

  /// No description provided for @july.
  ///
  /// In ar, this message translates to:
  /// **'يوليو'**
  String get july;

  /// No description provided for @august.
  ///
  /// In ar, this message translates to:
  /// **'أغسطس'**
  String get august;

  /// No description provided for @september.
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر'**
  String get september;

  /// No description provided for @october.
  ///
  /// In ar, this message translates to:
  /// **'أكتوبر'**
  String get october;

  /// No description provided for @november.
  ///
  /// In ar, this message translates to:
  /// **'نوفمبر'**
  String get november;

  /// No description provided for @december.
  ///
  /// In ar, this message translates to:
  /// **'ديسمبر'**
  String get december;

  /// No description provided for @unableToConnect.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بجهاز ELD بالعنوان'**
  String get unableToConnect;

  /// No description provided for @verifyFollowingItems.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التحقق من العناصر التالية:'**
  String get verifyFollowingItems;

  /// No description provided for @macEnteredCorrectly.
  ///
  /// In ar, this message translates to:
  /// **'تم إدخال عنوان MAC بشكل صحيح.'**
  String get macEnteredCorrectly;

  /// No description provided for @hardwareProperlyInstalled.
  ///
  /// In ar, this message translates to:
  /// **'تم تركيب جهاز ELD بشكل صحيح.'**
  String get hardwareProperlyInstalled;

  /// No description provided for @vehiclePowerOn.
  ///
  /// In ar, this message translates to:
  /// **'طاقة المركبة قيد التشغيل.'**
  String get vehiclePowerOn;

  /// No description provided for @bluetoothEnabled.
  ///
  /// In ar, this message translates to:
  /// **'البلوتوث مفعل في الجهاز المحمول.'**
  String get bluetoothEnabled;

  /// No description provided for @gpsEnabled.
  ///
  /// In ar, this message translates to:
  /// **'نظام تحديد المواقع GPS مفعل في الجهاز المحمول.'**
  String get gpsEnabled;

  /// No description provided for @enterMacAddress.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان MAC الخاص بـ ELD والموجود على الجهاز:'**
  String get enterMacAddress;

  /// No description provided for @connect.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get connect;

  /// No description provided for @continueDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'متابعة بدون اتصال'**
  String get continueDisconnected;

  /// No description provided for @usernameRequired.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم مطلوب'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور مطلوبة'**
  String get passwordRequired;

  /// No description provided for @hoursRecap.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الساعات'**
  String get hoursRecap;

  /// No description provided for @suggestedEvents.
  ///
  /// In ar, this message translates to:
  /// **'الأحداث المقترحة'**
  String get suggestedEvents;

  /// No description provided for @unidentifiedEvents.
  ///
  /// In ar, this message translates to:
  /// **'الأحداث غير المحددة'**
  String get unidentifiedEvents;

  /// No description provided for @unclaimed.
  ///
  /// In ar, this message translates to:
  /// **'غير مطالب بها'**
  String get unclaimed;

  /// No description provided for @rejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة'**
  String get rejected;

  /// No description provided for @noRecords.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات'**
  String get noRecords;

  /// No description provided for @drawSignatureHere.
  ///
  /// In ar, this message translates to:
  /// **'ارسم توقيعك هنا'**
  String get drawSignatureHere;

  /// No description provided for @fillFormFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب تعبئة النموذج وحفظه أولاً.'**
  String get fillFormFirst;

  /// No description provided for @formLabel.
  ///
  /// In ar, this message translates to:
  /// **'النموذج'**
  String get formLabel;

  /// No description provided for @certifyLabel.
  ///
  /// In ar, this message translates to:
  /// **'التوثيق'**
  String get certifyLabel;

  /// No description provided for @editDutyStatus.
  ///
  /// In ar, this message translates to:
  /// **'تعديل حالة الخدمة'**
  String get editDutyStatus;

  /// No description provided for @startTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت البداية'**
  String get startTime;

  /// No description provided for @duration.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get duration;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @vehicle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة'**
  String get vehicle;

  /// No description provided for @location.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get location;

  /// No description provided for @manualLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع يدوي'**
  String get manualLocation;

  /// No description provided for @events.
  ///
  /// In ar, this message translates to:
  /// **'الأحداث'**
  String get events;

  /// No description provided for @form.
  ///
  /// In ar, this message translates to:
  /// **'النموذج'**
  String get form;

  /// No description provided for @certify.
  ///
  /// In ar, this message translates to:
  /// **'التوثيق'**
  String get certify;

  /// No description provided for @driver.
  ///
  /// In ar, this message translates to:
  /// **'السائق'**
  String get driver;

  /// No description provided for @vehicles.
  ///
  /// In ar, this message translates to:
  /// **'المركبات'**
  String get vehicles;

  /// No description provided for @trailers.
  ///
  /// In ar, this message translates to:
  /// **'المقطورات'**
  String get trailers;

  /// No description provided for @shippingDocuments.
  ///
  /// In ar, this message translates to:
  /// **'وثائق الشحن'**
  String get shippingDocuments;

  /// No description provided for @coDriver.
  ///
  /// In ar, this message translates to:
  /// **'سائق مساعد'**
  String get coDriver;

  /// No description provided for @imageNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الصورة غير متاحة'**
  String get imageNotAvailable;

  /// No description provided for @certifyDeclaration.
  ///
  /// In ar, this message translates to:
  /// **'أشهد بموجب هذا أن بياناتي وسجل حالة الخدمة خلال فترة 24 ساعة هذه صحيحة ومضبوطة.'**
  String get certifyDeclaration;

  /// No description provided for @notReady.
  ///
  /// In ar, this message translates to:
  /// **'غير جاهز'**
  String get notReady;

  /// No description provided for @agree.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get agree;

  /// No description provided for @timeline24h.
  ///
  /// In ar, this message translates to:
  /// **'المخطط الزمني 24 ساعة'**
  String get timeline24h;

  /// No description provided for @settingsAppliedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم تطبيق الإعدادات بنجاح'**
  String get settingsAppliedSuccess;

  /// No description provided for @deviceInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الجهاز'**
  String get deviceInformation;

  /// No description provided for @confirmClearLogs.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مسح جميع السجلات؟'**
  String get confirmClearLogs;

  /// No description provided for @trackingStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة التتبع'**
  String get trackingStatus;

  /// No description provided for @activeStatus.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get activeStatus;

  /// No description provided for @stoppedStatus.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get stoppedStatus;

  /// No description provided for @coordinatesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإحداثيات'**
  String get coordinatesLabel;

  /// No description provided for @lastUpdateLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث'**
  String get lastUpdateLabel;

  /// No description provided for @locationDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الموقع غير مفعل'**
  String get locationDisabled;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get openSettings;

  /// No description provided for @remainingLabel.
  ///
  /// In ar, this message translates to:
  /// **'متبقي'**
  String get remainingLabel;

  /// No description provided for @available.
  ///
  /// In ar, this message translates to:
  /// **'المتاح'**
  String get available;

  /// No description provided for @recap.
  ///
  /// In ar, this message translates to:
  /// **'الملخص'**
  String get recap;

  /// No description provided for @changeStatus.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحالة'**
  String get changeStatus;

  /// No description provided for @errorCannotChangeStatusWhileMoving.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير الحالة أثناء حركة المركبة.'**
  String get errorCannotChangeStatusWhileMoving;

  /// No description provided for @customLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع مخصص'**
  String get customLocation;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @updateButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get updateButton;

  /// No description provided for @offDuty.
  ///
  /// In ar, this message translates to:
  /// **'خارج الخدمة'**
  String get offDuty;

  /// No description provided for @sleeperBerth.
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get sleeperBerth;

  /// No description provided for @drivingStatus.
  ///
  /// In ar, this message translates to:
  /// **'القيادة'**
  String get drivingStatus;

  /// No description provided for @onDuty.
  ///
  /// In ar, this message translates to:
  /// **'في الخدمة'**
  String get onDuty;

  /// No description provided for @personalUse.
  ///
  /// In ar, this message translates to:
  /// **'استخدام شخصي'**
  String get personalUse;

  /// No description provided for @yardMoves.
  ///
  /// In ar, this message translates to:
  /// **'تحركات الساحة'**
  String get yardMoves;

  /// No description provided for @confirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirmTitle;

  /// No description provided for @qrScannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح رمز QR'**
  String get qrScannerTitle;

  /// No description provided for @qrScannerInstructions.
  ///
  /// In ar, this message translates to:
  /// **'وجه الكاميرا نحو رمز QR'**
  String get qrScannerInstructions;

  /// No description provided for @logsTitle.
  ///
  /// In ar, this message translates to:
  /// **'السجلات'**
  String get logsTitle;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @last7Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 7 أيام'**
  String get last7Days;

  /// No description provided for @hoursWorkedToday.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل اليوم'**
  String get hoursWorkedToday;

  /// No description provided for @hoursAvailableToday.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المتاحة اليوم'**
  String get hoursAvailableToday;

  /// No description provided for @hoursAvailableTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المتاحة غداً'**
  String get hoursAvailableTomorrow;

  /// No description provided for @registerAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get registerAction;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل مطلوب'**
  String get fullNameRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordMismatch;

  /// No description provided for @haveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get haveAccount;

  /// No description provided for @loginHere.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك هنا'**
  String get loginHere;

  /// No description provided for @resetPassword.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get resetPassword;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مطلوب'**
  String get emailRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد الإلكتروني غير صحيحة'**
  String get invalidEmailFormat;

  /// No description provided for @sendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط الاستعادة'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get backToLogin;

  /// No description provided for @notImplemented.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة غير متوفرة بعد'**
  String get notImplemented;

  /// No description provided for @dvirTitle.
  ///
  /// In ar, this message translates to:
  /// **'فحص المركبة (DVIR)'**
  String get dvirTitle;

  /// No description provided for @inspectionType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الفحص'**
  String get inspectionType;

  /// No description provided for @vehicleInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات المركبة'**
  String get vehicleInfo;

  /// No description provided for @mechanicalChecklist.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الفحص الميكانيكي'**
  String get mechanicalChecklist;

  /// No description provided for @additionalNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات إضافية'**
  String get additionalNotes;

  /// No description provided for @vehicleCondition.
  ///
  /// In ar, this message translates to:
  /// **'تقييم حالة المركبة'**
  String get vehicleCondition;

  /// No description provided for @driverSignature.
  ///
  /// In ar, this message translates to:
  /// **'توقيع السائق'**
  String get driverSignature;

  /// No description provided for @saveReport.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التقرير'**
  String get saveReport;

  /// No description provided for @updateReport.
  ///
  /// In ar, this message translates to:
  /// **'تحديث التقرير'**
  String get updateReport;

  /// No description provided for @newReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير فحص جديد'**
  String get newReport;

  /// No description provided for @editReport.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التقرير'**
  String get editReport;

  /// No description provided for @noDvirReports.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تقارير فحص'**
  String get noDvirReports;

  /// No description provided for @createNewReport.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير جديد'**
  String get createNewReport;

  /// No description provided for @reportSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تقرير الفحص بنجاح'**
  String get reportSavedSuccess;

  /// No description provided for @defectsFound.
  ///
  /// In ar, this message translates to:
  /// **'أعطال مكتشفة'**
  String get defectsFound;

  /// No description provided for @submitted.
  ///
  /// In ar, this message translates to:
  /// **'مقدم'**
  String get submitted;

  /// No description provided for @draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get draft;

  /// No description provided for @trailer.
  ///
  /// In ar, this message translates to:
  /// **'المقطورة'**
  String get trailer;

  /// No description provided for @odometerReading.
  ///
  /// In ar, this message translates to:
  /// **'عداد المسافات'**
  String get odometerReading;

  /// No description provided for @dtcCodes.
  ///
  /// In ar, this message translates to:
  /// **'رموز أعطال المحرك (DTC)'**
  String get dtcCodes;

  /// No description provided for @notesHint.
  ///
  /// In ar, this message translates to:
  /// **'أي ملاحظات إضافية عن حالة المركبة...'**
  String get notesHint;

  /// No description provided for @dateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get dateLabel;

  /// No description provided for @selectVehicle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المركبة'**
  String get selectVehicle;

  /// No description provided for @searchVehicle.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن مركبة...'**
  String get searchVehicle;

  /// No description provided for @noVehiclesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مركبات متاحة'**
  String get noVehiclesFound;

  /// No description provided for @vehicleSelected.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار المركبة'**
  String get vehicleSelected;

  /// No description provided for @unassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مسندة'**
  String get unassigned;

  /// No description provided for @underDevelopment.
  ///
  /// In ar, this message translates to:
  /// **'قيد التطوير...'**
  String get underDevelopment;

  /// No description provided for @am.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get pm;

  /// No description provided for @miles.
  ///
  /// In ar, this message translates to:
  /// **'ميل'**
  String get miles;

  /// No description provided for @hour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get minute;

  /// No description provided for @newInspectionReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير فحص جديد'**
  String get newInspectionReport;

  /// No description provided for @editInspectionReport.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التقرير'**
  String get editInspectionReport;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get inactive;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get notAvailable;

  /// No description provided for @deviceInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الجهاز'**
  String get deviceInfo;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @rules.
  ///
  /// In ar, this message translates to:
  /// **'القواعد'**
  String get rules;

  /// No description provided for @infoPacket.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق'**
  String get infoPacket;

  /// No description provided for @odometer.
  ///
  /// In ar, this message translates to:
  /// **'وحدة المسافة'**
  String get odometer;

  /// No description provided for @engineHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات المحرك'**
  String get engineHours;

  /// No description provided for @offlineMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع غير متصل'**
  String get offlineMode;

  /// No description provided for @dotInspection.
  ///
  /// In ar, this message translates to:
  /// **'تفتيش DOT'**
  String get dotInspection;

  /// No description provided for @setInspectionPin.
  ///
  /// In ar, this message translates to:
  /// **'تعيين رمز التفتيش'**
  String get setInspectionPin;

  /// No description provided for @enter4DigitPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز من 4 أرقام'**
  String get enter4DigitPin;

  /// No description provided for @confirmPin.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get confirmPin;

  /// No description provided for @enterPinToUnlock.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز لفك القفل'**
  String get enterPinToUnlock;

  /// No description provided for @unlock.
  ///
  /// In ar, this message translates to:
  /// **'فك القفل'**
  String get unlock;

  /// No description provided for @dotInspectionMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع تفتيش DOT'**
  String get dotInspectionMode;

  /// No description provided for @screenLockedForOfficer.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة مقفلة لمراجعة الضابط'**
  String get screenLockedForOfficer;

  /// No description provided for @unlockDriverOnly.
  ///
  /// In ar, this message translates to:
  /// **'فك القفل (للسائق فقط)'**
  String get unlockDriverOnly;

  /// No description provided for @sendLogs.
  ///
  /// In ar, this message translates to:
  /// **'إرسال السجلات'**
  String get sendLogs;

  /// No description provided for @emailLogs.
  ///
  /// In ar, this message translates to:
  /// **'بريد السجلات'**
  String get emailLogs;

  /// No description provided for @endInspection.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التفتيش'**
  String get endInspection;

  /// No description provided for @certified.
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get certified;

  /// No description provided for @eldReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير ELD'**
  String get eldReport;

  /// No description provided for @hosReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير HOS'**
  String get hosReport;

  /// No description provided for @compliant.
  ///
  /// In ar, this message translates to:
  /// **'ممتثل'**
  String get compliant;

  /// No description provided for @nonCompliant.
  ///
  /// In ar, this message translates to:
  /// **'غير ممتثل'**
  String get nonCompliant;

  /// No description provided for @work.
  ///
  /// In ar, this message translates to:
  /// **'العمل'**
  String get work;

  /// No description provided for @rest.
  ///
  /// In ar, this message translates to:
  /// **'الراحة'**
  String get rest;

  /// No description provided for @break_.
  ///
  /// In ar, this message translates to:
  /// **'الاستراحة'**
  String get break_;

  /// No description provided for @distance.
  ///
  /// In ar, this message translates to:
  /// **'المسافة'**
  String get distance;

  /// No description provided for @malfunctionAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الأعطال'**
  String get malfunctionAlerts;

  /// No description provided for @clearAll.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get clearAll;

  /// No description provided for @pdfExportedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تصدير PDF بنجاح'**
  String get pdfExportedSuccess;

  /// No description provided for @userManual.
  ///
  /// In ar, this message translates to:
  /// **'دليل المستخدم'**
  String get userManual;

  /// No description provided for @instructions.
  ///
  /// In ar, this message translates to:
  /// **'التعليمات'**
  String get instructions;

  /// No description provided for @malfunctionManual.
  ///
  /// In ar, this message translates to:
  /// **'دليل الأعطال'**
  String get malfunctionManual;

  /// No description provided for @viewUserManual.
  ///
  /// In ar, this message translates to:
  /// **'عرض دليل المستخدم'**
  String get viewUserManual;

  /// No description provided for @viewInstructions.
  ///
  /// In ar, this message translates to:
  /// **'عرض التعليمات'**
  String get viewInstructions;

  /// No description provided for @viewMalfunctionManual.
  ///
  /// In ar, this message translates to:
  /// **'عرض دليل الأعطال'**
  String get viewMalfunctionManual;

  /// No description provided for @legalNotice.
  ///
  /// In ar, this message translates to:
  /// **'هذه الوثائق مطلوبة ضمن معايير إدارة الأساطيل المعتمدة. يجب أن تكون متاحة في جميع الأوقات أثناء تشغيل المركبة التجارية.'**
  String get legalNotice;

  /// No description provided for @gettingStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدء الاستخدام'**
  String get gettingStarted;

  /// No description provided for @connectingToVehicle.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بالمركبة'**
  String get connectingToVehicle;

  /// No description provided for @changingDutyStatus.
  ///
  /// In ar, this message translates to:
  /// **'تغيير حالة السائق'**
  String get changingDutyStatus;

  /// No description provided for @viewingLogs.
  ///
  /// In ar, this message translates to:
  /// **'عرض السجلات والتصديق'**
  String get viewingLogs;

  /// No description provided for @vehicleInspection.
  ///
  /// In ar, this message translates to:
  /// **'فحص المركبة (DVIR)'**
  String get vehicleInspection;

  /// No description provided for @roadsideInspection.
  ///
  /// In ar, this message translates to:
  /// **'التفتيش الميداني'**
  String get roadsideInspection;

  /// No description provided for @continueWithout.
  ///
  /// In ar, this message translates to:
  /// **'متابعة بدون'**
  String get continueWithout;

  /// No description provided for @grant.
  ///
  /// In ar, this message translates to:
  /// **'منح'**
  String get grant;

  /// No description provided for @time.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get time;

  /// No description provided for @odom.
  ///
  /// In ar, this message translates to:
  /// **'العداد'**
  String get odom;

  /// No description provided for @eng.
  ///
  /// In ar, this message translates to:
  /// **'المحرك'**
  String get eng;

  /// No description provided for @src.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get src;

  /// No description provided for @noManualModifications.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على تعديلات يدوية لهذا التاريخ.'**
  String get noManualModifications;

  /// No description provided for @failedToLoadAudits.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل السجلات'**
  String get failedToLoadAudits;

  /// No description provided for @exportErods.
  ///
  /// In ar, this message translates to:
  /// **'تصدير ملف eRODS'**
  String get exportErods;

  /// No description provided for @requiredForFmcsa.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب لتفتيش FMCSA'**
  String get requiredForFmcsa;

  /// No description provided for @changeStatusTo.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحالة إلى {status}'**
  String changeStatusTo(String status);

  /// No description provided for @connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاتصال...'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get disconnected;

  /// No description provided for @noRecordsToday.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات لهذا اليوم'**
  String get noRecordsToday;

  /// No description provided for @trackingNotStarted.
  ///
  /// In ar, this message translates to:
  /// **'لم يبدأ التتبع بعد'**
  String get trackingNotStarted;

  /// No description provided for @gpsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'GPS غير مفعل'**
  String get gpsDisabled;

  /// No description provided for @notConnectedToServer.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل بالخادم'**
  String get notConnectedToServer;

  /// No description provided for @unexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get unexpectedError;

  /// No description provided for @loadingRecords.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل السجلات...'**
  String get loadingRecords;

  /// No description provided for @defectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأعطال'**
  String get defectsTitle;

  /// No description provided for @vehicleConditionSatisfactory.
  ///
  /// In ar, this message translates to:
  /// **'حالة المركبة مرضية'**
  String get vehicleConditionSatisfactory;

  /// No description provided for @auditReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب: {reason}'**
  String auditReason(String reason);

  /// No description provided for @auditStatusChange.
  ///
  /// In ar, this message translates to:
  /// **'{oldStatus} -> {newStatus}'**
  String auditStatusChange(String oldStatus, String newStatus);

  /// No description provided for @calculatingLocation.
  ///
  /// In ar, this message translates to:
  /// **'جاري حساب الموقع...'**
  String get calculatingLocation;

  /// No description provided for @driveLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'القيادة'**
  String get driveLimitTitle;

  /// No description provided for @driveLimitDesc.
  ///
  /// In ar, this message translates to:
  /// **'حد 11 ساعة للقيادة'**
  String get driveLimitDesc;

  /// No description provided for @shiftLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوردية'**
  String get shiftLimitTitle;

  /// No description provided for @shiftLimitDesc.
  ///
  /// In ar, this message translates to:
  /// **'حد 14 ساعة للعمل'**
  String get shiftLimitDesc;

  /// No description provided for @breakLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاستراحة'**
  String get breakLimitTitle;

  /// No description provided for @breakLimitDesc.
  ///
  /// In ar, this message translates to:
  /// **'استراحة 30 دقيقة'**
  String get breakLimitDesc;

  /// No description provided for @cycleLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدورة'**
  String get cycleLimitTitle;

  /// No description provided for @cycleLimitDesc.
  ///
  /// In ar, this message translates to:
  /// **'USA 70/8'**
  String get cycleLimitDesc;

  /// No description provided for @hoursOfService.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الخدمة'**
  String get hoursOfService;

  /// No description provided for @sessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة'**
  String get sessionExpired;

  /// No description provided for @invalidConfiguration.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الخادم غير صالحة'**
  String get invalidConfiguration;

  /// No description provided for @invalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة'**
  String get invalidCredentials;

  /// No description provided for @sessionMissing.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة غير موجودة، يرجى تسجيل الدخول'**
  String get sessionMissing;

  /// No description provided for @interfaceLanguage.
  ///
  /// In ar, this message translates to:
  /// **'لغة الواجهة'**
  String get interfaceLanguage;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get languageEnglish;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @serverUrl.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخادم'**
  String get serverUrl;

  /// No description provided for @enterServerUrl.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الخادم.'**
  String get enterServerUrl;

  /// No description provided for @invalidServerUrl.
  ///
  /// In ar, this message translates to:
  /// **'عنوان غير صالح. مثال: https://server.example.com'**
  String get invalidServerUrl;

  /// No description provided for @serverUrlSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ عنوان الخادم.'**
  String get serverUrlSaved;

  /// No description provided for @formIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'البيانات غير مكتملة، يرجى ملء جميع الحقول أولاً.'**
  String get formIncomplete;

  /// No description provided for @sixteenHourCondition.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تفعيل استثناء 16 ساعة إلا إذا تحققت شروطه.'**
  String get sixteenHourCondition;

  /// No description provided for @rulesUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث القواعد.'**
  String get rulesUpdated;

  /// No description provided for @allowed.
  ///
  /// In ar, this message translates to:
  /// **'مسموح'**
  String get allowed;

  /// No description provided for @forbidden.
  ///
  /// In ar, this message translates to:
  /// **'ممنوع'**
  String get forbidden;

  /// No description provided for @notProvidedByServer.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفرة من الخادم'**
  String get notProvidedByServer;

  /// No description provided for @ruleSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر القاعدة'**
  String get ruleSource;

  /// No description provided for @cycleRule.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة الدورة'**
  String get cycleRule;

  /// No description provided for @cargoType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحمولة'**
  String get cargoType;

  /// No description provided for @restartRule.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التشغيل'**
  String get restartRule;

  /// No description provided for @restBreakRule.
  ///
  /// In ar, this message translates to:
  /// **'الاستراحة'**
  String get restBreakRule;

  /// No description provided for @sixteenHourException.
  ///
  /// In ar, this message translates to:
  /// **'استثناء 16 ساعة'**
  String get sixteenHourException;

  /// No description provided for @dailyLimits.
  ///
  /// In ar, this message translates to:
  /// **'الحدود اليومية'**
  String get dailyLimits;

  /// No description provided for @drivingLimit.
  ///
  /// In ar, this message translates to:
  /// **'القيادة'**
  String get drivingLimit;

  /// No description provided for @shiftWindowLimit.
  ///
  /// In ar, this message translates to:
  /// **'نافذة العمل'**
  String get shiftWindowLimit;

  /// No description provided for @cycleLimit.
  ///
  /// In ar, this message translates to:
  /// **'دورة العمل'**
  String get cycleLimit;

  /// No description provided for @hourAbbr.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get hourAbbr;

  /// No description provided for @minAbbr.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get minAbbr;

  /// No description provided for @contactFleetManager.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع مدير الأسطول للمزيد.'**
  String get contactFleetManager;

  /// No description provided for @personalConveyance.
  ///
  /// In ar, this message translates to:
  /// **'الاستخدام الشخصي'**
  String get personalConveyance;

  /// No description provided for @unlimitedTrailers.
  ///
  /// In ar, this message translates to:
  /// **'مقطورات غير محدودة'**
  String get unlimitedTrailers;

  /// No description provided for @unlimitedShippingDocs.
  ///
  /// In ar, this message translates to:
  /// **'مستندات شحن غير محدودة'**
  String get unlimitedShippingDocs;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutTitle;

  /// No description provided for @applicationInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التطبيق'**
  String get applicationInfo;

  /// No description provided for @appNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get appNameLabel;

  /// No description provided for @appVersionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get appVersionLabel;

  /// No description provided for @appPackageLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الحزمة'**
  String get appPackageLabel;

  /// No description provided for @deviceIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الجهاز'**
  String get deviceIdLabel;

  /// No description provided for @diagnosticsAndConnection.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص والاتصال'**
  String get diagnosticsAndConnection;

  /// No description provided for @centralServer.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المركزي'**
  String get centralServer;

  /// No description provided for @locationService.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع (GPS)'**
  String get locationService;

  /// No description provided for @enabled.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get disabled;

  /// No description provided for @hardwareAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الجهاز'**
  String get hardwareAlerts;

  /// No description provided for @noActiveAlerts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات'**
  String get noActiveAlerts;

  /// No description provided for @activeAlerts.
  ///
  /// In ar, this message translates to:
  /// **'يوجد تنبيهات'**
  String get activeAlerts;

  /// No description provided for @technicalInfo.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات التقنية'**
  String get technicalInfo;

  /// No description provided for @eldEngineVersion.
  ///
  /// In ar, this message translates to:
  /// **'إصدار محرك ELD'**
  String get eldEngineVersion;

  /// No description provided for @hardwareVersion.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الجهاز'**
  String get hardwareVersion;

  /// No description provided for @lastDataReceived.
  ///
  /// In ar, this message translates to:
  /// **'توقيت آخر بيانات'**
  String get lastDataReceived;

  /// No description provided for @eldConnectionStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة اتصال ELD'**
  String get eldConnectionStatus;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @supportText.
  ///
  /// In ar, this message translates to:
  /// **'للدعم الفني يرجى تزويد فريق الدعم بمعرّف الجهاز ورقم الإصدار أعلاه.'**
  String get supportText;

  /// No description provided for @noVehiclesAssigned.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مركبات معيّنة'**
  String get noVehiclesAssigned;

  /// No description provided for @vehiclesAssignedViaPortal.
  ///
  /// In ar, this message translates to:
  /// **'تُعيَّن المركبات عبر البوابة. '**
  String get vehiclesAssignedViaPortal;

  /// No description provided for @viewMyVehicles.
  ///
  /// In ar, this message translates to:
  /// **'عرض مركباتي'**
  String get viewMyVehicles;

  /// No description provided for @viewAllVehicles.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل المركبات'**
  String get viewAllVehicles;

  /// No description provided for @vehicleSelectedConnect.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار {name}. اتصل بجهاز ELD لتشغيلها. لم تُنقل ساعات الخدمة.'**
  String vehicleSelectedConnect(String name);

  /// No description provided for @inUse.
  ///
  /// In ar, this message translates to:
  /// **'قيد الاستخدام'**
  String get inUse;

  /// No description provided for @viewOnly.
  ///
  /// In ar, this message translates to:
  /// **'عرض فقط'**
  String get viewOnly;

  /// No description provided for @assignedToYou.
  ///
  /// In ar, this message translates to:
  /// **'معيّنة لك'**
  String get assignedToYou;

  /// No description provided for @errMotionUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.'**
  String get errMotionUnknown;

  /// No description provided for @errVehicleMoving.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تبديل المركبة وهي تتحرك. لم تُنقل الساعات.'**
  String get errVehicleMoving;

  /// No description provided for @errIdentifierMissing.
  ///
  /// In ar, this message translates to:
  /// **'الخادم لم يُرجع معرف المركبة. لن يُخترع معرف.'**
  String get errIdentifierMissing;

  /// No description provided for @errThresholdMissing.
  ///
  /// In ar, this message translates to:
  /// **'عتبة الحركة غير متوفرة من الإعداد.'**
  String get errThresholdMissing;

  /// No description provided for @errUnauthorized.
  ///
  /// In ar, this message translates to:
  /// **'غير مصرح لك بتشغيل هذه المركبة.'**
  String get errUnauthorized;

  /// No description provided for @errUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المركبة غير متاحة.'**
  String get errUnavailable;

  /// No description provided for @errInUse.
  ///
  /// In ar, this message translates to:
  /// **'المركبة قيد الاستخدام.'**
  String get errInUse;

  /// No description provided for @errRejected.
  ///
  /// In ar, this message translates to:
  /// **'رفض الخادم تشغيل المركبة.'**
  String get errRejected;

  /// No description provided for @errListUnreadable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة قائمة المركبات.'**
  String get errListUnreadable;

  /// No description provided for @nA.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get nA;

  /// No description provided for @email1.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email1;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @mainOfficeAddress.
  ///
  /// In ar, this message translates to:
  /// **'المكتب الرئيسي'**
  String get mainOfficeAddress;

  /// No description provided for @homeTerminalAddress.
  ///
  /// In ar, this message translates to:
  /// **'المحطة الرئيسية'**
  String get homeTerminalAddress;

  /// No description provided for @timeZone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get timeZone;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق'**
  String get language;

  /// No description provided for @languageUpdatedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث اللغة بنجاح'**
  String get languageUpdatedSuccessfully;

  /// No description provided for @odometerUnitUpdatedSuccessfull.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث وحدة المسافة بنجاح'**
  String get odometerUnitUpdatedSuccessfull;

  /// No description provided for @pleaseContactYourFleetManagerT.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الاتصال بمدير الأسطول لتغيير معلومات الحساب.'**
  String get pleaseContactYourFleetManagerT;

  /// No description provided for @thePacketIsIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'الحزمة غير مكتملة.'**
  String get thePacketIsIncomplete;

  /// No description provided for @inspectionMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التفتيش'**
  String get inspectionMode;

  /// No description provided for @dataTransferInstructionSheet.
  ///
  /// In ar, this message translates to:
  /// **'ورقة تعليمات نقل البيانات'**
  String get dataTransferInstructionSheet;

  /// No description provided for @malfunctionManual39534.
  ///
  /// In ar, this message translates to:
  /// **'دليل الأعطال (395.34)'**
  String get malfunctionManual39534;

  /// No description provided for @goldenFeatherEldInspectionMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التفتيش لـ Golden Feather ELD'**
  String get goldenFeatherEldInspectionMode;

  /// No description provided for @tapDotInspectionInTheMenuPress.
  ///
  /// In ar, this message translates to:
  /// **'اضغط \"وضع التفتيش\" في القائمة واضغط \"بدء التفتيش\". دع الضابط يعرض السجلات من جهازك. اعرض بطاقة التعليمات هذه إذا طلب.'**
  String get tapDotInspectionInTheMenuPress;

  /// No description provided for @anInspectorMayPressArrowsToVie.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للمفتش الضغط على الأسهم لعرض السجلات السابقة أو التالية.'**
  String get anInspectorMayPressArrowsToVie;

  /// No description provided for @theOfficerCannotLeaveInspectio.
  ///
  /// In ar, this message translates to:
  /// **'لا يخرج المفتش من وضع التفتيش. يخرج السائق بزر خروج السائق بعد إدخال كلمة مرور حسابه.'**
  String get theOfficerCannotLeaveInspectio;

  /// No description provided for @goldenFeatherEldIsCapableOfPro.
  ///
  /// In ar, this message translates to:
  /// **'جهاز Golden Feather ELD قادر على إنتاج ونقل سجلات ELD عبر طرق النقل التليماتية: الويب اللاسلكي والبريد الإلكتروني. لإرسال السجلات عبر الويب، اضغط زر \"DOT Inspection\" ثم \"Send Logs\". لإرسالها عبر البريد، اختر \"Email Logs\" وأدخل البريد.'**
  String get goldenFeatherEldIsCapableOfPro;

  /// No description provided for @goldenFeatherEldMalfunctionMan.
  ///
  /// In ar, this message translates to:
  /// **'دليل الأعطال لـ Golden Feather ELD'**
  String get goldenFeatherEldMalfunctionMan;

  /// No description provided for @inAccordanceWithTheGuidelinesS.
  ///
  /// In ar, this message translates to:
  /// **'وفقاً للإرشادات المحددة في 395.34'**
  String get inAccordanceWithTheGuidelinesS;

  /// No description provided for @malfunctionIndication.
  ///
  /// In ar, this message translates to:
  /// **'مؤشر العطل'**
  String get malfunctionIndication;

  /// No description provided for @immediatelyContactTheSupportIf.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بالدعم فوراً إذا انطفأ ضوء LED عند التوصيل بالمركبة أو إذا أبلغ التطبيق عن عطل.'**
  String get immediatelyContactTheSupportIf;

  /// No description provided for @noteTheMalfunction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل العطل'**
  String get noteTheMalfunction;

  /// No description provided for @noteTheMalfunctionAndProvideAW.
  ///
  /// In ar, this message translates to:
  /// **'سجل العطل وقدم إشعاراً خطياً لشركتك خلال 24 ساعة.'**
  String get noteTheMalfunctionAndProvideAW;

  /// No description provided for @switchToPaperLogs.
  ///
  /// In ar, this message translates to:
  /// **'التبديل للسجلات الورقية'**
  String get switchToPaperLogs;

  /// No description provided for @k8DaysRule.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة 8 أيام'**
  String get k8DaysRule;

  /// No description provided for @contactTheSupportTeamAtTopceld.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم عبر topceld@gmail.com'**
  String get contactTheSupportTeamAtTopceld;

  /// No description provided for @eldUserManual.
  ///
  /// In ar, this message translates to:
  /// **'دليل المستخدم'**
  String get eldUserManual;

  /// No description provided for @features.
  ///
  /// In ar, this message translates to:
  /// **'الميزات'**
  String get features;

  /// No description provided for @installationAndSetup.
  ///
  /// In ar, this message translates to:
  /// **'التثبيت والإعداد'**
  String get installationAndSetup;

  /// No description provided for @logManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة السجلات'**
  String get logManagement;

  /// No description provided for @roadsideInspections.
  ///
  /// In ar, this message translates to:
  /// **'تفتيش الطريق'**
  String get roadsideInspections;

  /// No description provided for @electronicDriverVehicleInspect.
  ///
  /// In ar, this message translates to:
  /// **'تقارير فحص المركبة (DVIR)'**
  String get electronicDriverVehicleInspect;

  /// No description provided for @fleetManagerPortal.
  ///
  /// In ar, this message translates to:
  /// **'بوابة مدير الأسطول'**
  String get fleetManagerPortal;

  /// No description provided for @electronicLoggingDeviceEld.
  ///
  /// In ar, this message translates to:
  /// **'جهاز التسجيل الإلكتروني (ELD)'**
  String get electronicLoggingDeviceEld;

  /// No description provided for @recordsOfNdutyStatus.
  ///
  /// In ar, this message translates to:
  /// **'سجلات حالة الخدمة'**
  String get recordsOfNdutyStatus;

  /// No description provided for @easilyManageYourDutyStatusChan.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحالات بسهولة مع إمكانية عرض، وتعديل، وتوقيع السجلات بدقة.'**
  String get easilyManageYourDutyStatusChan;

  /// No description provided for @availableHoursAndNrequiredBrea.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المتاحة\\nوالفترات المطلوبة'**
  String get availableHoursAndNrequiredBrea;

  /// No description provided for @stayInformedAboutYourAvailable.
  ///
  /// In ar, this message translates to:
  /// **'ابقَ على اطلاع بساعات القيادة المتاحة وفترات الراحة الإلزامية لضمان الامتثال.'**
  String get stayInformedAboutYourAvailable;

  /// No description provided for @interAndIntrastateNhosRules.
  ///
  /// In ar, this message translates to:
  /// **'قواعد HOS'**
  String get interAndIntrastateNhosRules;

  /// No description provided for @ourAppSupportsBothInterAndIntr.
  ///
  /// In ar, this message translates to:
  /// **'يدعم تطبيقنا قواعد القيادة بين الولايات وداخلها.'**
  String get ourAppSupportsBothInterAndIntr;

  /// No description provided for @roadsideInspectionNfunction.
  ///
  /// In ar, this message translates to:
  /// **'تفتيش الطريق'**
  String get roadsideInspectionNfunction;

  /// No description provided for @duringRoadsideInspectionsUseTh.
  ///
  /// In ar, this message translates to:
  /// **'أثناء التفتيش الأمني، استخدم وضع التفتيش في التطبيق لمشاركة السجلات.'**
  String get duringRoadsideInspectionsUseTh;

  /// No description provided for @vehicleInspectionNreports.
  ///
  /// In ar, this message translates to:
  /// **'تقارير فحص المركبة'**
  String get vehicleInspectionNreports;

  /// No description provided for @generatePreOrPostTripDvirsWith.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ تقارير DVIR قبل أو بعد الرحلة لإشعار الميكانيكيين بأي أعطال فوراً.'**
  String get generatePreOrPostTripDvirsWith;

  /// No description provided for @onlineFleetNmanagerPortal.
  ///
  /// In ar, this message translates to:
  /// **'بوابة مدير الأسطول'**
  String get onlineFleetNmanagerPortal;

  /// No description provided for @accessTheFleetManagerPortalToM.
  ///
  /// In ar, this message translates to:
  /// **'الوصول لبوابة المدير لمراقبة الامتثال وعرض البيانات في الوقت الفعلي.'**
  String get accessTheFleetManagerPortalToM;

  /// No description provided for @gpsTracking.
  ///
  /// In ar, this message translates to:
  /// **'تتبع GPS'**
  String get gpsTracking;

  /// No description provided for @trackYourVehicle.
  ///
  /// In ar, this message translates to:
  /// **'تتبع موقع مركبتك في الوقت الفعلي لتحسين الإدارة والأمان.'**
  String get trackYourVehicle;

  /// No description provided for @iftaCalculations.
  ///
  /// In ar, this message translates to:
  /// **'حسابات IFTA'**
  String get iftaCalculations;

  /// No description provided for @automaticallyCalculateIftaData.
  ///
  /// In ar, this message translates to:
  /// **'حساب بيانات IFTA آلياً لتبسيط تقارير ضرائب الوقود.'**
  String get automaticallyCalculateIftaData;

  /// No description provided for @setUpFleetNmanagerPortal.
  ///
  /// In ar, this message translates to:
  /// **'إعداد البوابة'**
  String get setUpFleetNmanagerPortal;

  /// No description provided for @useYourCredentialsToSignIntoTh.
  ///
  /// In ar, this message translates to:
  /// **'استخدم بيانات الدخول للوصول إلى البوابة وتوفير معلومات شركتك والسائقين.'**
  String get useYourCredentialsToSignIntoTh;

  /// No description provided for @monitorHosAndNfmcsaCompliance.
  ///
  /// In ar, this message translates to:
  /// **'مراقبة الامتثال'**
  String get monitorHosAndNfmcsaCompliance;

  /// No description provided for @stayOnTopOfDrivers.
  ///
  /// In ar, this message translates to:
  /// **'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.'**
  String get stayOnTopOfDrivers;

  /// No description provided for @preconfiguredStatuses.
  ///
  /// In ar, this message translates to:
  /// **'حالات مسبقة الإعداد'**
  String get preconfiguredStatuses;

  /// No description provided for @customizeDutyStatusesAccessByS.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص الوصول للحالات عبر تفعيل تحرك الساحة والاستخدام الشخصي كخيارات متاحة.'**
  String get customizeDutyStatusesAccessByS;

  /// No description provided for @driverAndVehicleInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات السائق والمركبة'**
  String get driverAndVehicleInformation;

  /// No description provided for @trackYourDrivers.
  ///
  /// In ar, this message translates to:
  /// **'تتبع موقع السائقين الحالي أو الأخير، المركبة، ومعلومات الاتصال بسهولة.'**
  String get trackYourDrivers;

  /// No description provided for @downloadAndTransferLogs.
  ///
  /// In ar, this message translates to:
  /// **'تحميل ونقل السجلات'**
  String get downloadAndTransferLogs;

  /// No description provided for @downloadAnyDrivers.
  ///
  /// In ar, this message translates to:
  /// **'حمل أي سجل للسائقين بصيغة PDF بنقرات قليلة. في حال التفتيش يمكن إرسالها بسهولة للضابط.'**
  String get downloadAnyDrivers;

  /// No description provided for @filterLogs.
  ///
  /// In ar, this message translates to:
  /// **'تصفية السجلات'**
  String get filterLogs;

  /// No description provided for @saveTimeByQuicklyFindingLogsBy.
  ///
  /// In ar, this message translates to:
  /// **'وفر الوقت بإيجاد السجلات بسرعة حسب التاريخ، السائق، أو المركبة باستخدام خيار التصفية.'**
  String get saveTimeByQuicklyFindingLogsBy;

  /// No description provided for @installEldHardware.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت الجهاز'**
  String get installEldHardware;

  /// No description provided for @beginByLocatingTheEcmDiagnosti.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:\\n\\n• وصلة 6-pin\\n• وصلة 9-pin\\n• وصلة OBDII\\n\\nبمجرد تحديد الوصلة، ركب الجهاز وثبته بإحكام.'**
  String get beginByLocatingTheEcmDiagnosti;

  /// No description provided for @installEldSoftware.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت البرنامج'**
  String get installEldSoftware;

  /// No description provided for @beforeYouStartUsingTheEldEnsur.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من أن جهازك متصل بالإنترنت والبلوتوث مفعل.\\n\\n• قم بتثبيت التطبيق.\\n• سجل الدخول ببياناتك.\\n• زامن الجهاز من خلال اختيار مركبتك من القائمة.'**
  String get beforeYouStartUsingTheEldEnsur;

  /// No description provided for @hoursOfService1.
  ///
  /// In ar, this message translates to:
  /// **'ساعات الخدمة'**
  String get hoursOfService1;

  /// No description provided for @onceTheEldIsSetUpItAutomatical.
  ///
  /// In ar, this message translates to:
  /// **'بمجرد الإعداد، يسجل الجهاز وقت القيادة آلياً، ويحسب الساعات المتاحة وفترات الراحة.'**
  String get onceTheEldIsSetUpItAutomatical;

  /// No description provided for @accessingLogs.
  ///
  /// In ar, this message translates to:
  /// **'الوصول للسجلات'**
  String get accessingLogs;

  /// No description provided for @logInToTheEldAppWithYourUnique.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدخول وانتقل لقسم \"السجلات\" للوصول للبيانات.'**
  String get logInToTheEldAppWithYourUnique;

  /// No description provided for @viewingLogs1.
  ///
  /// In ar, this message translates to:
  /// **'عرض السجلات'**
  String get viewingLogs1;

  /// No description provided for @viewDetailedRodsForDifferentDa.
  ///
  /// In ar, this message translates to:
  /// **'شاهد التفاصيل اليومية لكل تغيير حالة يتضمن الوقت والمدة والمكان.'**
  String get viewDetailedRodsForDifferentDa;

  /// No description provided for @editingLogs.
  ///
  /// In ar, this message translates to:
  /// **'تعديل السجلات'**
  String get editingLogs;

  /// No description provided for @editDutyStatusEntriesExceptFor.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الإدخالات (باستثناء وقت القيادة الآلي). اضغط على التاريخ وعدل واحفظ.'**
  String get editDutyStatusEntriesExceptFor;

  /// No description provided for @certifyingLogs.
  ///
  /// In ar, this message translates to:
  /// **'توقيع السجلات'**
  String get certifyingLogs;

  /// No description provided for @certifyingLogsEndYourShiftByDi.
  ///
  /// In ar, this message translates to:
  /// **'أنهِ ورديتك بتوقيع سجلاتك رقمياً للتأكيد على دقتها والامتثال بضغطة زر.'**
  String get certifyingLogsEndYourShiftByDi;

  /// No description provided for @duringARoadsideInspectionFollo.
  ///
  /// In ar, this message translates to:
  /// **'أثناء التفتيش الأمني، اتبع الخطوات:\\n\\n• ادخل لوضع تفتيش DOT من القائمة الرئيسية.\\n• اضغط \"بدء التفتيش\" لعرض سجلات (RODS) للضابط.\\n• استخدم أسهم التنقل لمراجعة السجلات حسب التاريخ.\\n• إذا طلب منك، أرسل السجلات عبر الويب أو البريد.\\n• بعد الانتهاء، اضغط \"رجوع\" للعودة.'**
  String get duringARoadsideInspectionFollo;

  /// No description provided for @hosComplianceAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الامتثال'**
  String get hosComplianceAlerts;

  /// No description provided for @stayCompliantWithHosRegulation.
  ///
  /// In ar, this message translates to:
  /// **'ابقَ ممتثلاً لمراقبة التنبيهات:\\n\\n• على شاشة السجلات الرئيسية، راقب الأيقونة الحمراء التي تشير لمخالفة HOS أو تحذير النموذج.\\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل عبر الضغط عليها.'**
  String get stayCompliantWithHosRegulation;

  /// No description provided for @createDvir.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فحص'**
  String get createDvir;

  /// No description provided for @createANewInspectionReportNNAc.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير فحص جديد:\\n\\n• افتح القائمة واختر DVIR.\\n• اضغط على علامة الزائد لبدء فحص جديد.\\n• راجع المكونات وحدد أي أعطال.\\n• أضف ملاحظات إذا لزم الأمر.\\n• اضغط توقيع للحفظ في السجل.'**
  String get createANewInspectionReportNNAc;

  /// No description provided for @editDvir.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفحص'**
  String get editDvir;

  /// No description provided for @editAnExistingReportNNGoToDvir.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تقرير سابق:\\n\\n• اذهب للسجل واختر التقرير.\\n• اضغط زر التعديل لإجراء التغييرات.'**
  String get editAnExistingReportNNGoToDvir;

  /// No description provided for @deleteDvir.
  ///
  /// In ar, this message translates to:
  /// **'حذف الفحص'**
  String get deleteDvir;

  /// No description provided for @deleteAnExistingReportNNInDvir.
  ///
  /// In ar, this message translates to:
  /// **'حذف تقرير سابق:\\n\\n• اذهب للسجل واختر التقرير.\\n• اضغط زر الحذف وتأكد.'**
  String get deleteAnExistingReportNNInDvir;

  /// No description provided for @infoPacketManualBlurb.
  ///
  /// In ar, this message translates to:
  /// **'يجوز أن يكون دليل المستخدم وورقة التعليمات وورقة تعليمات الأعطال بصيغة إلكترونية، وفق السجل الفيدرالي بعنوان \"إرشاد تنظيمي بشأن التوقيعات والمستندات الإلكترونية\" (76 FR 411).'**
  String get infoPacketManualBlurb;

  /// No description provided for @infoPacketInstructionsBlurb.
  ///
  /// In ar, this message translates to:
  /// **'بالإضافة إلى ما سبق، يجب أن تكون في المركبة التجارية نماذج فارغة لسجلات حالة الخدمة (RODS) تكفي لتسجيل حالة السائق والمعلومات ذات الصلة لمدة لا تقل عن 8 أيام.'**
  String get infoPacketInstructionsBlurb;

  /// No description provided for @packetIncompleteMissing.
  ///
  /// In ar, this message translates to:
  /// **'الحزمة غير مكتملة: {missing}'**
  String packetIncompleteMissing(String missing);

  /// No description provided for @recordsOfDutyStatus.
  ///
  /// In ar, this message translates to:
  /// **'سجلات حالة الخدمة'**
  String get recordsOfDutyStatus;

  /// No description provided for @availableHoursAndRequiredBreaks.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المتاحة\nوالفترات المطلوبة'**
  String get availableHoursAndRequiredBreaks;

  /// No description provided for @interAndIntrastateHosRules.
  ///
  /// In ar, this message translates to:
  /// **'قواعد HOS'**
  String get interAndIntrastateHosRules;

  /// No description provided for @roadsideInspectionFunction.
  ///
  /// In ar, this message translates to:
  /// **'تفتيش الطريق'**
  String get roadsideInspectionFunction;

  /// No description provided for @vehicleInspectionReports.
  ///
  /// In ar, this message translates to:
  /// **'تقارير فحص المركبة'**
  String get vehicleInspectionReports;

  /// No description provided for @onlineFleetManagerPortal.
  ///
  /// In ar, this message translates to:
  /// **'بوابة مدير الأسطول'**
  String get onlineFleetManagerPortal;

  /// No description provided for @trackYourVehicleSLocationIn.
  ///
  /// In ar, this message translates to:
  /// **'تتبع موقع مركبتك في الوقت الفعلي لتحسين الإدارة والأمان.'**
  String get trackYourVehicleSLocationIn;

  /// No description provided for @setUpFleetManagerPortal.
  ///
  /// In ar, this message translates to:
  /// **'إعداد البوابة'**
  String get setUpFleetManagerPortal;

  /// No description provided for @monitorHosAndFmcsaCompliance.
  ///
  /// In ar, this message translates to:
  /// **'مراقبة الامتثال'**
  String get monitorHosAndFmcsaCompliance;

  /// No description provided for @stayOnTopOfDriversDuty.
  ///
  /// In ar, this message translates to:
  /// **'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.'**
  String get stayOnTopOfDriversDuty;

  /// No description provided for @trackYourDriversCurrentOrLast.
  ///
  /// In ar, this message translates to:
  /// **'تتبع موقع السائقين الحالي أو الأخير، المركبة، ومعلومات الاتصال بسهولة.'**
  String get trackYourDriversCurrentOrLast;

  /// No description provided for @downloadAnyDriversLogsInPdf.
  ///
  /// In ar, this message translates to:
  /// **'حمل أي سجل للسائقين بصيغة PDF بنقرات قليلة. في حال التفتيش يمكن إرسالها بسهولة للضابط.'**
  String get downloadAnyDriversLogsInPdf;

  /// No description provided for @beginByLocatingTheEcmDiagnostic.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:\n\n• وصلة 6-pin\n• وصلة 9-pin\n• وصلة OBDII\n\nبمجرد تحديد الوصلة، ركب الجهاز وثبته بإحكام.'**
  String get beginByLocatingTheEcmDiagnostic;

  /// No description provided for @beforeYouStartUsingTheEld.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من أن جهازك متصل بالإنترنت والبلوتوث مفعل.\n\n• قم بتثبيت التطبيق.\n• سجل الدخول ببياناتك.\n• زامن الجهاز من خلال اختيار مركبتك من القائمة.'**
  String get beforeYouStartUsingTheEld;

  /// No description provided for @onceTheEldIsSetUp.
  ///
  /// In ar, this message translates to:
  /// **'بمجرد الإعداد، يسجل الجهاز وقت القيادة آلياً، ويحسب الساعات المتاحة وفترات الراحة.'**
  String get onceTheEldIsSetUp;

  /// No description provided for @duringARoadsideInspectionFollowThese.
  ///
  /// In ar, this message translates to:
  /// **'أثناء التفتيش الأمني، اتبع الخطوات:\n\n• ادخل لوضع تفتيش DOT من القائمة الرئيسية.\n• اضغط \"بدء التفتيش\" لعرض سجلات (RODS) للضابط.\n• استخدم أسهم التنقل لمراجعة السجلات حسب التاريخ.\n• إذا طلب منك، أرسل السجلات عبر الويب أو البريد.\n• بعد الانتهاء، اضغط \"رجوع\" للعودة.'**
  String get duringARoadsideInspectionFollowThese;

  /// No description provided for @stayCompliantWithHosRegulationsBy.
  ///
  /// In ar, this message translates to:
  /// **'ابقَ ممتثلاً لمراقبة التنبيهات:\n\n• على شاشة السجلات الرئيسية، راقب الأيقونة الحمراء التي تشير لمخالفة HOS أو تحذير النموذج.\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل عبر الضغط عليها.'**
  String get stayCompliantWithHosRegulationsBy;

  /// No description provided for @createANewInspectionReportAccess.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير فحص جديد:\n\n• افتح القائمة واختر DVIR.\n• اضغط على علامة الزائد لبدء فحص جديد.\n• راجع المكونات وحدد أي أعطال.\n• أضف ملاحظات إذا لزم الأمر.\n• اضغط توقيع للحفظ في السجل.'**
  String get createANewInspectionReportAccess;

  /// No description provided for @editAnExistingReportGoTo.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر التعديل لإجراء التغييرات.'**
  String get editAnExistingReportGoTo;

  /// No description provided for @deleteAnExistingReportInDvir.
  ///
  /// In ar, this message translates to:
  /// **'حذف تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر الحذف وتأكد.'**
  String get deleteAnExistingReportInDvir;

  /// No description provided for @pleaseContactYourFleetManagerTo.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الاتصال بمدير الأسطول لتغيير معلومات الحساب.'**
  String get pleaseContactYourFleetManagerTo;

  /// No description provided for @todayLogDate.
  ///
  /// In ar, this message translates to:
  /// **'اليوم - {date}'**
  String todayLogDate(Object date);

  /// No description provided for @enterTheTrailerNumber.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم المقطورة.'**
  String get enterTheTrailerNumber;

  /// No description provided for @trailerNumberMustBeLettersNumbers.
  ///
  /// In ar, this message translates to:
  /// **'رقم المقطورة: أحرف وأرقام وشرطات فقط (حتى 50).'**
  String get trailerNumberMustBeLettersNumbers;

  /// No description provided for @enterTheDocumentNumber.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم المستند.'**
  String get enterTheDocumentNumber;

  /// No description provided for @shippingDocumentNumberIsTooLong.
  ///
  /// In ar, this message translates to:
  /// **'رقم مستند الشحن طويل جداً (حتى 100).'**
  String get shippingDocumentNumberIsTooLong;

  /// No description provided for @enterOneDocumentAtATime.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مستنداً واحداً في كل مرة (بدون فاصلة).'**
  String get enterOneDocumentAtATime;

  /// No description provided for @reasonForChange.
  ///
  /// In ar, this message translates to:
  /// **'سبب التعديل'**
  String get reasonForChange;

  /// No description provided for @enterReasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل السبب (مطلوب)'**
  String get enterReasonRequired;

  /// No description provided for @aReasonForTheChangeIs.
  ///
  /// In ar, this message translates to:
  /// **'سبب التعديل مطلوب.'**
  String get aReasonForTheChangeIs;

  /// No description provided for @cannotSaveDriverSessionNotFound.
  ///
  /// In ar, this message translates to:
  /// **'جلسة السائق غير موجودة. لا يمكن الحفظ.'**
  String get cannotSaveDriverSessionNotFound;

  /// No description provided for @automaticDrivingTimeCannotBeShortened.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تقصير أو حذف وقت القيادة الآلي.'**
  String get automaticDrivingTimeCannotBeShortened;

  /// No description provided for @eventSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الحدث بنجاح'**
  String get eventSavedSuccessfully;

  /// No description provided for @reCertificationRequiredEditsWereMade.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إعادة الاعتماد: حدثت تعديلات بعد آخر توقيع.'**
  String get reCertificationRequiredEditsWereMade;

  /// No description provided for @typeHere.
  ///
  /// In ar, this message translates to:
  /// **'اكتب هنا'**
  String get typeHere;

  /// No description provided for @noDocumentsAdded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستندات'**
  String get noDocumentsAdded;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @carrierProposedEdits39530Are.
  ///
  /// In ar, this message translates to:
  /// **'تعديلات الناقل المقترحة (§395.30) تُراجَع داخل كل سجل في تبويب Certify (قبول / رفض).'**
  String get carrierProposedEdits39530Are;

  /// No description provided for @unidentifiedDrivingIsReviewedInUnidentified.
  ///
  /// In ar, this message translates to:
  /// **'القيادة غير المحددة تُراجَع في شاشة الأحداث غير المحددة.'**
  String get unidentifiedDrivingIsReviewedInUnidentified;

  /// No description provided for @noTrailersAdded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مقطورات'**
  String get noTrailersAdded;

  /// No description provided for @noVehicleIsSelected.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مركبة محددة.'**
  String get noVehicleIsSelected;

  /// No description provided for @anAnnotationIsRequired.
  ///
  /// In ar, this message translates to:
  /// **'التعليق مطلوب.'**
  String get anAnnotationIsRequired;

  /// No description provided for @yourRecordWasUpdatedReviewThe.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث سجلك. راجع السجل اليومي؛ قد يلزم إعادة التصديق.'**
  String get yourRecordWasUpdatedReviewThe;

  /// No description provided for @assume.
  ///
  /// In ar, this message translates to:
  /// **'افتراض'**
  String get assume;

  /// No description provided for @requiredAnnotationThisTimeIsAssumed.
  ///
  /// In ar, this message translates to:
  /// **'التعليق مطلوب. تُحتسب هذه المدة قيادة.'**
  String get requiredAnnotationThisTimeIsAssumed;

  /// No description provided for @notMine.
  ///
  /// In ar, this message translates to:
  /// **'ليست لي'**
  String get notMine;

  /// No description provided for @requiredRejectionReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض مطلوب'**
  String get requiredRejectionReason;

  /// No description provided for @overdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get overdue;

  /// No description provided for @originalRecordPreserved.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الأصلية محفوظة'**
  String get originalRecordPreserved;

  /// No description provided for @byDate.
  ///
  /// In ar, this message translates to:
  /// **'حسب التاريخ…'**
  String get byDate;

  /// No description provided for @currentVehicleOnly.
  ///
  /// In ar, this message translates to:
  /// **'المركبة الحالية فقط'**
  String get currentVehicleOnly;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح التصفية'**
  String get clearFilters;

  /// No description provided for @currentVehicle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة الحالية'**
  String get currentVehicle;

  /// No description provided for @responseWasInterrupted.
  ///
  /// In ar, this message translates to:
  /// **'انقطعت العملية. أعد المحاولة.'**
  String get responseWasInterrupted;

  /// No description provided for @pleaseDrawASignatureFirst.
  ///
  /// In ar, this message translates to:
  /// **'ارسم التوقيع أولاً.'**
  String get pleaseDrawASignatureFirst;

  /// No description provided for @logSuccessfullyCertified.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد السجل.'**
  String get logSuccessfullyCertified;

  /// No description provided for @notReadyForCertification.
  ///
  /// In ar, this message translates to:
  /// **'غير جاهز للاعتماد'**
  String get notReadyForCertification;

  /// No description provided for @pleaseResolveTheFollowingIssuesBefore.
  ///
  /// In ar, this message translates to:
  /// **'عالج النواقص التالية قبل اعتماد السجل:'**
  String get pleaseResolveTheFollowingIssuesBefore;

  /// No description provided for @carrierEditsMustBeAcceptedOr.
  ///
  /// In ar, this message translates to:
  /// **'تعديلات الناقل بانتظار ردك قبل الاعتماد.'**
  String get carrierEditsMustBeAcceptedOr;

  /// No description provided for @carrierEditAcceptedReCertifyThe.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول تعديل الناقل. أعد التصديق.'**
  String get carrierEditAcceptedReCertifyThe;

  /// No description provided for @carrierEditRejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض تعديل الناقل.'**
  String get carrierEditRejected;

  /// No description provided for @sessionMissingPleaseLogInAgain.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول مرة أخرى.'**
  String get sessionMissingPleaseLogInAgain;

  /// No description provided for @carrierProposedEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل من الناقل'**
  String get carrierProposedEdit;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get accept;

  /// No description provided for @selectAVehicleBeforeSavingThe.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المركبة قبل حفظ النموذج.'**
  String get selectAVehicleBeforeSavingThe;

  /// No description provided for @coDriverMustBeAServer.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون السائق المساعد صالحاً قبل الحفظ.'**
  String get coDriverMustBeAServer;

  /// No description provided for @keepAPaperLogForThatDayAndUnti.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ بسجل ورقي لذلك اليوم وحتى يتم إصلاح الجهاز. في حال التفتيش، اعرض الأيام السبعة السابقة من التطبيق.'**
  String get keepAPaperLogForThatDayAndUnti;

  /// No description provided for @inTheEventOfAnEldMalfunctionTh.
  ///
  /// In ar, this message translates to:
  /// **'في حال عطل ELD، يجب على الشركة اتخاذ إجراءات لإصلاح العطل خلال 8 أيام من اكتشافه.'**
  String get inTheEventOfAnEldMalfunctionTh;

  /// No description provided for @anInspectorMayViewTheLogFormTh.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للمفتش عرض نموذج السجل، المخطط الشبكي، والأحداث مع الملاحظات.'**
  String get anInspectorMayViewTheLogFormTh;

  /// No description provided for @theEventCouldNotBeSaved.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الحدث.'**
  String get theEventCouldNotBeSaved;

  /// No description provided for @theEventWasSavedButThe.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الحدث لكن تعذر تسجيل سبب التعديل.'**
  String get theEventWasSavedButThe;

  /// No description provided for @transferAuditTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل نقل السجلات'**
  String get transferAuditTitle;

  /// No description provided for @noTransfersFromServer.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات نقل في رد الخادم.'**
  String get noTransfersFromServer;

  /// No description provided for @transferAuditNotLoaded.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة سجل النقل: {error}'**
  String transferAuditNotLoaded(Object error);

  /// No description provided for @driving24h.
  ///
  /// In ar, this message translates to:
  /// **'قيادة 24 ساعة'**
  String get driving24h;

  /// No description provided for @pendingDays.
  ///
  /// In ar, this message translates to:
  /// **'معلّق {days} يوم'**
  String pendingDays(Object days);

  /// No description provided for @enterTrailerNumber.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم المقطورة.'**
  String get enterTrailerNumber;

  /// No description provided for @trailerNumberFormatError.
  ///
  /// In ar, this message translates to:
  /// **'رقم المقطورة: أحرف وأرقام وشرطات فقط (حتى 50).'**
  String get trailerNumberFormatError;

  /// No description provided for @enterDocumentNumber.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم المستند.'**
  String get enterDocumentNumber;

  /// No description provided for @documentNumberTooLong.
  ///
  /// In ar, this message translates to:
  /// **'رقم مستند الشحن طويل جداً (حتى 100).'**
  String get documentNumberTooLong;

  /// No description provided for @oneDocumentAtATime.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مستنداً واحداً في كل مرة (بدون فاصلة).'**
  String get oneDocumentAtATime;

  /// No description provided for @selectVehicleBeforeSavingForm.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المركبة قبل حفظ النموذج.'**
  String get selectVehicleBeforeSavingForm;

  /// No description provided for @coDriverMustBeServerId.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون السائق المساعد صالحاً قبل الحفظ.'**
  String get coDriverMustBeServerId;

  /// No description provided for @serverSavedFormIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الخادم النموذج وتركه غير مكتمل.'**
  String get serverSavedFormIncomplete;

  /// No description provided for @serverSavedFormNoStatus.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الخادم النموذج ولم يُرجع حالة الاكتمال.'**
  String get serverSavedFormNoStatus;

  /// No description provided for @responseInterrupted.
  ///
  /// In ar, this message translates to:
  /// **'انقطعت العملية. أعد المحاولة.'**
  String get responseInterrupted;

  /// No description provided for @drawSignatureFirst.
  ///
  /// In ar, this message translates to:
  /// **'ارسم التوقيع أولاً.'**
  String get drawSignatureFirst;

  /// No description provided for @drawYourSignatureHere.
  ///
  /// In ar, this message translates to:
  /// **'ارسم توقيعك هنا'**
  String get drawYourSignatureHere;

  /// No description provided for @certifyLegalStatement.
  ///
  /// In ar, this message translates to:
  /// **'أشهد بموجب هذا أن إدخالات بياناتي وسجل حالة الواجب الخاص بي لمدة 24 ساعة صحيحة ودقيقة.'**
  String get certifyLegalStatement;

  /// No description provided for @errNoInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.'**
  String get errNoInternet;

  /// No description provided for @errRequestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال الطلب. أعد المحاولة.'**
  String get errRequestFailed;

  /// No description provided for @errRequestFailedNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال الطلب. تحقق من الشبكة ثم أعد المحاولة.'**
  String get errRequestFailedNetwork;

  /// No description provided for @errCannotReachServer.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم. تحقق من الشبكة ثم أعد المحاولة.'**
  String get errCannotReachServer;

  /// No description provided for @errServerRejected.
  ///
  /// In ar, this message translates to:
  /// **'الخادم رفض الطلب.'**
  String get errServerRejected;

  /// No description provided for @errSessionExpiredAction.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول مرة أخرى.'**
  String get errSessionExpiredAction;

  /// No description provided for @errPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية لهذا الإجراء.'**
  String get errPermissionDenied;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر غير موجود على الخادم.'**
  String get errNotFound;

  /// No description provided for @errServerError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم. أعد المحاولة.'**
  String get errServerError;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال الطلب.'**
  String get errGeneric;

  /// No description provided for @enterAReasonForManualRecording.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سبب التسجيل اليدوي.'**
  String get enterAReasonForManualRecording;

  /// No description provided for @couldNotUpdateManualRecordingM.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث وضع التسجيل اليدوي. أعد المحاولة.'**
  String get couldNotUpdateManualRecordingM;

  /// No description provided for @unableToConnectToEld.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بجهاز ELD.'**
  String get unableToConnectToEld;

  /// No description provided for @checkBluetoothAndRetry.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من تشغيل الجهاز والبلوتوث ثم أعد المحاولة.'**
  String get checkBluetoothAndRetry;

  /// No description provided for @checkNetworkAndRetry.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الشبكة والجهاز ثم أعد المحاولة.'**
  String get checkNetworkAndRetry;

  /// No description provided for @driverSessionMissingSignIn.
  ///
  /// In ar, this message translates to:
  /// **'جلسة السائق غير موجودة. سجّل الدخول قبل التفتيش.'**
  String get driverSessionMissingSignIn;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ar, this message translates to:
  /// **'ساعاتك تُسجَّل تلقائياً'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In ar, this message translates to:
  /// **'يتتبع جهاز ELD حالة قيادتك مقابل حدود FMCSA لحظة تحرك المركبة — بلا أوراق وبلا تخمين.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ar, this message translates to:
  /// **'افحص مركبتك بثقة'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In ar, this message translates to:
  /// **'فحص يومي قبل وبعد الرحلة، تتبع العيوب مع شهادات الإصلاح، ومراجعة §396.13 — كل ذلك في مكان واحد.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للمفتش دائماً'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In ar, this message translates to:
  /// **'سجلاتك وحزمتك القانونية وخيارات النقل على متن الجهاز — حتى بلا إنترنت على الطريق.'**
  String get onboardingBody3;

  /// No description provided for @startedOnDate.
  ///
  /// In ar, this message translates to:
  /// **'بدأ: {date}'**
  String startedOnDate(Object date);

  /// No description provided for @tableTimeEt.
  ///
  /// In ar, this message translates to:
  /// **'الوقت ET'**
  String get tableTimeEt;

  /// No description provided for @certEventStatus.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد · {status}'**
  String certEventStatus(Object status);

  /// No description provided for @eventCodeNote.
  ///
  /// In ar, this message translates to:
  /// **'الرمز: {code}'**
  String eventCodeNote(Object code);

  /// No description provided for @originNote.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: {origin}'**
  String originNote(Object origin);

  /// No description provided for @notesNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات: {notes}'**
  String notesNote(Object notes);

  /// No description provided for @inspectionCommentErrorLength.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون التعليق بين 4 و60 حرفاً.'**
  String get inspectionCommentErrorLength;

  /// No description provided for @enterValidEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريداً صالحاً.'**
  String get enterValidEmail;

  /// No description provided for @transferAccepted.
  ///
  /// In ar, this message translates to:
  /// **'قبل الخادم طلب النقل.'**
  String get transferAccepted;

  /// No description provided for @sendLogsViaEmail.
  ///
  /// In ar, this message translates to:
  /// **'إرسال السجلات عبر البريد'**
  String get sendLogsViaEmail;

  /// No description provided for @send8Logs.
  ///
  /// In ar, this message translates to:
  /// **'إرسال 8 سجلات'**
  String get send8Logs;

  /// No description provided for @recipientEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد المستلم'**
  String get recipientEmail;

  /// No description provided for @comment.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get comment;

  /// No description provided for @dataTransferType.
  ///
  /// In ar, this message translates to:
  /// **'نوع نقل البيانات'**
  String get dataTransferType;

  /// No description provided for @sendAction.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get sendAction;

  /// No description provided for @inspectLogs24.
  ///
  /// In ar, this message translates to:
  /// **'افحص سجلات فترة 24 ساعة والأيام السابقة لدورة واحدة'**
  String get inspectLogs24;

  /// No description provided for @setPinGuidance.
  ///
  /// In ar, this message translates to:
  /// **'اختر «بدء التفتيش» وسلّم الجهاز للضابط'**
  String get setPinGuidance;

  /// No description provided for @eldCertifies.
  ///
  /// In ar, this message translates to:
  /// **'يشهد التطبيق أن استخدامه مع الجهاز يستوفي متطلبات ELD في 49 CFR part 395 Subpart B.'**
  String get eldCertifies;

  /// No description provided for @notAllowedByServer.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح لهذا الحساب حسب الخادم.'**
  String get notAllowedByServer;

  /// No description provided for @startInspectionUpper.
  ///
  /// In ar, this message translates to:
  /// **'بدء التفتيش'**
  String get startInspectionUpper;

  /// No description provided for @serverDoesNotAllow.
  ///
  /// In ar, this message translates to:
  /// **'الخادم لا يسمح ببدء التفتيش الآن.'**
  String get serverDoesNotAllow;

  /// No description provided for @sendLogsFor24.
  ///
  /// In ar, this message translates to:
  /// **'أرسل السجلات لفترة 24 ساعة والأيام السابقة لدورة واحدة'**
  String get sendLogsFor24;

  /// No description provided for @sendLogsToOfficer.
  ///
  /// In ar, this message translates to:
  /// **'أرسل سجلاتك للضابط إذا طلب ذلك'**
  String get sendLogsToOfficer;

  /// No description provided for @sendLogsUpper.
  ///
  /// In ar, this message translates to:
  /// **'إرسال السجلات'**
  String get sendLogsUpper;

  /// No description provided for @emailLogs24Pdf.
  ///
  /// In ar, this message translates to:
  /// **'أرسل السجلات بالبريد لفترة 24 ساعة والأيام السابقة كملف PDF'**
  String get emailLogs24Pdf;

  /// No description provided for @emailLogsPdf.
  ///
  /// In ar, this message translates to:
  /// **'أرسل سجلاتك بصيغة PDF'**
  String get emailLogsPdf;

  /// No description provided for @emailLogsUpper.
  ///
  /// In ar, this message translates to:
  /// **'بريد السجلات'**
  String get emailLogsUpper;

  /// No description provided for @infoPacketUpper.
  ///
  /// In ar, this message translates to:
  /// **'حزمة المعلومات'**
  String get infoPacketUpper;

  /// No description provided for @inspectionPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز التفتيش'**
  String get inspectionPinTitle;

  /// No description provided for @enter4Digits.
  ///
  /// In ar, this message translates to:
  /// **'الرمز يجب أن يكون 4 أرقام.'**
  String get enter4Digits;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان غير متطابقين.'**
  String get pinsDoNotMatch;

  /// No description provided for @pinLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get pinLabel;

  /// No description provided for @confirmPinLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get confirmPinLabel;

  /// No description provided for @cancelAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelAction;

  /// No description provided for @enterInspectionPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التفتيش.'**
  String get enterInspectionPin;

  /// No description provided for @incorrectPin.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح.'**
  String get incorrectPin;

  /// No description provided for @driverExit.
  ///
  /// In ar, this message translates to:
  /// **'خروج السائق'**
  String get driverExit;

  /// No description provided for @exitAction.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get exitAction;

  /// No description provided for @enterNewPinOfficer.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التفتيش الجديد الذي سيتم إعطاؤه للضابط'**
  String get enterNewPinOfficer;

  /// No description provided for @enterSamePinToExit.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز نفسه للخروج من وضع التفتيش'**
  String get enterSamePinToExit;

  /// No description provided for @setPinGuidanceDialog.
  ///
  /// In ar, this message translates to:
  /// **'عيّن رمزاً من 4 أرقام لقفل الشاشة. المفتش يرى السجلات فقط ولا يخرج إلا بكلمة مرور السائق.'**
  String get setPinGuidanceDialog;

  /// No description provided for @enterPinToExitGuidance.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التفتيش الذي عيّنته عند البدء. المفتش لا يخرج من هنا.'**
  String get enterPinToExitGuidance;

  /// No description provided for @menuTitle.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get menuTitle;

  /// No description provided for @vehicleInMotionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة في حالة حركة'**
  String get vehicleInMotionTitle;

  /// No description provided for @vehicleInMotionDesc.
  ///
  /// In ar, this message translates to:
  /// **'التزاماً بقواعد السلامة المرورية ولوائح FMCSA، يتم حظر استخدام التطبيق أثناء القيادة. ستتم استعادة الواجهة فور توقف المركبة.'**
  String get vehicleInMotionDesc;

  /// No description provided for @weakConnectionDelayedData.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال ضعيف. قد تتأخر بعض البيانات.'**
  String get weakConnectionDelayedData;

  /// No description provided for @noInternetConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت.'**
  String get noInternetConnection;

  /// No description provided for @connectionStatusUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حالة الاتصال غير معروفة.'**
  String get connectionStatusUnknown;

  /// No description provided for @driveLimitFormat.
  ///
  /// In ar, this message translates to:
  /// **'حد القيادة {drive} ساعة'**
  String driveLimitFormat(String drive);

  /// No description provided for @shiftLimitFormat.
  ///
  /// In ar, this message translates to:
  /// **'حد الخدمة {shift} ساعة'**
  String shiftLimitFormat(String shift);

  /// No description provided for @breakLimitFormat.
  ///
  /// In ar, this message translates to:
  /// **'استراحة {rest} دقيقة'**
  String breakLimitFormat(String rest);

  /// No description provided for @usedFormat.
  ///
  /// In ar, this message translates to:
  /// **'{description} · مستخدم'**
  String usedFormat(String description);

  /// No description provided for @noticeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه'**
  String get noticeTitle;

  /// No description provided for @gpsTurnedOff.
  ///
  /// In ar, this message translates to:
  /// **'نظام تحديد المواقع مغلق.'**
  String get gpsTurnedOff;

  /// No description provided for @serverReportsEldAlert.
  ///
  /// In ar, this message translates to:
  /// **'الخادم يبلّغ عن تنبيه تشغيلي في جهاز ELD. افتح شاشة الاتصال للتفاصيل.'**
  String get serverReportsEldAlert;

  /// No description provided for @operationalAlertTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه تشغيلي'**
  String get operationalAlertTooltip;

  /// No description provided for @noInternetBanner.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد إنترنت. يمكنك المتابعة وعرض البيانات المحفوظة.'**
  String get noInternetBanner;

  /// No description provided for @dvirSatisfactory.
  ///
  /// In ar, this message translates to:
  /// **'حالة المركبة مرضية'**
  String get dvirSatisfactory;

  /// No description provided for @dvirHasDefects.
  ///
  /// In ar, this message translates to:
  /// **'توجد عيوب'**
  String get dvirHasDefects;

  /// No description provided for @dvirDefectsCorrected.
  ///
  /// In ar, this message translates to:
  /// **'تم إصلاح العيوب'**
  String get dvirDefectsCorrected;

  /// No description provided for @dvirDefectsNotCorrected.
  ///
  /// In ar, this message translates to:
  /// **'العيوب لا تستوجب الإصلاح'**
  String get dvirDefectsNotCorrected;

  /// No description provided for @dvirDefectRecorded.
  ///
  /// In ar, this message translates to:
  /// **'— يوجد عيب مسجّل'**
  String get dvirDefectRecorded;

  /// No description provided for @dvirNoRepairCert.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تصديق إصلاح بعد'**
  String get dvirNoRepairCert;

  /// No description provided for @dvirSetByCarrier.
  ///
  /// In ar, this message translates to:
  /// **'يحدّدها الناقل لا السائق'**
  String get dvirSetByCarrier;

  /// No description provided for @dvirTimeUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'وقت الفحص غير متاح. اتصل ثم أعد المحاولة.'**
  String get dvirTimeUnavailable;

  /// No description provided for @dvirSavedCannotEdit.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تعديل تقرير محفوظ من هذا الجهاز.'**
  String get dvirSavedCannotEdit;

  /// No description provided for @dvirSignatureRequired.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع مطلوب.'**
  String get dvirSignatureRequired;

  /// No description provided for @dvirDriverSessionMissing.
  ///
  /// In ar, this message translates to:
  /// **'جلسة السائق مفقودة. سجّل الدخول مجدداً قبل التوقيع.'**
  String get dvirDriverSessionMissing;

  /// No description provided for @dvirVehicleIdMissing.
  ///
  /// In ar, this message translates to:
  /// **'معرّف المركبة مفقود. اختر مركبة قبل التوقيع.'**
  String get dvirVehicleIdMissing;

  /// No description provided for @dvirPrevNoServerId.
  ///
  /// In ar, this message translates to:
  /// **'التقرير السابق بلا معرّف خادم ولا يمكن مراجعته.'**
  String get dvirPrevNoServerId;

  /// No description provided for @dvirPreviousInspection.
  ///
  /// In ar, this message translates to:
  /// **'الفحص السابق'**
  String get dvirPreviousInspection;

  /// No description provided for @dvirReviewBeforeDriving.
  ///
  /// In ar, this message translates to:
  /// **'راجع التقرير السابق ووقّع عليه قبل القيادة.'**
  String get dvirReviewBeforeDriving;

  /// No description provided for @dvirRecordedDefects.
  ///
  /// In ar, this message translates to:
  /// **'العيوب المسجّلة:'**
  String get dvirRecordedDefects;

  /// No description provided for @dvirNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عيوب.'**
  String get dvirNone;

  /// No description provided for @dvirRepairStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الإصلاح: '**
  String get dvirRepairStatus;

  /// No description provided for @dvirReviewed.
  ///
  /// In ar, this message translates to:
  /// **'تمت المراجعة'**
  String get dvirReviewed;

  /// No description provided for @dvirLocationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الموقع غير متاح'**
  String get dvirLocationUnavailable;

  /// No description provided for @dvirCompanyUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الشركة غير متاحة'**
  String get dvirCompanyUnavailable;

  /// No description provided for @dvirTimeUnavailableShort.
  ///
  /// In ar, this message translates to:
  /// **'الوقت غير متاح'**
  String get dvirTimeUnavailableShort;

  /// No description provided for @dvirInsertDvir.
  ///
  /// In ar, this message translates to:
  /// **'إدراج تقرير فحص (DVIR)'**
  String get dvirInsertDvir;

  /// No description provided for @dvirPreviousReviewNotice.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة التقرير السابق — فتح التقرير لا يعد مراجعة له.'**
  String get dvirPreviousReviewNotice;

  /// No description provided for @dvirTimeET.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get dvirTimeET;

  /// No description provided for @dvirOdometerMi.
  ///
  /// In ar, this message translates to:
  /// **'المسافة'**
  String get dvirOdometerMi;

  /// No description provided for @dvirOdometerHint.
  ///
  /// In ar, this message translates to:
  /// **'المسافة'**
  String get dvirOdometerHint;

  /// No description provided for @company.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get company;

  /// No description provided for @remarks.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get remarks;

  /// No description provided for @dvirImageNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الصورة غير متاحة'**
  String get dvirImageNotAvailable;

  /// No description provided for @dvirClearSignature.
  ///
  /// In ar, this message translates to:
  /// **'مسح التوقيع'**
  String get dvirClearSignature;

  /// No description provided for @dvirSigned.
  ///
  /// In ar, this message translates to:
  /// **'تم التوقيع'**
  String get dvirSigned;

  /// No description provided for @dvirSign.
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get dvirSign;

  /// No description provided for @removeAction.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get removeAction;

  /// No description provided for @addDefects.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عيوب'**
  String get addDefects;

  /// No description provided for @dvirDefects396_11.
  ///
  /// In ar, this message translates to:
  /// **'العيوب (§396.11)'**
  String get dvirDefects396_11;

  /// No description provided for @dvirLoadDefectsFail.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قائمة العيوب من الخادم.'**
  String get dvirLoadDefectsFail;

  /// No description provided for @retryAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryAction;

  /// No description provided for @dvirCatalogEmpty.
  ///
  /// In ar, this message translates to:
  /// **'القائمة فارغة.'**
  String get dvirCatalogEmpty;

  /// No description provided for @dvirSafetyAffecting.
  ///
  /// In ar, this message translates to:
  /// **'يؤثر على السلامة'**
  String get dvirSafetyAffecting;

  /// No description provided for @dvirDescriptionOptional.
  ///
  /// In ar, this message translates to:
  /// **'وصف (اختياري)'**
  String get dvirDescriptionOptional;

  /// No description provided for @eldDiagnosticReading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة حالة الاتصال...'**
  String get eldDiagnosticReading;

  /// No description provided for @eldDiagnosticDiagnosticFormat.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص: {diagnostics}'**
  String eldDiagnosticDiagnosticFormat(String diagnostics);

  /// No description provided for @eldDiagnosticMalfunctionFormat.
  ///
  /// In ar, this message translates to:
  /// **'عطل: {malfunctions}'**
  String eldDiagnosticMalfunctionFormat(String malfunctions);

  /// No description provided for @eldDiagnosticLastValidDataFormat.
  ///
  /// In ar, this message translates to:
  /// **'آخر بيانات صالحة: {lastHeartbeat}'**
  String eldDiagnosticLastValidDataFormat(String lastHeartbeat);

  /// No description provided for @eldDiagnosticDataAgeFormat.
  ///
  /// In ar, this message translates to:
  /// **'عمر البيانات: {dataAgeSeconds} ثانية'**
  String eldDiagnosticDataAgeFormat(String dataAgeSeconds);

  /// No description provided for @eldDiagnosticNotReady.
  ///
  /// In ar, this message translates to:
  /// **'غير جاهز للتشغيل الطبيعي.'**
  String get eldDiagnosticNotReady;

  /// No description provided for @eldDiagnosticDataNotReliable.
  ///
  /// In ar, this message translates to:
  /// **'البيانات غير موثوقة.'**
  String get eldDiagnosticDataNotReliable;

  /// No description provided for @eldDiagnosticConnected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get eldDiagnosticConnected;

  /// No description provided for @eldDiagnosticDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get eldDiagnosticDisconnected;

  /// No description provided for @eldDiagnosticUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get eldDiagnosticUnavailable;

  /// No description provided for @eldDiagnosticMalfunction.
  ///
  /// In ar, this message translates to:
  /// **'عطل'**
  String get eldDiagnosticMalfunction;

  /// No description provided for @eldDiagnosticNoConnectionStatus.
  ///
  /// In ar, this message translates to:
  /// **'الخادم لم يُرجع حالة اتصال.'**
  String get eldDiagnosticNoConnectionStatus;

  /// No description provided for @eldReadinessTitle.
  ///
  /// In ar, this message translates to:
  /// **'جاهزية ما قبل التشغيل'**
  String get eldReadinessTitle;

  /// No description provided for @eldReadinessChecking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فحص الجاهزية...'**
  String get eldReadinessChecking;

  /// No description provided for @eldReadinessReady.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للتشغيل'**
  String get eldReadinessReady;

  /// No description provided for @eldReadinessNotReady.
  ///
  /// In ar, this message translates to:
  /// **'غير جاهز للتشغيل'**
  String get eldReadinessNotReady;

  /// No description provided for @eldReadinessRecommendedActionFormat.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء المقترح: {action}'**
  String eldReadinessRecommendedActionFormat(String action);

  /// No description provided for @eldReadinessDevicePaired.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز مقترن'**
  String get eldReadinessDevicePaired;

  /// No description provided for @eldReadinessConnectionActive.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال نشط'**
  String get eldReadinessConnectionActive;

  /// No description provided for @eldReadinessMotionData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الحركة'**
  String get eldReadinessMotionData;

  /// No description provided for @eldReadinessLocationData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الموقع'**
  String get eldReadinessLocationData;

  /// No description provided for @eldReadinessEngineTelemetry.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المحرك (ECM)'**
  String get eldReadinessEngineTelemetry;

  /// No description provided for @eldMalfunctionTitle.
  ///
  /// In ar, this message translates to:
  /// **'في حال العطل (§395.34)'**
  String get eldMalfunctionTitle;

  /// No description provided for @eldMalfunctionStep1.
  ///
  /// In ar, this message translates to:
  /// **'دوّن العطل وأبلغ الناقل كتابياً خلال 24 ساعة.'**
  String get eldMalfunctionStep1;

  /// No description provided for @eldMalfunctionStep2.
  ///
  /// In ar, this message translates to:
  /// **'أعد بناء سجل 24 ساعة الحالية والأيام السبعة السابقة على الورق إن لم تكن متاحة من الجهاز.'**
  String get eldMalfunctionStep2;

  /// No description provided for @eldMalfunctionStep3.
  ///
  /// In ar, this message translates to:
  /// **'استمر بالتسجيل الورقي حتى إصلاح الجهاز.'**
  String get eldMalfunctionStep3;

  /// No description provided for @notifyCarrier.
  ///
  /// In ar, this message translates to:
  /// **'إخطار الناقل'**
  String get notifyCarrier;

  /// No description provided for @requestExtension.
  ///
  /// In ar, this message translates to:
  /// **'طلب تمديد'**
  String get requestExtension;

  /// No description provided for @simulateMalfunction.
  ///
  /// In ar, this message translates to:
  /// **'محاكاة عطل'**
  String get simulateMalfunction;

  /// No description provided for @simulateMalfunctionDebug.
  ///
  /// In ar, this message translates to:
  /// **'محاكاة عطل (تصحيح)'**
  String get simulateMalfunctionDebug;

  /// No description provided for @simulatedMalfunctionRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل عطل محاكى (تصحيح فقط)'**
  String get simulatedMalfunctionRecorded;

  /// No description provided for @inspectionLogsTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجلات التفتيش'**
  String get inspectionLogsTitle;

  /// No description provided for @dvirActiveDefectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'العيوب النشطة لمركبتك'**
  String get dvirActiveDefectsTitle;

  /// No description provided for @dvirDefectDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العيب'**
  String get dvirDefectDetailsTitle;

  /// No description provided for @dvirDefectSeverity.
  ///
  /// In ar, this message translates to:
  /// **'الخطورة'**
  String get dvirDefectSeverity;

  /// No description provided for @dvirDefectStage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة'**
  String get dvirDefectStage;

  /// No description provided for @dvirDefectOutOfService.
  ///
  /// In ar, this message translates to:
  /// **'المركبة متوقفة عن الخدمة'**
  String get dvirDefectOutOfService;

  /// No description provided for @dvirDefectRepairs.
  ///
  /// In ar, this message translates to:
  /// **'سجل الإصلاحات'**
  String get dvirDefectRepairs;

  /// No description provided for @dvirDefectNoRepairs.
  ///
  /// In ar, this message translates to:
  /// **'لا إصلاحات مسجلة بعد'**
  String get dvirDefectNoRepairs;

  /// No description provided for @dvirDefectCertifications.
  ///
  /// In ar, this message translates to:
  /// **'اعتمادات الناقل'**
  String get dvirDefectCertifications;

  /// No description provided for @dvirDefectNoCertifications.
  ///
  /// In ar, this message translates to:
  /// **'لا اعتمادات بعد'**
  String get dvirDefectNoCertifications;

  /// No description provided for @eldMalfunctionManualActive.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل اليدوي مفعّل حالياً.'**
  String get eldMalfunctionManualActive;

  /// No description provided for @eldMalfunctionManualActiveWithReason.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل اليدوي مفعّل حالياً — {reason}.'**
  String eldMalfunctionManualActiveWithReason(String reason);

  /// No description provided for @eldMalfunctionEndManual.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التسجيل اليدوي'**
  String get eldMalfunctionEndManual;

  /// No description provided for @eldMalfunctionServerNotAllow.
  ///
  /// In ar, this message translates to:
  /// **'الخادم لا يسمح بالتحويل إلى التسجيل اليدوي لهذه المركبة.'**
  String get eldMalfunctionServerNotAllow;

  /// No description provided for @eldMalfunctionStartManual.
  ///
  /// In ar, this message translates to:
  /// **'بدء التسجيل اليدوي'**
  String get eldMalfunctionStartManual;

  /// No description provided for @eldMalfunctionStartSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل بداية فترة التسجيل اليدوي على الخادم.'**
  String get eldMalfunctionStartSuccess;

  /// No description provided for @eldMalfunctionEndSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء التسجيل اليدوي والعودة إلى التسجيل الإلكتروني.'**
  String get eldMalfunctionEndSuccess;

  /// No description provided for @eldMalfunctionReasonStart.
  ///
  /// In ar, this message translates to:
  /// **'سبب التسجيل اليدوي'**
  String get eldMalfunctionReasonStart;

  /// No description provided for @eldMalfunctionReasonEnd.
  ///
  /// In ar, this message translates to:
  /// **'سبب إنهاء التسجيل اليدوي'**
  String get eldMalfunctionReasonEnd;

  /// No description provided for @eldMalfunctionHintStart.
  ///
  /// In ar, this message translates to:
  /// **'مثال: انقطاع الاتصال بالجهاز'**
  String get eldMalfunctionHintStart;

  /// No description provided for @eldMalfunctionHintEnd.
  ///
  /// In ar, this message translates to:
  /// **'مثال: عاد اتصال الجهاز'**
  String get eldMalfunctionHintEnd;

  /// No description provided for @dvirListNoRecords.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات'**
  String get dvirListNoRecords;

  /// No description provided for @dvirListTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي'**
  String get dvirListTotal;

  /// No description provided for @dvirListOpen.
  ///
  /// In ar, this message translates to:
  /// **'عيوب مفتوحة'**
  String get dvirListOpen;

  /// No description provided for @dvirListSigned.
  ///
  /// In ar, this message translates to:
  /// **'موقّعة'**
  String get dvirListSigned;

  /// No description provided for @dvirListOos.
  ///
  /// In ar, this message translates to:
  /// **'خارج الخدمة'**
  String get dvirListOos;

  /// No description provided for @serverAcceptedDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'قبل الخادم المتابعة دون اتصال. لم يُنشأ حدث واجب محلي.'**
  String get serverAcceptedDisconnected;

  /// No description provided for @macAddressRequired.
  ///
  /// In ar, this message translates to:
  /// **'عنوان MAC مطلوب.'**
  String get macAddressRequired;

  /// No description provided for @coDriverSelectLabel.
  ///
  /// In ar, this message translates to:
  /// **'اختر مساعد السائق'**
  String get coDriverSelectLabel;

  /// No description provided for @coDriverSelectHint.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار مساعد السائق الخاص بك'**
  String get coDriverSelectHint;

  /// No description provided for @coDriverSwitchDrivers.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الأدوار'**
  String get coDriverSwitchDrivers;

  /// No description provided for @coDriverSwitchHint.
  ///
  /// In ar, this message translates to:
  /// **'ستصبح السائق المساعد. سيبقى مساعدك سائقاً.'**
  String get coDriverSwitchHint;

  /// No description provided for @coDriverSwitching.
  ///
  /// In ar, this message translates to:
  /// **'جاري التبديل...'**
  String get coDriverSwitching;

  /// No description provided for @coDriverSwitchAction.
  ///
  /// In ar, this message translates to:
  /// **'تبديل'**
  String get coDriverSwitchAction;

  /// No description provided for @coDriverConfirmSwitchTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التبديل'**
  String get coDriverConfirmSwitchTitle;

  /// No description provided for @coDriverConfirmSwitchBody.
  ///
  /// In ar, this message translates to:
  /// **'يطلب التبديل من الخادم فقط. لن تُنقل ساعات الخدمة ولن تتغير حالة الواجب.'**
  String get coDriverConfirmSwitchBody;

  /// No description provided for @coDriverRolesSwitchedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تبديل الأدوار'**
  String get coDriverRolesSwitchedTitle;

  /// No description provided for @coDriverRolesSwitchedBody.
  ///
  /// In ar, this message translates to:
  /// **'أنت الآن السائق المساعد.\n{newPrimary} هو الآن السائق الأساسي.\n\nلم تُنقل الساعات ولم تتغير حالة الواجب. يضبط السائق الجديد حالته قبل الحركة.'**
  String coDriverRolesSwitchedBody(String newPrimary);

  /// No description provided for @coDriverDefaultNewPrimary.
  ///
  /// In ar, this message translates to:
  /// **'السائق المساعد'**
  String get coDriverDefaultNewPrimary;

  /// No description provided for @coDriverNone.
  ///
  /// In ar, this message translates to:
  /// **'لا سائق مساعد'**
  String get coDriverNone;

  /// No description provided for @coDriverRefusalSessionMissing.
  ///
  /// In ar, this message translates to:
  /// **'جلسة السائق غير موجودة. سجّل الدخول قبل التبديل.'**
  String get coDriverRefusalSessionMissing;

  /// No description provided for @coDriverRefusalStillDriving.
  ///
  /// In ar, this message translates to:
  /// **'غيّر حالة الواجب قبل التسليم. التبديل لا يغيّر الحالة.'**
  String get coDriverRefusalStillDriving;

  /// No description provided for @coDriverRefusalMotionUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.'**
  String get coDriverRefusalMotionUnknown;

  /// No description provided for @coDriverRefusalThresholdMissing.
  ///
  /// In ar, this message translates to:
  /// **'عتبة الحركة غير متوفرة من الإعداد.'**
  String get coDriverRefusalThresholdMissing;

  /// No description provided for @coDriverRefusalVehicleMoving.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تبديل الأدوار والمركبة تتحرك.'**
  String get coDriverRefusalVehicleMoving;

  /// No description provided for @coDriverRefusalCoDriverMissing.
  ///
  /// In ar, this message translates to:
  /// **'اختر سائقاً مساعداً قبل التبديل.'**
  String get coDriverRefusalCoDriverMissing;

  /// No description provided for @coDriverRefusalSameDriver.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن اختيار الحساب الحالي سائقاً مساعداً.'**
  String get coDriverRefusalSameDriver;

  /// No description provided for @coDriverLinkedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساعد المرتبط'**
  String get coDriverLinkedTitle;

  /// No description provided for @coDriverLinkNotRead.
  ///
  /// In ar, this message translates to:
  /// **'لم يُقرأ الارتباط بعد.'**
  String get coDriverLinkNotRead;

  /// No description provided for @coDriverLinkNone.
  ///
  /// In ar, this message translates to:
  /// **'لا سائق مساعد مرتبط.'**
  String get coDriverLinkNone;

  /// No description provided for @coDriverTeamDrivingActive.
  ///
  /// In ar, this message translates to:
  /// **'قيادة جماعية نشطة'**
  String get coDriverTeamDrivingActive;

  /// No description provided for @coDriverTeamDrivingInactive.
  ///
  /// In ar, this message translates to:
  /// **'قيادة جماعية غير نشطة'**
  String get coDriverTeamDrivingInactive;

  /// No description provided for @coDriverHosIsolationReadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة حالة عزل سجلات HOS.'**
  String get coDriverHosIsolationReadError;

  /// No description provided for @coDriverHosIsolated.
  ///
  /// In ar, this message translates to:
  /// **'سجلات HOS معزولة'**
  String get coDriverHosIsolated;

  /// No description provided for @coDriverHosNotIsolated.
  ///
  /// In ar, this message translates to:
  /// **'سجلات HOS غير معزولة'**
  String get coDriverHosNotIsolated;

  /// No description provided for @coDriverVehicleMissing.
  ///
  /// In ar, this message translates to:
  /// **'اختر مركبة قبل ربط السائق المساعد.'**
  String get coDriverVehicleMissing;

  /// No description provided for @dvirDefectsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عيوب للتقرير عنها.'**
  String get dvirDefectsNone;

  /// No description provided for @dvirDefectsCount.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد {defectCount} عيوب.'**
  String dvirDefectsCount(int defectCount);

  /// No description provided for @languageSpanish.
  ///
  /// In ar, this message translates to:
  /// **'الإسبانية'**
  String get languageSpanish;

  /// No description provided for @reCertificationRequiredMsg.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إعادة الاعتماد: حدثت تعديلات بعد آخر توقيع.'**
  String get reCertificationRequiredMsg;

  /// No description provided for @statusOff.
  ///
  /// In ar, this message translates to:
  /// **'خارج الخدمة'**
  String get statusOff;

  /// No description provided for @statusSb.
  ///
  /// In ar, this message translates to:
  /// **'مقصورة النوم'**
  String get statusSb;

  /// No description provided for @statusD.
  ///
  /// In ar, this message translates to:
  /// **'قيادة'**
  String get statusD;

  /// No description provided for @statusOn.
  ///
  /// In ar, this message translates to:
  /// **'في الخدمة'**
  String get statusOn;

  /// No description provided for @statusPc.
  ///
  /// In ar, this message translates to:
  /// **'استخدام شخصي'**
  String get statusPc;

  /// No description provided for @statusYm.
  ///
  /// In ar, this message translates to:
  /// **'حركة ساحة'**
  String get statusYm;

  /// No description provided for @dvirPreTrip.
  ///
  /// In ar, this message translates to:
  /// **'قبل الرحلة'**
  String get dvirPreTrip;

  /// No description provided for @dvirPostTrip.
  ///
  /// In ar, this message translates to:
  /// **'بعد الرحلة'**
  String get dvirPostTrip;

  /// No description provided for @dvirSafeToDrive.
  ///
  /// In ar, this message translates to:
  /// **'آمنة للقيادة'**
  String get dvirSafeToDrive;

  /// No description provided for @dvirNeedsRepair.
  ///
  /// In ar, this message translates to:
  /// **'تتطلب صيانة'**
  String get dvirNeedsRepair;

  /// No description provided for @dvirUnsafe.
  ///
  /// In ar, this message translates to:
  /// **'غير آمنة'**
  String get dvirUnsafe;

  /// No description provided for @dvirBrakes.
  ///
  /// In ar, this message translates to:
  /// **'المكابح'**
  String get dvirBrakes;

  /// No description provided for @dvirTires.
  ///
  /// In ar, this message translates to:
  /// **'الإطارات'**
  String get dvirTires;

  /// No description provided for @dvirLights.
  ///
  /// In ar, this message translates to:
  /// **'الإضاءة'**
  String get dvirLights;

  /// No description provided for @dvirSteering.
  ///
  /// In ar, this message translates to:
  /// **'أجهزة التوجيه'**
  String get dvirSteering;

  /// No description provided for @dvirTrailerCoupling.
  ///
  /// In ar, this message translates to:
  /// **'وصلات المقطورة'**
  String get dvirTrailerCoupling;

  /// No description provided for @dvirEmergencyEquipment.
  ///
  /// In ar, this message translates to:
  /// **'معدات الطوارئ'**
  String get dvirEmergencyEquipment;

  /// No description provided for @dvirEngine.
  ///
  /// In ar, this message translates to:
  /// **'المحرك'**
  String get dvirEngine;

  /// No description provided for @dvirFuelSystem.
  ///
  /// In ar, this message translates to:
  /// **'نظام الوقود'**
  String get dvirFuelSystem;

  /// No description provided for @dvirExhaustSystem.
  ///
  /// In ar, this message translates to:
  /// **'نظام العادم'**
  String get dvirExhaustSystem;

  /// No description provided for @dvirSuspension.
  ///
  /// In ar, this message translates to:
  /// **'نظام التعليق'**
  String get dvirSuspension;

  /// No description provided for @dvirMirrors.
  ///
  /// In ar, this message translates to:
  /// **'المرايا'**
  String get dvirMirrors;

  /// No description provided for @dvirWindshield.
  ///
  /// In ar, this message translates to:
  /// **'الزجاج الأمامي'**
  String get dvirWindshield;

  /// No description provided for @routingCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز التوجيه'**
  String get routingCode;

  /// No description provided for @routingCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التوجيه من المفتش'**
  String get routingCodeHint;

  /// No description provided for @tooManyPinAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولات خاطئة كثيرة. انتظر قليلاً ثم حاول مجدداً.'**
  String get tooManyPinAttempts;

  /// No description provided for @reviewedBy.
  ///
  /// In ar, this message translates to:
  /// **'باسم مُراجِع التقرير'**
  String get reviewedBy;

  /// No description provided for @companyName.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get companyName;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @diagnosticsScreen.
  ///
  /// In ar, this message translates to:
  /// **'التشخيصات'**
  String get diagnosticsScreen;

  /// No description provided for @diagnosticEvents.
  ///
  /// In ar, this message translates to:
  /// **'أحداث تشخيص البيانات'**
  String get diagnosticEvents;

  /// No description provided for @formSavedOffline.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ النموذج محلياً — سيُزامن عند عودة الاتصال.'**
  String get formSavedOffline;

  /// No description provided for @transferMethodWebServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات الويب'**
  String get transferMethodWebServices;

  /// No description provided for @transferMethodEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get transferMethodEmail;

  /// No description provided for @dvirRepairCert.
  ///
  /// In ar, this message translates to:
  /// **'شهادة إصلاح'**
  String get dvirRepairCert;

  /// No description provided for @dvirReviewed39613.
  ///
  /// In ar, this message translates to:
  /// **'تمت مراجعة §396.13'**
  String get dvirReviewed39613;

  /// No description provided for @dvirReportId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف التقرير'**
  String get dvirReportId;

  /// No description provided for @dvirRetentionUntil.
  ///
  /// In ar, this message translates to:
  /// **'الاحتفاظ حتى (§396.11)'**
  String get dvirRetentionUntil;

  /// No description provided for @dvirPrevReviewSection.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة تقرير الفحص السابق (§396.13)'**
  String get dvirPrevReviewSection;

  /// No description provided for @offlineEldGeneratedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد ملف ELD بنجاح في وضع عدم الاتصال'**
  String get offlineEldGeneratedTitle;

  /// No description provided for @offlineEldGeneratedDesc.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الملف محلياً بصيغة CSV وفق معايير FMCSA (49 CFR § 395). تم جدولة إرسال السجلات للسيرفر فور عودة الاتصال، ويمكنك مشاركة الملف مباشرة مع ضابط التفتيش الآن.'**
  String get offlineEldGeneratedDesc;

  /// No description provided for @shareOrExportCsv.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة / حفظ ملف CSV'**
  String get shareOrExportCsv;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
