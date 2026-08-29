import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('en')
  ];

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
  /// **'السجلات'**
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
  /// **'الخادم غير مهيأ'**
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
  /// **'بدء الخدمة'**
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
  /// **'تحركات ساحة'**
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
  /// **'البريد الإلكتروني / اسم المستخدم'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مطلوب'**
  String get emailRequired;

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
  /// **'لا يوجد'**
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
  /// **'عداد المسافة'**
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

  /// No description provided for @startInspectionDesc.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التفتيش لعرض السجلات للضابط. سيتم قفل الشاشة لمنع الوصول للتطبيقات الأخرى.'**
  String get startInspectionDesc;

  /// No description provided for @sendLogs.
  ///
  /// In ar, this message translates to:
  /// **'إرسال السجلات'**
  String get sendLogs;

  /// No description provided for @emailLogs.
  ///
  /// In ar, this message translates to:
  /// **'إرسال عبر البريد'**
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
