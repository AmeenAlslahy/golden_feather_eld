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
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @driverId.
  ///
  /// In en, this message translates to:
  /// **'Driver ID'**
  String get driverId;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licenseState.
  ///
  /// In en, this message translates to:
  /// **'License State'**
  String get licenseState;

  /// No description provided for @exemptDriver.
  ///
  /// In en, this message translates to:
  /// **'Exempt Driver'**
  String get exemptDriver;

  /// No description provided for @unidentifiedDriving.
  ///
  /// In en, this message translates to:
  /// **'Unidentified Driving'**
  String get unidentifiedDriving;

  /// No description provided for @coDriverId.
  ///
  /// In en, this message translates to:
  /// **'Co-Driver ID'**
  String get coDriverId;

  /// No description provided for @logDate.
  ///
  /// In en, this message translates to:
  /// **'Log Date'**
  String get logDate;

  /// No description provided for @displayDate.
  ///
  /// In en, this message translates to:
  /// **'Display Date'**
  String get displayDate;

  /// No description provided for @displayLocation.
  ///
  /// In en, this message translates to:
  /// **'Display Location'**
  String get displayLocation;

  /// No description provided for @eldRegId.
  ///
  /// In en, this message translates to:
  /// **'ELD Registration ID'**
  String get eldRegId;

  /// No description provided for @eldIdentifier.
  ///
  /// In en, this message translates to:
  /// **'ELD Identifier'**
  String get eldIdentifier;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @periodStart.
  ///
  /// In en, this message translates to:
  /// **'Period Start'**
  String get periodStart;

  /// No description provided for @dataDiag.
  ///
  /// In en, this message translates to:
  /// **'Data Diag.'**
  String get dataDiag;

  /// No description provided for @deviceMalf.
  ///
  /// In en, this message translates to:
  /// **'Device Malf.'**
  String get deviceMalf;

  /// No description provided for @vin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vin;

  /// No description provided for @carrier.
  ///
  /// In en, this message translates to:
  /// **'Carrier'**
  String get carrier;

  /// No description provided for @mainOffice.
  ///
  /// In en, this message translates to:
  /// **'Main Office'**
  String get mainOffice;

  /// No description provided for @homeTerminal.
  ///
  /// In en, this message translates to:
  /// **'Home Terminal'**
  String get homeTerminal;

  /// No description provided for @insertDutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Insert Duty Status'**
  String get insertDutyStatus;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addButton;

  /// No description provided for @eventAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event added successfully'**
  String get eventAddedSuccess;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Golden Feather ELD'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Golden Feather - Field Compliance Tracking'**
  String get appSlogan;

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get statusTitle;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @locationButton.
  ///
  /// In en, this message translates to:
  /// **'Send location'**
  String get locationButton;

  /// No description provided for @statusButton.
  ///
  /// In en, this message translates to:
  /// **'Show status'**
  String get statusButton;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Change settings'**
  String get settingsButton;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;

  /// No description provided for @disabledValue.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledValue;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'Device identifier'**
  String get idLabel;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get urlLabel;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy'**
  String get accuracyLabel;

  /// No description provided for @highestAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highestAccuracyLabel;

  /// No description provided for @highAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highAccuracyLabel;

  /// No description provided for @mediumAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumAccuracyLabel;

  /// No description provided for @lowAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowAccuracyLabel;

  /// No description provided for @intervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval (seconds)'**
  String get intervalLabel;

  /// No description provided for @fastestIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Fastest interval (seconds)'**
  String get fastestIntervalLabel;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (meters)'**
  String get distanceLabel;

  /// No description provided for @angleLabel.
  ///
  /// In en, this message translates to:
  /// **'Angle (degrees)'**
  String get angleLabel;

  /// No description provided for @heartbeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Stationary heartbeat (seconds)'**
  String get heartbeatLabel;

  /// No description provided for @bufferLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline buffering'**
  String get bufferLabel;

  /// No description provided for @wakelockLabel.
  ///
  /// In en, this message translates to:
  /// **'Wake lock'**
  String get wakelockLabel;

  /// No description provided for @stopDetectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop detection'**
  String get stopDetectionLabel;

  /// No description provided for @preferPlatformProvidersLabel.
  ///
  /// In en, this message translates to:
  /// **'Use system location'**
  String get preferPlatformProvidersLabel;

  /// No description provided for @serverNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Server Not Configured'**
  String get serverNotConfigured;

  /// No description provided for @trackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Continuous tracking'**
  String get trackingLabel;

  /// No description provided for @advancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get advancedLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @optimizationMessage.
  ///
  /// In en, this message translates to:
  /// **'To ensure reliable tracking, please disable battery optimization for this app.'**
  String get optimizationMessage;

  /// No description provided for @passwordError.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get passwordError;

  /// No description provided for @disclosureMessage.
  ///
  /// In en, this message translates to:
  /// **'This app collects location and activity data in the background and sends it to the configured server.'**
  String get disclosureMessage;

  /// No description provided for @configurationMessage.
  ///
  /// In en, this message translates to:
  /// **'Apply new configuration?'**
  String get configurationMessage;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start service'**
  String get startAction;

  /// No description provided for @stopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop service'**
  String get stopAction;

  /// No description provided for @sosAction.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sosAction;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get inspection;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @startInspection.
  ///
  /// In en, this message translates to:
  /// **'Start Inspection'**
  String get startInspection;

  /// No description provided for @stopInspection.
  ///
  /// In en, this message translates to:
  /// **'Stop Inspection'**
  String get stopInspection;

  /// No description provided for @pauseInspection.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseInspection;

  /// No description provided for @resumeInspection.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeInspection;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveDraft;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard Draft'**
  String get discardDraft;

  /// No description provided for @inspectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection Title'**
  String get inspectionTitle;

  /// No description provided for @inspectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Inspection Location'**
  String get inspectionLocation;

  /// No description provided for @inspectionDate.
  ///
  /// In en, this message translates to:
  /// **'Inspection Date'**
  String get inspectionDate;

  /// No description provided for @inspectionTime.
  ///
  /// In en, this message translates to:
  /// **'Inspection Time'**
  String get inspectionTime;

  /// No description provided for @inspectionDuration.
  ///
  /// In en, this message translates to:
  /// **'Inspection Duration'**
  String get inspectionDuration;

  /// No description provided for @inspectorName.
  ///
  /// In en, this message translates to:
  /// **'Inspector Name'**
  String get inspectorName;

  /// No description provided for @inspectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Inspection Status'**
  String get inspectionStatus;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusRequiresReview.
  ///
  /// In en, this message translates to:
  /// **'Requires Review'**
  String get statusRequiresReview;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist Title'**
  String get checklistTitle;

  /// No description provided for @checklistCategory.
  ///
  /// In en, this message translates to:
  /// **'Checklist Category'**
  String get checklistCategory;

  /// No description provided for @addChecklist.
  ///
  /// In en, this message translates to:
  /// **'Add Checklist'**
  String get addChecklist;

  /// No description provided for @editChecklist.
  ///
  /// In en, this message translates to:
  /// **'Edit Checklist'**
  String get editChecklist;

  /// No description provided for @deleteChecklist.
  ///
  /// In en, this message translates to:
  /// **'Delete Checklist'**
  String get deleteChecklist;

  /// No description provided for @checklistItems.
  ///
  /// In en, this message translates to:
  /// **'Checklist Items'**
  String get checklistItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @itemTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get itemTypeText;

  /// No description provided for @itemTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get itemTypeNumber;

  /// No description provided for @itemTypeYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get itemTypeYesNo;

  /// No description provided for @itemTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get itemTypeMultipleChoice;

  /// No description provided for @itemTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get itemTypePhoto;

  /// No description provided for @itemTypeSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get itemTypeSignature;

  /// No description provided for @itemTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get itemTypeDate;

  /// No description provided for @itemTypeTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get itemTypeTime;

  /// No description provided for @itemTypeBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get itemTypeBarcode;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo required'**
  String get photoRequired;

  /// No description provided for @signatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Signature required'**
  String get signatureRequired;

  /// No description provided for @notesRequired.
  ///
  /// In en, this message translates to:
  /// **'Notes required'**
  String get notesRequired;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @photoPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo Preview'**
  String get photoPreview;

  /// No description provided for @signHere.
  ///
  /// In en, this message translates to:
  /// **'Sign Here'**
  String get signHere;

  /// No description provided for @clearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear Signature'**
  String get clearSignature;

  /// No description provided for @signaturePreview.
  ///
  /// In en, this message translates to:
  /// **'Signature Preview'**
  String get signaturePreview;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String syncPending(String count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String syncFailed(String count);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorMessage;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get successMessage;

  /// No description provided for @warningMessage.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningMessage;

  /// No description provided for @infoMessage.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get infoMessage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please grant location permission'**
  String get locationPermissionDenied;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please grant camera permission'**
  String get cameraPermissionDenied;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please grant storage permission'**
  String get storagePermissionDenied;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirmDelete;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @confirmSubmit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit the report?'**
  String get confirmSubmit;

  /// No description provided for @confirmDiscard.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard changes?'**
  String get confirmDiscard;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @changesWillBeLost.
  ///
  /// In en, this message translates to:
  /// **'Changes will be lost if you continue'**
  String get changesWillBeLost;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get systemMode;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @qrCodeScanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrCodeScanner;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @scanningInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code'**
  String get scanningInstructions;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// No description provided for @sortByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortByStatus;

  /// No description provided for @exportPDF.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPDF;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newInspectionAssigned.
  ///
  /// In en, this message translates to:
  /// **'New inspection assigned'**
  String get newInspectionAssigned;

  /// No description provided for @inspectionReminder.
  ///
  /// In en, this message translates to:
  /// **'Inspection reminder'**
  String get inspectionReminder;

  /// No description provided for @inspectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Inspection overdue'**
  String get inspectionOverdue;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncComplete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @fail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get fail;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @unableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to ELD with MAC'**
  String get unableToConnect;

  /// No description provided for @verifyFollowingItems.
  ///
  /// In en, this message translates to:
  /// **'Please verify the following items:'**
  String get verifyFollowingItems;

  /// No description provided for @macEnteredCorrectly.
  ///
  /// In en, this message translates to:
  /// **'ELD MAC address is entered correctly.'**
  String get macEnteredCorrectly;

  /// No description provided for @hardwareProperlyInstalled.
  ///
  /// In en, this message translates to:
  /// **'ELD hardware is properly installed.'**
  String get hardwareProperlyInstalled;

  /// No description provided for @vehiclePowerOn.
  ///
  /// In en, this message translates to:
  /// **'Vehicle power is ON.'**
  String get vehiclePowerOn;

  /// No description provided for @bluetoothEnabled.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is enabled on the mobile device.'**
  String get bluetoothEnabled;

  /// No description provided for @gpsEnabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is enabled on the mobile device.'**
  String get gpsEnabled;

  /// No description provided for @enterMacAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter ELD MAC address listed on the device:'**
  String get enterMacAddress;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connect;

  /// No description provided for @continueDisconnected.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE DISCONNECTED'**
  String get continueDisconnected;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @hoursRecap.
  ///
  /// In en, this message translates to:
  /// **'Hours Recap'**
  String get hoursRecap;

  /// No description provided for @suggestedEvents.
  ///
  /// In en, this message translates to:
  /// **'Suggested Events'**
  String get suggestedEvents;

  /// No description provided for @unidentifiedEvents.
  ///
  /// In en, this message translates to:
  /// **'Unidentified Events'**
  String get unidentifiedEvents;

  /// No description provided for @unclaimed.
  ///
  /// In en, this message translates to:
  /// **'UNCLAIMED'**
  String get unclaimed;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No Records'**
  String get noRecords;

  /// No description provided for @drawSignatureHere.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature here'**
  String get drawSignatureHere;

  /// No description provided for @fillFormFirst.
  ///
  /// In en, this message translates to:
  /// **'You need to fill and save form first.'**
  String get fillFormFirst;

  /// No description provided for @formLabel.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get formLabel;

  /// No description provided for @certifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Certify'**
  String get certifyLabel;

  /// No description provided for @editDutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Edit Duty Status'**
  String get editDutyStatus;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @manualLocation.
  ///
  /// In en, this message translates to:
  /// **'Manual Location'**
  String get manualLocation;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @form.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get form;

  /// No description provided for @certify.
  ///
  /// In en, this message translates to:
  /// **'Certify'**
  String get certify;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @trailers.
  ///
  /// In en, this message translates to:
  /// **'Trailers'**
  String get trailers;

  /// No description provided for @shippingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Shipping Documents'**
  String get shippingDocuments;

  /// No description provided for @coDriver.
  ///
  /// In en, this message translates to:
  /// **'Co-Driver'**
  String get coDriver;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @certifyDeclaration.
  ///
  /// In en, this message translates to:
  /// **'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.'**
  String get certifyDeclaration;

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'NOT READY'**
  String get notReady;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'AGREE'**
  String get agree;

  /// No description provided for @timeline24h.
  ///
  /// In en, this message translates to:
  /// **'24-Hour Timeline'**
  String get timeline24h;

  /// No description provided for @settingsAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings applied successfully'**
  String get settingsAppliedSuccess;

  /// No description provided for @deviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInformation;

  /// No description provided for @confirmClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all logs?'**
  String get confirmClearLogs;

  /// No description provided for @trackingStatus.
  ///
  /// In en, this message translates to:
  /// **'Tracking Status'**
  String get trackingStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @stoppedStatus.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stoppedStatus;

  /// No description provided for @coordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinatesLabel;

  /// No description provided for @lastUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdateLabel;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Disabled'**
  String get locationDisabled;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @recap.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get recap;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @errorCannotChangeStatusWhileMoving.
  ///
  /// In en, this message translates to:
  /// **'Cannot change status while the vehicle is moving.'**
  String get errorCannotChangeStatusWhileMoving;

  /// No description provided for @customLocation.
  ///
  /// In en, this message translates to:
  /// **'Custom location'**
  String get customLocation;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateButton;

  /// No description provided for @offDuty.
  ///
  /// In en, this message translates to:
  /// **'Off Duty'**
  String get offDuty;

  /// No description provided for @sleeperBerth.
  ///
  /// In en, this message translates to:
  /// **'Sleeper'**
  String get sleeperBerth;

  /// No description provided for @drivingStatus.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get drivingStatus;

  /// No description provided for @onDuty.
  ///
  /// In en, this message translates to:
  /// **'On Duty'**
  String get onDuty;

  /// No description provided for @personalUse.
  ///
  /// In en, this message translates to:
  /// **'Personal Use'**
  String get personalUse;

  /// No description provided for @yardMoves.
  ///
  /// In en, this message translates to:
  /// **'Yard Moves'**
  String get yardMoves;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTitle;

  /// No description provided for @qrScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScannerTitle;

  /// No description provided for @qrScannerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code'**
  String get qrScannerInstructions;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @hoursWorkedToday.
  ///
  /// In en, this message translates to:
  /// **'Hours Worked Today'**
  String get hoursWorkedToday;

  /// No description provided for @hoursAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Hours Available Today'**
  String get hoursAvailableToday;

  /// No description provided for @hoursAvailableTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Hours Available Tomorrow'**
  String get hoursAvailableTomorrow;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get fullNameRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email / Username'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @notImplemented.
  ///
  /// In en, this message translates to:
  /// **'This feature is not implemented yet'**
  String get notImplemented;

  /// No description provided for @dvirTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Inspection (DVIR)'**
  String get dvirTitle;

  /// No description provided for @inspectionType.
  ///
  /// In en, this message translates to:
  /// **'Inspection Type'**
  String get inspectionType;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInfo;

  /// No description provided for @mechanicalChecklist.
  ///
  /// In en, this message translates to:
  /// **'Mechanical Checklist'**
  String get mechanicalChecklist;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @vehicleCondition.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Condition Assessment'**
  String get vehicleCondition;

  /// No description provided for @driverSignature.
  ///
  /// In en, this message translates to:
  /// **'Driver Signature'**
  String get driverSignature;

  /// No description provided for @saveReport.
  ///
  /// In en, this message translates to:
  /// **'Save Report'**
  String get saveReport;

  /// No description provided for @updateReport.
  ///
  /// In en, this message translates to:
  /// **'Update Report'**
  String get updateReport;

  /// No description provided for @newReport.
  ///
  /// In en, this message translates to:
  /// **'New Inspection Report'**
  String get newReport;

  /// No description provided for @editReport.
  ///
  /// In en, this message translates to:
  /// **'Edit Report'**
  String get editReport;

  /// No description provided for @noDvirReports.
  ///
  /// In en, this message translates to:
  /// **'No Inspection Reports'**
  String get noDvirReports;

  /// No description provided for @createNewReport.
  ///
  /// In en, this message translates to:
  /// **'Create New Report'**
  String get createNewReport;

  /// No description provided for @reportSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Inspection report saved successfully'**
  String get reportSavedSuccess;

  /// No description provided for @defectsFound.
  ///
  /// In en, this message translates to:
  /// **'Defects Found'**
  String get defectsFound;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @trailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get trailer;

  /// No description provided for @odometerReading.
  ///
  /// In en, this message translates to:
  /// **'Odometer Reading'**
  String get odometerReading;

  /// No description provided for @dtcCodes.
  ///
  /// In en, this message translates to:
  /// **'Engine Diagnostic Codes (DTC)'**
  String get dtcCodes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes about vehicle condition...'**
  String get notesHint;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// No description provided for @searchVehicle.
  ///
  /// In en, this message translates to:
  /// **'Search vehicles...'**
  String get searchVehicle;

  /// No description provided for @noVehiclesFound.
  ///
  /// In en, this message translates to:
  /// **'No vehicles available'**
  String get noVehiclesFound;

  /// No description provided for @vehicleSelected.
  ///
  /// In en, this message translates to:
  /// **'Vehicle selected'**
  String get vehicleSelected;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @underDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Under Development...'**
  String get underDevelopment;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @miles.
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get miles;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @newInspectionReport.
  ///
  /// In en, this message translates to:
  /// **'New Inspection Report'**
  String get newInspectionReport;

  /// No description provided for @editInspectionReport.
  ///
  /// In en, this message translates to:
  /// **'Edit Inspection Report'**
  String get editInspectionReport;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @infoPacket.
  ///
  /// In en, this message translates to:
  /// **'Info Packet'**
  String get infoPacket;

  /// No description provided for @odometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometer;

  /// No description provided for @engineHours.
  ///
  /// In en, this message translates to:
  /// **'Engine Hours'**
  String get engineHours;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @dotInspection.
  ///
  /// In en, this message translates to:
  /// **'DOT Inspection'**
  String get dotInspection;

  /// No description provided for @setInspectionPin.
  ///
  /// In en, this message translates to:
  /// **'Set Inspection PIN'**
  String get setInspectionPin;

  /// No description provided for @enter4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit PIN'**
  String get enter4DigitPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @enterPinToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to Unlock'**
  String get enterPinToUnlock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @dotInspectionMode.
  ///
  /// In en, this message translates to:
  /// **'DOT Inspection Mode'**
  String get dotInspectionMode;

  /// No description provided for @screenLockedForOfficer.
  ///
  /// In en, this message translates to:
  /// **'Screen locked for officer review'**
  String get screenLockedForOfficer;

  /// No description provided for @unlockDriverOnly.
  ///
  /// In en, this message translates to:
  /// **'Unlock (Driver Only)'**
  String get unlockDriverOnly;

  /// No description provided for @startInspectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Start inspection to display logs for the officer. The screen will be locked to prevent access to other apps.'**
  String get startInspectionDesc;

  /// No description provided for @sendLogs.
  ///
  /// In en, this message translates to:
  /// **'Send Logs'**
  String get sendLogs;

  /// No description provided for @emailLogs.
  ///
  /// In en, this message translates to:
  /// **'Email Logs'**
  String get emailLogs;

  /// No description provided for @endInspection.
  ///
  /// In en, this message translates to:
  /// **'End Inspection'**
  String get endInspection;

  /// No description provided for @certified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get certified;

  /// No description provided for @eldReport.
  ///
  /// In en, this message translates to:
  /// **'ELD Report'**
  String get eldReport;

  /// No description provided for @hosReport.
  ///
  /// In en, this message translates to:
  /// **'HOS Report'**
  String get hosReport;

  /// No description provided for @compliant.
  ///
  /// In en, this message translates to:
  /// **'Compliant'**
  String get compliant;

  /// No description provided for @nonCompliant.
  ///
  /// In en, this message translates to:
  /// **'Non-Compliant'**
  String get nonCompliant;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @break_.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get break_;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @malfunctionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Malfunction Alerts'**
  String get malfunctionAlerts;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @pdfExportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF exported successfully'**
  String get pdfExportedSuccess;

  /// No description provided for @userManual.
  ///
  /// In en, this message translates to:
  /// **'User Manual'**
  String get userManual;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @malfunctionManual.
  ///
  /// In en, this message translates to:
  /// **'Malfunction Manual'**
  String get malfunctionManual;

  /// No description provided for @viewUserManual.
  ///
  /// In en, this message translates to:
  /// **'View User Manual'**
  String get viewUserManual;

  /// No description provided for @viewInstructions.
  ///
  /// In en, this message translates to:
  /// **'View Instructions'**
  String get viewInstructions;

  /// No description provided for @viewMalfunctionManual.
  ///
  /// In en, this message translates to:
  /// **'View Malfunction Manual'**
  String get viewMalfunctionManual;

  /// No description provided for @legalNotice.
  ///
  /// In en, this message translates to:
  /// **'These documents are required by approved fleet management standards. They must be available at all times while operating a commercial vehicle.'**
  String get legalNotice;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @connectingToVehicle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Vehicle'**
  String get connectingToVehicle;

  /// No description provided for @changingDutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Changing Duty Status'**
  String get changingDutyStatus;

  /// No description provided for @viewingLogs.
  ///
  /// In en, this message translates to:
  /// **'Viewing Logs & Certification'**
  String get viewingLogs;

  /// No description provided for @vehicleInspection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Inspection (DVIR)'**
  String get vehicleInspection;

  /// No description provided for @roadsideInspection.
  ///
  /// In en, this message translates to:
  /// **'Roadside Inspection'**
  String get roadsideInspection;

  /// No description provided for @continueWithout.
  ///
  /// In en, this message translates to:
  /// **'Continue Without'**
  String get continueWithout;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @odom.
  ///
  /// In en, this message translates to:
  /// **'Odom.'**
  String get odom;

  /// No description provided for @eng.
  ///
  /// In en, this message translates to:
  /// **'Eng.'**
  String get eng;

  /// No description provided for @src.
  ///
  /// In en, this message translates to:
  /// **'Src'**
  String get src;

  /// No description provided for @noManualModifications.
  ///
  /// In en, this message translates to:
  /// **'No manual modifications found for this date.'**
  String get noManualModifications;

  /// No description provided for @failedToLoadAudits.
  ///
  /// In en, this message translates to:
  /// **'Failed to load audits'**
  String get failedToLoadAudits;

  /// No description provided for @exportErods.
  ///
  /// In en, this message translates to:
  /// **'Export as eRODS (XML/CSV)'**
  String get exportErods;

  /// No description provided for @requiredForFmcsa.
  ///
  /// In en, this message translates to:
  /// **'Required for FMCSA inspection'**
  String get requiredForFmcsa;

  /// No description provided for @changeStatusTo.
  ///
  /// In en, this message translates to:
  /// **'Change status to {status}'**
  String changeStatusTo(String status);

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @noRecordsToday.
  ///
  /// In en, this message translates to:
  /// **'No records for today'**
  String get noRecordsToday;

  /// No description provided for @trackingNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking has not started yet'**
  String get trackingNotStarted;

  /// No description provided for @gpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get gpsDisabled;

  /// No description provided for @notConnectedToServer.
  ///
  /// In en, this message translates to:
  /// **'Not connected to server'**
  String get notConnectedToServer;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @loadingRecords.
  ///
  /// In en, this message translates to:
  /// **'Loading records...'**
  String get loadingRecords;

  /// No description provided for @defectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Defects'**
  String get defectsTitle;

  /// No description provided for @vehicleConditionSatisfactory.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Condition Satisfactory'**
  String get vehicleConditionSatisfactory;

  /// No description provided for @auditReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String auditReason(String reason);

  /// No description provided for @auditStatusChange.
  ///
  /// In en, this message translates to:
  /// **'{oldStatus} -> {newStatus}'**
  String auditStatusChange(String oldStatus, String newStatus);

  /// No description provided for @calculatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Calculating location...'**
  String get calculatingLocation;

  /// No description provided for @driveLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'DRIVE'**
  String get driveLimitTitle;

  /// No description provided for @driveLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'11-Hour Driving Limit'**
  String get driveLimitDesc;

  /// No description provided for @shiftLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'SHIFT'**
  String get shiftLimitTitle;

  /// No description provided for @shiftLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'14-Hour On Duty Limit'**
  String get shiftLimitDesc;

  /// No description provided for @breakLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get breakLimitTitle;

  /// No description provided for @breakLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'30 Minute Rest Break'**
  String get breakLimitDesc;

  /// No description provided for @cycleLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'CYCLE'**
  String get cycleLimitTitle;

  /// No description provided for @cycleLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'USA 70/8'**
  String get cycleLimitDesc;

  /// No description provided for @hoursOfService.
  ///
  /// In en, this message translates to:
  /// **'HOURS OF SERVICE'**
  String get hoursOfService;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please login again'**
  String get sessionExpired;

  /// No description provided for @invalidConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Invalid server configuration'**
  String get invalidConfiguration;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @sessionMissing.
  ///
  /// In en, this message translates to:
  /// **'Session missing, please login again'**
  String get sessionMissing;

  /// No description provided for @carrierEdits.
  ///
  /// In en, this message translates to:
  /// **'Carrier Edits'**
  String get carrierEdits;

  /// No description provided for @switchDrivers.
  ///
  /// In en, this message translates to:
  /// **'Switch Drivers'**
  String get switchDrivers;

  /// No description provided for @auditTrail.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get auditTrail;

  /// No description provided for @repairCertification.
  ///
  /// In en, this message translates to:
  /// **'Repair Certification'**
  String get repairCertification;

  /// No description provided for @previousDvirReview.
  ///
  /// In en, this message translates to:
  /// **'Previous DVIR Review'**
  String get previousDvirReview;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @applicationInfo.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get applicationInfo;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @packageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageLabel;

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceIdLabel;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @centralServer.
  ///
  /// In en, this message translates to:
  /// **'Central server'**
  String get centralServer;

  /// No description provided for @locationService.
  ///
  /// In en, this message translates to:
  /// **'Location service (GPS)'**
  String get locationService;

  /// No description provided for @enabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledLabel;

  /// No description provided for @disabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledLabel;

  /// No description provided for @ecmSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'ECM Sync Status'**
  String get ecmSyncStatus;

  /// No description provided for @syncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedLabel;

  /// No description provided for @desyncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Desynced'**
  String get desyncedLabel;

  /// No description provided for @hardwareConnection.
  ///
  /// In en, this message translates to:
  /// **'Hardware Connection'**
  String get hardwareConnection;

  /// No description provided for @healthyLabel.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthyLabel;

  /// No description provided for @faultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Faulty'**
  String get faultyLabel;

  /// No description provided for @technicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Technical Info'**
  String get technicalInfo;

  /// No description provided for @eldEngineVersion.
  ///
  /// In en, this message translates to:
  /// **'ELD Engine Version'**
  String get eldEngineVersion;

  /// No description provided for @hardwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Hardware Version'**
  String get hardwareVersion;

  /// No description provided for @lastDataReceived.
  ///
  /// In en, this message translates to:
  /// **'Last Data Received'**
  String get lastDataReceived;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'For technical support, provide the device ID and version shown above.'**
  String get supportMessage;

  /// No description provided for @unassignedVehicles.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Vehicles'**
  String get unassignedVehicles;

  /// No description provided for @unassignedVehiclesCannotBeSelected.
  ///
  /// In en, this message translates to:
  /// **'Unassigned vehicles cannot be selected directly. Vehicles are assigned to drivers through the web portal by the fleet manager.\\n\\nPlease contact your fleet manager to assign the vehicle.'**
  String get unassignedVehiclesCannotBeSelected;

  /// No description provided for @contactManager.
  ///
  /// In en, this message translates to:
  /// **'Contact Manager'**
  String get contactManager;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get developerOptions;

  /// No description provided for @trackingLogs.
  ///
  /// In en, this message translates to:
  /// **'Tracking Logs'**
  String get trackingLogs;

  /// No description provided for @viewRawGpsLogs.
  ///
  /// In en, this message translates to:
  /// **'View raw GPS logs'**
  String get viewRawGpsLogs;

  /// No description provided for @mockErrors.
  ///
  /// In en, this message translates to:
  /// **'Mock Errors'**
  String get mockErrors;

  /// No description provided for @toolsToTestUi.
  ///
  /// In en, this message translates to:
  /// **'Tools to test UI'**
  String get toolsToTestUi;

  /// No description provided for @notAvailableInProductionBuild.
  ///
  /// In en, this message translates to:
  /// **'Not available in production build'**
  String get notAvailableInProductionBuild;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearLocalAppData.
  ///
  /// In en, this message translates to:
  /// **'Clear local app data'**
  String get clearLocalAppData;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @vehicleInMotion.
  ///
  /// In en, this message translates to:
  /// **'Vehicle in Motion'**
  String get vehicleInMotion;

  /// No description provided for @toComplyWithFmcsaRegulations.
  ///
  /// In en, this message translates to:
  /// **'To comply with FMCSA regulations and safety rules, the application is locked while driving. It will unlock when the vehicle stops.'**
  String get toComplyWithFmcsaRegulations;

  /// No description provided for @switchToManualMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Manual Mode'**
  String get switchToManualMode;

  /// No description provided for @accordingToFmcsa39534.
  ///
  /// In en, this message translates to:
  /// **'According to FMCSA §395.34, you may switch to manual recording if the ELD is malfunctioning. Please provide the reason below:'**
  String get accordingToFmcsa39534;

  /// No description provided for @reasonForManualMode.
  ///
  /// In en, this message translates to:
  /// **'Reason for manual mode...'**
  String get reasonForManualMode;

  /// No description provided for @pleaseProvideAReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason'**
  String get pleaseProvideAReason;

  /// No description provided for @selectCoDriver.
  ///
  /// In en, this message translates to:
  /// **'Select Co-driver'**
  String get selectCoDriver;

  /// No description provided for @selectYourCoDriver.
  ///
  /// In en, this message translates to:
  /// **'Select your co-driver'**
  String get selectYourCoDriver;

  /// No description provided for @youWillBecomeCoDriver.
  ///
  /// In en, this message translates to:
  /// **'You will become co-driver. Your co-driver will stay driver.'**
  String get youWillBecomeCoDriver;

  /// No description provided for @confirmSwitch.
  ///
  /// In en, this message translates to:
  /// **'Confirm Switch'**
  String get confirmSwitch;

  /// No description provided for @areYouSureYouWant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to switch roles?'**
  String get areYouSureYouWant;

  /// No description provided for @rolesSwitchedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'✅ Roles switched successfully'**
  String get rolesSwitchedSuccessfully;

  /// No description provided for @email1.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email1;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get timeZone;

  /// No description provided for @languageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdatedSuccessfully;

  /// No description provided for @odometerUnitUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Odometer unit updated successfully'**
  String get odometerUnitUpdatedSuccessfully;

  /// No description provided for @pleaseContactFleetManagerTo.
  ///
  /// In en, this message translates to:
  /// **'Please contact fleet manager to change information'**
  String get pleaseContactFleetManagerTo;

  /// No description provided for @formIsIncompletePleaseFill.
  ///
  /// In en, this message translates to:
  /// **'Form is incomplete, please fill all fields.'**
  String get formIsIncompletePleaseFill;

  /// No description provided for @failedToUpdateRulesFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to update rules'**
  String get failedToUpdateRulesFailure;

  /// No description provided for @hH.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hH;

  /// No description provided for @hHMM.
  ///
  /// In en, this message translates to:
  /// **'h m'**
  String get hHMM;

  /// No description provided for @activeCycle.
  ///
  /// In en, this message translates to:
  /// **'Active Cycle'**
  String get activeCycle;

  /// No description provided for @ruleSource.
  ///
  /// In en, this message translates to:
  /// **'Rule Source'**
  String get ruleSource;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @cargoType.
  ///
  /// In en, this message translates to:
  /// **'Cargo Type'**
  String get cargoType;

  /// No description provided for @restBreak.
  ///
  /// In en, this message translates to:
  /// **'Rest Break'**
  String get restBreak;

  /// No description provided for @dailyLimits.
  ///
  /// In en, this message translates to:
  /// **'Daily Limits'**
  String get dailyLimits;

  /// No description provided for @shiftWindow.
  ///
  /// In en, this message translates to:
  /// **'Shift window'**
  String get shiftWindow;

  /// No description provided for @requiredBreak.
  ///
  /// In en, this message translates to:
  /// **'Required break'**
  String get requiredBreak;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @malfunctionTypes.
  ///
  /// In en, this message translates to:
  /// **'Malfunction Types'**
  String get malfunctionTypes;

  /// No description provided for @dataGapRecordingInterruptionFor.
  ///
  /// In en, this message translates to:
  /// **'Data Gap: Recording interruption for more than 5 minutes.'**
  String get dataGapRecordingInterruptionFor;

  /// No description provided for @positioningMalfunctionZeroCoordinatesAt.
  ///
  /// In en, this message translates to:
  /// **'Positioning Malfunction: Zero coordinates at high speed.'**
  String get positioningMalfunctionZeroCoordinatesAt;

  /// No description provided for @motionSensorMalfunctionSuddenSpeed.
  ///
  /// In en, this message translates to:
  /// **'Motion Sensor Malfunction: Sudden speed change > 80 km/h.'**
  String get motionSensorMalfunctionSuddenSpeed;

  /// No description provided for @engineSyncMalfunctionEngineRunning.
  ///
  /// In en, this message translates to:
  /// **'Engine Sync Malfunction: Engine running > 60 min without motion.'**
  String get engineSyncMalfunctionEngineRunning;

  /// No description provided for @unidentifiedDriveVehicleMovingWithout.
  ///
  /// In en, this message translates to:
  /// **'Unidentified Drive: Vehicle moving without ignition.'**
  String get unidentifiedDriveVehicleMovingWithout;

  /// No description provided for @troubleshootingSteps.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting Steps'**
  String get troubleshootingSteps;

  /// No description provided for @k1CheckEldDeviceConnection.
  ///
  /// In en, this message translates to:
  /// **'1. Check ELD device connection to diagnostic port.'**
  String get k1CheckEldDeviceConnection;

  /// No description provided for @k2RestartTheVehicleAnd.
  ///
  /// In en, this message translates to:
  /// **'2. Restart the vehicle and wait 30 seconds.'**
  String get k2RestartTheVehicleAnd;

  /// No description provided for @k3CheckThatBluetoothAnd.
  ///
  /// In en, this message translates to:
  /// **'3. Check that Bluetooth and GPS are enabled on your phone.'**
  String get k3CheckThatBluetoothAnd;

  /// No description provided for @k4TryReconnectingFromThe.
  ///
  /// In en, this message translates to:
  /// **'4. Try reconnecting from the Connection screen.'**
  String get k4TryReconnectingFromThe;

  /// No description provided for @k5IfMalfunctionPersistsSwitch.
  ///
  /// In en, this message translates to:
  /// **'5. If malfunction persists, switch to paper logs.'**
  String get k5IfMalfunctionPersistsSwitch;

  /// No description provided for @k6ContactYourFleetManager.
  ///
  /// In en, this message translates to:
  /// **'6. Contact your fleet manager to report the malfunction.'**
  String get k6ContactYourFleetManager;

  /// No description provided for @importantDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Important Deadlines'**
  String get importantDeadlines;

  /// No description provided for @deviceMustBeRepairedWithin.
  ///
  /// In en, this message translates to:
  /// **'Device must be repaired within 8 days of malfunction.'**
  String get deviceMustBeRepairedWithin;

  /// No description provided for @cannotDriveWithoutAWorking.
  ///
  /// In en, this message translates to:
  /// **'Cannot drive without a working ELD for more than 8 days.'**
  String get cannotDriveWithoutAWorking;

  /// No description provided for @allMalfunctionsMustBeDocumented.
  ///
  /// In en, this message translates to:
  /// **'All malfunctions must be documented in logs.'**
  String get allMalfunctionsMustBeDocumented;

  /// No description provided for @topComplianceEldInspectionMode.
  ///
  /// In en, this message translates to:
  /// **'TOP COMPLIANCE ELD Inspection Mode'**
  String get topComplianceEldInspectionMode;

  /// No description provided for @anInspectorMayPressArrows.
  ///
  /// In en, this message translates to:
  /// **'An inspector may press arrows to view previous or next day'**
  String get anInspectorMayPressArrows;

  /// No description provided for @anInspectorMayViewThe.
  ///
  /// In en, this message translates to:
  /// **'An inspector may view the log form, the log graph and the log events with notes.'**
  String get anInspectorMayViewThe;

  /// No description provided for @exitTheInspectionModeBy.
  ///
  /// In en, this message translates to:
  /// **'Exit the inspection mode by pressing back arrow in the left top corner of the app.'**
  String get exitTheInspectionModeBy;

  /// No description provided for @topComplianceEldMalfunctionManual.
  ///
  /// In en, this message translates to:
  /// **'TOP COMPLIANCE ELD Malfunction Manual'**
  String get topComplianceEldMalfunctionManual;

  /// No description provided for @inAccordanceWithTheGuidelines.
  ///
  /// In en, this message translates to:
  /// **'In accordance with the guidelines set forth in 395.34'**
  String get inAccordanceWithTheGuidelines;

  /// No description provided for @malfunctionIndication.
  ///
  /// In en, this message translates to:
  /// **'Malfunction indication'**
  String get malfunctionIndication;

  /// No description provided for @immediatelyContactTheSupportIf.
  ///
  /// In en, this message translates to:
  /// **'Immediately contact the support if LED light on the device is off when the device is plugged into the diagnostic port or if the malfunction reported by the app.'**
  String get immediatelyContactTheSupportIf;

  /// No description provided for @noteTheMalfunction.
  ///
  /// In en, this message translates to:
  /// **'Note the malfunction'**
  String get noteTheMalfunction;

  /// No description provided for @noteTheMalfunctionAndProvide.
  ///
  /// In en, this message translates to:
  /// **'Note the malfunction and provide a written notice to your fleet within 24 hours.'**
  String get noteTheMalfunctionAndProvide;

  /// No description provided for @switchToPaperLogs.
  ///
  /// In en, this message translates to:
  /// **'Switch to paper logs'**
  String get switchToPaperLogs;

  /// No description provided for @keepAPaperLogFor.
  ///
  /// In en, this message translates to:
  /// **'Keep a paper log for that day and until the device is repaired or replaced. In the event of an inspection, display the previous 7 days from the app.'**
  String get keepAPaperLogFor;

  /// No description provided for @k8DaysRule.
  ///
  /// In en, this message translates to:
  /// **'8 days rule'**
  String get k8DaysRule;

  /// No description provided for @inTheEventOfAn.
  ///
  /// In en, this message translates to:
  /// **'In the event of an ELD malfunction, the motor carrier must take actions to correct the malfunction within 8 days of discovery.'**
  String get inTheEventOfAn;

  /// No description provided for @contactTheSupportTeamAt.
  ///
  /// In en, this message translates to:
  /// **'Contact the support team at topceld@gmail.com'**
  String get contactTheSupportTeamAt;

  /// No description provided for @eldUserManual.
  ///
  /// In en, this message translates to:
  /// **'ELD User Manual'**
  String get eldUserManual;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @installationAndSetup.
  ///
  /// In en, this message translates to:
  /// **'Installation and Setup'**
  String get installationAndSetup;

  /// No description provided for @logManagement.
  ///
  /// In en, this message translates to:
  /// **'Log Management'**
  String get logManagement;

  /// No description provided for @roadsideInspections.
  ///
  /// In en, this message translates to:
  /// **'Roadside Inspections'**
  String get roadsideInspections;

  /// No description provided for @electronicDriverVehicleInspectionReports.
  ///
  /// In en, this message translates to:
  /// **'Electronic Driver Vehicle Inspection Reports (DVIR)'**
  String get electronicDriverVehicleInspectionReports;

  /// No description provided for @fleetManagerPortal.
  ///
  /// In en, this message translates to:
  /// **'Fleet Manager Portal'**
  String get fleetManagerPortal;

  /// No description provided for @electronicLoggingDeviceEld.
  ///
  /// In en, this message translates to:
  /// **'Electronic Logging Device (ELD)'**
  String get electronicLoggingDeviceEld;

  /// No description provided for @recordsOfNdutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Records of\\nDuty Status'**
  String get recordsOfNdutyStatus;

  /// No description provided for @easilyManageYourDutyStatus.
  ///
  /// In en, this message translates to:
  /// **'Easily manage your duty status changes with our user-friendly ELD app. View, edit, and certify your logs.'**
  String get easilyManageYourDutyStatus;

  /// No description provided for @availableHoursAndNrequiredBreaks.
  ///
  /// In en, this message translates to:
  /// **'Available Hours and\\nRequired Breaks'**
  String get availableHoursAndNrequiredBreaks;

  /// No description provided for @stayInformedAboutYourAvailable.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about your available driving hours and mandatory rest breaks to ensure compliance.'**
  String get stayInformedAboutYourAvailable;

  /// No description provided for @roadsideInspectionNfunction.
  ///
  /// In en, this message translates to:
  /// **'Roadside Inspection\\nFunction'**
  String get roadsideInspectionNfunction;

  /// No description provided for @duringRoadsideInspectionsUseThe.
  ///
  /// In en, this message translates to:
  /// **'During roadside inspections, use the DOT Inspection mode in the app to share your logs with ease.'**
  String get duringRoadsideInspectionsUseThe;

  /// No description provided for @vehicleInspectionNreports.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Inspection\\nReports'**
  String get vehicleInspectionNreports;

  /// No description provided for @generatePreOrPostTrip.
  ///
  /// In en, this message translates to:
  /// **'Generate pre- or post-trip DVIRs within the app, notifying mechanics of any vehicle defects.'**
  String get generatePreOrPostTrip;

  /// No description provided for @setUpFleetNmanagerPortal.
  ///
  /// In en, this message translates to:
  /// **'Set Up Fleet\\nManager Portal'**
  String get setUpFleetNmanagerPortal;

  /// No description provided for @useYourCredentialsToSign.
  ///
  /// In en, this message translates to:
  /// **'Use your credentials to sign into the online portal, providing essential information about your company.'**
  String get useYourCredentialsToSign;

  /// No description provided for @monitorHosAndNfmcsaCompliance.
  ///
  /// In en, this message translates to:
  /// **'Monitor HOS and\\nFMCSA-Compliance'**
  String get monitorHosAndNfmcsaCompliance;

  /// No description provided for @stayOnTopOfDrivers.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of drivers'**
  String get stayOnTopOfDrivers;

  /// No description provided for @installEldHardware.
  ///
  /// In en, this message translates to:
  /// **'Install ELD Hardware'**
  String get installEldHardware;

  /// No description provided for @beginByLocatingTheEcm.
  ///
  /// In en, this message translates to:
  /// **'Begin by locating the ECM (diagnostic) port in your vehicle. Depending on your vehicle type, use the appropriate connection:'**
  String get beginByLocatingTheEcm;

  /// No description provided for @accessingLogs.
  ///
  /// In en, this message translates to:
  /// **'Accessing Logs'**
  String get accessingLogs;

  /// No description provided for @logInAndNavigateTo.
  ///
  /// In en, this message translates to:
  /// **'Log in and navigate to the '**
  String get logInAndNavigateTo;

  /// No description provided for @viewingLogs1.
  ///
  /// In en, this message translates to:
  /// **'Viewing Logs'**
  String get viewingLogs1;

  /// No description provided for @viewDetailedRodsForDifferent.
  ///
  /// In en, this message translates to:
  /// **'View detailed RODS for different dates.'**
  String get viewDetailedRodsForDifferent;

  /// No description provided for @editingLogs.
  ///
  /// In en, this message translates to:
  /// **'Editing Logs'**
  String get editingLogs;

  /// No description provided for @editDutyStatusEntriesExcept.
  ///
  /// In en, this message translates to:
  /// **'Edit duty status entries (except auto driving).'**
  String get editDutyStatusEntriesExcept;

  /// No description provided for @hosComplianceAlerts.
  ///
  /// In en, this message translates to:
  /// **'HOS Compliance Alerts'**
  String get hosComplianceAlerts;

  /// No description provided for @watchForTheRedExclamation.
  ///
  /// In en, this message translates to:
  /// **'• Watch for the red exclamation icon.\\n• Review a list of HOS violations below the log graph.'**
  String get watchForTheRedExclamation;

  /// No description provided for @createDvir.
  ///
  /// In en, this message translates to:
  /// **'Create DVIR'**
  String get createDvir;

  /// No description provided for @startNewInspectionMarkDefects.
  ///
  /// In en, this message translates to:
  /// **'Start new inspection, mark defects, add notes, and sign.'**
  String get startNewInspectionMarkDefects;

  /// No description provided for @editDvir.
  ///
  /// In en, this message translates to:
  /// **'Edit DVIR'**
  String get editDvir;

  /// No description provided for @selectAnExistingReportTo.
  ///
  /// In en, this message translates to:
  /// **'Select an existing report to edit.'**
  String get selectAnExistingReportTo;

  /// No description provided for @deleteDvir.
  ///
  /// In en, this message translates to:
  /// **'Delete DVIR'**
  String get deleteDvir;

  /// No description provided for @removeTheReportFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove the report from history.'**
  String get removeTheReportFromHistory;

  /// No description provided for @switchAction.
  ///
  /// In en, this message translates to:
  /// **'SWITCH'**
  String get switchAction;
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
