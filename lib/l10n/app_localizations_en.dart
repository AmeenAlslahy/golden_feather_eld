// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get auditTrail => 'Audit Trail';

  @override
  String get auditTrailNote =>
      'This log confirms every action is kept with the user, time, and previous/new values. It cannot be edited or deleted.';

  @override
  String get auditNoRecords => 'No Records';

  @override
  String get auditLoadFailed => 'Could not load the audit trail.';

  @override
  String get vehicleStatusOutOfService => 'OUT_OF_SERVICE';

  @override
  String get vehicleStatusRestricted => 'RESTRICTED';

  @override
  String get vehicleStatusAvailable => 'AVAILABLE';

  @override
  String get driverName => 'Driver Name';

  @override
  String get driverId => 'Driver ID';

  @override
  String get license => 'License';

  @override
  String get licenseState => 'License State';

  @override
  String get exemptDriver => 'Exempt Driver';

  @override
  String get unidentifiedDriving => 'Unidentified Driving';

  @override
  String get coDriverId => 'Co-Driver ID';

  @override
  String get logDate => 'Log Date';

  @override
  String get displayDate => 'Display Date';

  @override
  String get displayLocation => 'Display Location';

  @override
  String get eldRegId => 'ELD Registration ID';

  @override
  String get eldIdentifier => 'ELD Identifier';

  @override
  String get provider => 'Provider';

  @override
  String get periodStart => 'Period Start';

  @override
  String get dataDiag => 'Data Diag.';

  @override
  String get deviceMalf => 'Device Malf.';

  @override
  String get vin => 'VIN';

  @override
  String get carrier => 'Carrier';

  @override
  String get mainOffice => 'Main Office';

  @override
  String get homeTerminal => 'Home Terminal';

  @override
  String get insertDutyStatus => 'Insert Duty Status';

  @override
  String get addButton => 'ADD';

  @override
  String get eventAddedSuccess => 'Event added successfully';

  @override
  String get appName => 'Golden Feather ELD';

  @override
  String get appSlogan => 'Golden Feather - Field Compliance Tracking';

  @override
  String get trackingTitle => 'Tracking';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get statusTitle => 'Logs';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => 'Delete';

  @override
  String get retryButton => 'Retry';

  @override
  String get closeButton => 'Close';

  @override
  String get shareButton => 'Share';

  @override
  String get clearButton => 'Clear';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get locationButton => 'Send location';

  @override
  String get statusButton => 'Show status';

  @override
  String get settingsButton => 'Change settings';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get disabledValue => 'Disabled';

  @override
  String get idLabel => 'Device identifier';

  @override
  String get urlLabel => 'Server URL';

  @override
  String get accuracyLabel => 'Location accuracy';

  @override
  String get highestAccuracyLabel => 'Highest';

  @override
  String get highAccuracyLabel => 'High';

  @override
  String get mediumAccuracyLabel => 'Medium';

  @override
  String get lowAccuracyLabel => 'Low';

  @override
  String get intervalLabel => 'Interval (seconds)';

  @override
  String get fastestIntervalLabel => 'Fastest interval (seconds)';

  @override
  String get distanceLabel => 'Distance (meters)';

  @override
  String get angleLabel => 'Angle (degrees)';

  @override
  String get heartbeatLabel => 'Stationary heartbeat (seconds)';

  @override
  String get bufferLabel => 'Offline buffering';

  @override
  String get wakelockLabel => 'Wake lock';

  @override
  String get stopDetectionLabel => 'Stop detection';

  @override
  String get preferPlatformProvidersLabel => 'Use system location';

  @override
  String get serverNotConfigured => 'Server Not Configured';

  @override
  String get trackingLabel => 'Continuous tracking';

  @override
  String get advancedLabel => 'Advanced settings';

  @override
  String get passwordLabel => 'Password';

  @override
  String get optimizationMessage =>
      'To ensure reliable tracking, please disable battery optimization for this app.';

  @override
  String get passwordError => 'Wrong password';

  @override
  String get disclosureMessage =>
      'This app collects location and activity data in the background and sends it to the configured server.';

  @override
  String get configurationMessage => 'Apply new configuration?';

  @override
  String get startAction => 'Start';

  @override
  String get stopAction => 'Stop service';

  @override
  String get sosAction => 'Send SOS';

  @override
  String get home => 'Home';

  @override
  String get inspection => 'Inspection';

  @override
  String get checklist => 'Checklist';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get startInspection => 'Start Inspection';

  @override
  String get stopInspection => 'Stop Inspection';

  @override
  String get pauseInspection => 'Pause';

  @override
  String get resumeInspection => 'Resume';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get saveDraft => 'Save as Draft';

  @override
  String get discardDraft => 'Discard Draft';

  @override
  String get inspectionTitle => 'Inspection Title';

  @override
  String get inspectionLocation => 'Inspection Location';

  @override
  String get inspectionDate => 'Inspection Date';

  @override
  String get inspectionTime => 'Inspection Time';

  @override
  String get inspectionDuration => 'Inspection Duration';

  @override
  String get inspectorName => 'Inspector Name';

  @override
  String get inspectionStatus => 'Inspection Status';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusRequiresReview => 'Requires Review';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get checklistTitle => 'Checklist Title';

  @override
  String get checklistCategory => 'Checklist Category';

  @override
  String get addChecklist => 'Add Checklist';

  @override
  String get editChecklist => 'Edit Checklist';

  @override
  String get deleteChecklist => 'Delete Checklist';

  @override
  String get checklistItems => 'Checklist Items';

  @override
  String get addItem => 'Add Item';

  @override
  String get removeItem => 'Remove Item';

  @override
  String get itemTypeText => 'Text';

  @override
  String get itemTypeNumber => 'Number';

  @override
  String get itemTypeYesNo => 'Yes / No';

  @override
  String get itemTypeMultipleChoice => 'Multiple Choice';

  @override
  String get itemTypePhoto => 'Photo';

  @override
  String get itemTypeSignature => 'Signature';

  @override
  String get itemTypeDate => 'Date';

  @override
  String get itemTypeTime => 'Time';

  @override
  String get itemTypeBarcode => 'Barcode';

  @override
  String get photoRequired => 'Photo required';

  @override
  String get signatureRequired => 'Signature required';

  @override
  String get notesRequired => 'Notes required';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get photoPreview => 'Photo Preview';

  @override
  String get signHere => 'Sign Here';

  @override
  String get clearSignature => 'Clear signature';

  @override
  String get signaturePreview => 'Signature Preview';

  @override
  String get addNote => 'Add Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get synced => 'Synced';

  @override
  String get syncing => 'Syncing...';

  @override
  String syncPending(String count) {
    return '$count pending';
  }

  @override
  String syncFailed(String count) {
    return '$count failed';
  }

  @override
  String get offline => 'Offline';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get errorMessage => 'An error occurred';

  @override
  String get successMessage => 'Operation completed successfully';

  @override
  String get warningMessage => 'Warning';

  @override
  String get infoMessage => 'Information';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get noResults => 'No results found';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get locationPermissionDenied => 'Please grant location permission';

  @override
  String get cameraPermissionDenied => 'Please grant camera permission';

  @override
  String get storagePermissionDenied => 'Please grant storage permission';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get confirmSubmit => 'Are you sure you want to submit the report?';

  @override
  String get confirmDiscard => 'Are you sure you want to discard changes?';

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get changesWillBeLost => 'Changes will be lost if you continue';

  @override
  String get languageLabel => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System Mode';

  @override
  String get themeLabel => 'Theme';

  @override
  String get aboutLabel => 'About';

  @override
  String get versionLabel => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get help => 'Help';

  @override
  String get faq => 'FAQ';

  @override
  String get qrCodeScanner => 'QR Scanner';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get scanningInstructions => 'Point the camera at a QR code';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByStatus => 'Status';

  @override
  String get exportPDF => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get print => 'Print';

  @override
  String get notifications => 'Notifications';

  @override
  String get newInspectionAssigned => 'New inspection assigned';

  @override
  String get inspectionReminder => 'Inspection reminder';

  @override
  String get inspectionOverdue => 'Inspection overdue';

  @override
  String get syncComplete => 'Sync completed';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get na => 'N/A';

  @override
  String get pass => 'Pass';

  @override
  String get fail => 'Fail';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get unableToConnect => 'Unable to connect to ELD with MAC';

  @override
  String get verifyFollowingItems => 'Please verify the following items:';

  @override
  String get macEnteredCorrectly => 'ELD MAC address is entered correctly.';

  @override
  String get hardwareProperlyInstalled => 'ELD hardware is properly installed.';

  @override
  String get vehiclePowerOn => 'Vehicle power is ON.';

  @override
  String get bluetoothEnabled => 'Bluetooth is enabled on the mobile device.';

  @override
  String get gpsEnabled => 'GPS is enabled on the mobile device.';

  @override
  String get enterMacAddress => 'Enter ELD MAC address listed on the device:';

  @override
  String get connect => 'CONNECT';

  @override
  String get continueDisconnected => 'CONTINUE DISCONNECTED';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get hoursRecap => 'Hours Recap';

  @override
  String get suggestedEvents => 'Suggested Events';

  @override
  String get unidentifiedEvents => 'Unidentified Events';

  @override
  String get unclaimed => 'UNCLAIMED';

  @override
  String get rejected => 'REJECTED';

  @override
  String get noRecords => 'No Records';

  @override
  String get drawSignatureHere => 'Draw your signature here';

  @override
  String get fillFormFirst => 'You need to fill and save form first.';

  @override
  String get formLabel => 'Form';

  @override
  String get certifyLabel => 'Certify';

  @override
  String get editDutyStatus => 'Edit Duty Status';

  @override
  String get startTime => 'Start Time';

  @override
  String get duration => 'Duration';

  @override
  String get status => 'Status';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get location => 'Location';

  @override
  String get manualLocation => 'Manual Location';

  @override
  String get events => 'Events';

  @override
  String get form => 'Form';

  @override
  String get certify => 'Certify';

  @override
  String get driver => 'Driver';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get trailers => 'Trailers';

  @override
  String get shippingDocuments => 'Shipping Documents';

  @override
  String get coDriver => 'Co-Driver';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get certifyDeclaration =>
      'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.';

  @override
  String get notReady => 'NOT READY';

  @override
  String get agree => 'AGREE';

  @override
  String get timeline24h => '24-Hour Timeline';

  @override
  String get settingsAppliedSuccess => 'Settings applied successfully';

  @override
  String get deviceInformation => 'Device Information';

  @override
  String get confirmClearLogs => 'Are you sure you want to clear all logs?';

  @override
  String get trackingStatus => 'Tracking Status';

  @override
  String get activeStatus => 'Active';

  @override
  String get stoppedStatus => 'Stopped';

  @override
  String get coordinatesLabel => 'Coordinates';

  @override
  String get lastUpdateLabel => 'Last Update';

  @override
  String get locationDisabled => 'Location Disabled';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get available => 'Available';

  @override
  String get recap => 'Recap';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get errorCannotChangeStatusWhileMoving =>
      'Cannot change status while the vehicle is moving.';

  @override
  String get customLocation => 'Custom location';

  @override
  String get notes => 'Notes';

  @override
  String get updateButton => 'UPDATE';

  @override
  String get offDuty => 'Off Duty';

  @override
  String get sleeperBerth => 'Sleeper';

  @override
  String get drivingStatus => 'Driving';

  @override
  String get onDuty => 'On Duty';

  @override
  String get personalUse => 'Personal Use';

  @override
  String get yardMoves => 'Yard Moves';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerInstructions => 'Point the camera at the QR code';

  @override
  String get logsTitle => 'Logs';

  @override
  String get total => 'Total';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get hoursWorkedToday => 'Hours Worked Today';

  @override
  String get hoursAvailableToday => 'Hours Available Today';

  @override
  String get hoursAvailableTomorrow => 'Hours Available Tomorrow';

  @override
  String get registerAction => 'Register';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameRequired => 'Full Name is required';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginHere => 'Login here';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get notImplemented => 'This feature is not implemented yet';

  @override
  String get dvirTitle => 'Vehicle Inspection (DVIR)';

  @override
  String get inspectionType => 'Inspection Type';

  @override
  String get vehicleInfo => 'Vehicle Information';

  @override
  String get mechanicalChecklist => 'Mechanical Checklist';

  @override
  String get additionalNotes => 'Additional Notes';

  @override
  String get vehicleCondition => 'Vehicle Condition Assessment';

  @override
  String get driverSignature => 'Driver Signature';

  @override
  String get saveReport => 'Save Report';

  @override
  String get updateReport => 'Update Report';

  @override
  String get newReport => 'New Inspection Report';

  @override
  String get editReport => 'Edit Report';

  @override
  String get noDvirReports => 'No Inspection Reports';

  @override
  String get createNewReport => 'Create New Report';

  @override
  String get reportSavedSuccess => 'Inspection report saved successfully';

  @override
  String get defectsFound => 'Defects Found';

  @override
  String get submitted => 'Submitted';

  @override
  String get draft => 'Draft';

  @override
  String get trailer => 'Trailer';

  @override
  String get odometerReading => 'Odometer Reading';

  @override
  String get dtcCodes => 'Engine Diagnostic Codes (DTC)';

  @override
  String get notesHint => 'Any additional notes about vehicle condition...';

  @override
  String get dateLabel => 'Date';

  @override
  String get selectVehicle => 'Select Vehicle';

  @override
  String get searchVehicle => 'Search vehicles...';

  @override
  String get noVehiclesFound => 'No vehicles available';

  @override
  String get vehicleSelected => 'Vehicle selected';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get underDevelopment => 'Under Development...';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get miles => 'miles';

  @override
  String get hour => 'hour';

  @override
  String get minute => 'minute';

  @override
  String get newInspectionReport => 'New Inspection Report';

  @override
  String get editInspectionReport => 'Edit Inspection Report';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get notAvailable => 'N/A';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get account => 'Account';

  @override
  String get rules => 'Rules';

  @override
  String get infoPacket => 'Info Packet';

  @override
  String get odometer => 'Odometer';

  @override
  String get engineHours => 'Engine Hours';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get dotInspection => 'DOT Inspection';

  @override
  String get setInspectionPin => 'Set Inspection PIN';

  @override
  String get enter4DigitPin => 'Enter 4-digit PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get enterPinToUnlock => 'Enter PIN to Unlock';

  @override
  String get unlock => 'Unlock';

  @override
  String get dotInspectionMode => 'DOT Inspection Mode';

  @override
  String get screenLockedForOfficer => 'Screen locked for officer review';

  @override
  String get unlockDriverOnly => 'Unlock (Driver Only)';

  @override
  String get sendLogs => 'Send Logs';

  @override
  String get emailLogs => 'Email Logs';

  @override
  String get endInspection => 'End Inspection';

  @override
  String get certified => 'Certified';

  @override
  String get eldReport => 'ELD Report';

  @override
  String get hosReport => 'HOS Report';

  @override
  String get compliant => 'Compliant';

  @override
  String get nonCompliant => 'Non-Compliant';

  @override
  String get work => 'Work';

  @override
  String get rest => 'Rest';

  @override
  String get break_ => 'Break';

  @override
  String get distance => 'Distance';

  @override
  String get malfunctionAlerts => 'Malfunction Alerts';

  @override
  String get clearAll => 'Clear All';

  @override
  String get pdfExportedSuccess => 'PDF exported successfully';

  @override
  String get userManual => 'User Manual';

  @override
  String get instructions => 'Instructions';

  @override
  String get malfunctionManual => 'Malfunction Manual';

  @override
  String get viewUserManual => 'View User Manual';

  @override
  String get viewInstructions => 'View Instructions';

  @override
  String get viewMalfunctionManual => 'View Malfunction Manual';

  @override
  String get legalNotice =>
      'These documents are required by approved fleet management standards. They must be available at all times while operating a commercial vehicle.';

  @override
  String get gettingStarted => 'Getting Started';

  @override
  String get connectingToVehicle => 'Connecting to Vehicle';

  @override
  String get changingDutyStatus => 'Changing Duty Status';

  @override
  String get viewingLogs => 'Viewing Logs & Certification';

  @override
  String get vehicleInspection => 'Vehicle Inspection (DVIR)';

  @override
  String get roadsideInspection => 'Roadside Inspection';

  @override
  String get continueWithout => 'Continue Without';

  @override
  String get grant => 'Grant';

  @override
  String get time => 'Time';

  @override
  String get odom => 'Odom.';

  @override
  String get eng => 'Eng.';

  @override
  String get src => 'Src';

  @override
  String get noManualModifications =>
      'No manual modifications found for this date.';

  @override
  String get failedToLoadAudits => 'Failed to load audits';

  @override
  String get exportErods => 'Export as eRODS (XML/CSV)';

  @override
  String get requiredForFmcsa => 'Required for FMCSA inspection';

  @override
  String changeStatusTo(String status) {
    return 'Change status to $status';
  }

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get noRecordsToday => 'No records for today';

  @override
  String get trackingNotStarted => 'Tracking has not started yet';

  @override
  String get gpsDisabled => 'GPS is disabled';

  @override
  String get notConnectedToServer => 'Not connected to server';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get loadingRecords => 'Loading records...';

  @override
  String get defectsTitle => 'Defects';

  @override
  String get vehicleConditionSatisfactory => 'Vehicle Condition Satisfactory';

  @override
  String auditReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String auditStatusChange(String oldStatus, String newStatus) {
    return '$oldStatus -> $newStatus';
  }

  @override
  String get calculatingLocation => 'Calculating location...';

  @override
  String get driveLimitTitle => 'DRIVE';

  @override
  String get driveLimitDesc => '11-Hour Driving Limit';

  @override
  String get shiftLimitTitle => 'SHIFT';

  @override
  String get shiftLimitDesc => '14-Hour On Duty Limit';

  @override
  String get breakLimitTitle => 'BREAK';

  @override
  String get breakLimitDesc => '30 Minute Rest Break';

  @override
  String get cycleLimitTitle => 'CYCLE';

  @override
  String get cycleLimitDesc => 'USA 70/8';

  @override
  String get hoursOfService => 'HOURS OF SERVICE';

  @override
  String get sessionExpired => 'Session expired, please login again';

  @override
  String get invalidConfiguration => 'Invalid server configuration';

  @override
  String get invalidCredentials => 'Invalid username or password';

  @override
  String get sessionMissing => 'Session missing, please login again';

  @override
  String get interfaceLanguage => 'Interface language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get enterServerUrl => 'Enter the server URL.';

  @override
  String get invalidServerUrl =>
      'Invalid URL. Example: https://server.example.com';

  @override
  String get serverUrlSaved => 'Server URL saved.';

  @override
  String get formIncomplete => 'Form is incomplete, please fill all fields.';

  @override
  String get sixteenHourCondition =>
      'The 16-hour exception cannot be enabled unless its conditions are met.';

  @override
  String get rulesUpdated => 'Rules updated successfully';

  @override
  String get allowed => 'Allowed';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get notProvidedByServer => 'Not provided by the server';

  @override
  String get ruleSource => 'Rule Source';

  @override
  String get cycleRule => 'Cycle Rule';

  @override
  String get cargoType => 'Cargo Type';

  @override
  String get restartRule => 'Restart';

  @override
  String get restBreakRule => 'Rest Break';

  @override
  String get sixteenHourException => '16-Hour Short-Haul Exception';

  @override
  String get dailyLimits => 'Daily Limits';

  @override
  String get drivingLimit => 'Driving';

  @override
  String get shiftWindowLimit => 'Shift window';

  @override
  String get cycleLimit => 'Cycle';

  @override
  String get hourAbbr => 'h';

  @override
  String get minAbbr => 'm';

  @override
  String get contactFleetManager => 'Contact your fleet manager for more info.';

  @override
  String get personalConveyance => 'Personal Conveyance';

  @override
  String get unlimitedTrailers => 'Unlimited Trailers';

  @override
  String get unlimitedShippingDocs => 'Unlimited Shipping Documents';

  @override
  String get aboutTitle => 'About';

  @override
  String get applicationInfo => 'Application';

  @override
  String get appNameLabel => 'Name';

  @override
  String get appVersionLabel => 'Version';

  @override
  String get appPackageLabel => 'Package';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get diagnosticsAndConnection => 'Diagnostics';

  @override
  String get centralServer => 'Central server';

  @override
  String get locationService => 'Location service (GPS)';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get hardwareAlerts => 'Hardware alerts';

  @override
  String get noActiveAlerts => 'No active alerts';

  @override
  String get activeAlerts => 'Active alerts';

  @override
  String get technicalInfo => 'Technical Info';

  @override
  String get eldEngineVersion => 'ELD Engine Version';

  @override
  String get hardwareVersion => 'Hardware Version';

  @override
  String get lastDataReceived => 'Last Data Received';

  @override
  String get eldConnectionStatus => 'ELD Connection Status';

  @override
  String get refresh => 'Refresh';

  @override
  String get supportText =>
      'For technical support, provide the device ID and version shown above.';

  @override
  String get noVehiclesAssigned => 'No Vehicles Assigned';

  @override
  String get vehiclesAssignedViaPortal =>
      'Vehicles are assigned via the portal. ';

  @override
  String get viewMyVehicles => 'VIEW MY VEHICLES';

  @override
  String get viewAllVehicles => 'VIEW ALL VEHICLES';

  @override
  String vehicleSelectedConnect(String name) {
    return 'Selected $name. Connect to the ELD to operate it. Hours were not copied.';
  }

  @override
  String get inUse => 'In use';

  @override
  String get viewOnly => 'View only';

  @override
  String get assignedToYou => 'Assigned to you';

  @override
  String get errMotionUnknown =>
      'Vehicle motion is unknown. That is not treated as stopped.';

  @override
  String get errVehicleMoving =>
      'The vehicle cannot be changed while moving. Hours were not copied.';

  @override
  String get errIdentifierMissing =>
      'The server did not return a vehicle identifier. One will not be invented.';

  @override
  String get errThresholdMissing => 'The motion threshold is not available.';

  @override
  String get errUnauthorized =>
      'You are not authorized to operate this vehicle.';

  @override
  String get errUnavailable => 'Vehicle unavailable.';

  @override
  String get errInUse => 'The vehicle is in use.';

  @override
  String get errRejected => 'The server rejected vehicle operation.';

  @override
  String get errListUnreadable => 'The vehicle list could not be read.';

  @override
  String get nA => 'N/A';

  @override
  String get email1 => 'Email';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get mainOfficeAddress => 'Main Office Address';

  @override
  String get homeTerminalAddress => 'Home Terminal Address';

  @override
  String get timeZone => 'Time Zone';

  @override
  String get language => 'Language';

  @override
  String get languageUpdatedSuccessfully => 'Language updated successfully';

  @override
  String get odometerUnitUpdatedSuccessfull =>
      'Odometer unit updated successfully';

  @override
  String get pleaseContactYourFleetManagerT =>
      'Please contact your fleet manager to change your\\naccount information.';

  @override
  String get thePacketIsIncomplete => 'The packet is incomplete.';

  @override
  String get inspectionMode => 'Inspection Mode';

  @override
  String get dataTransferInstructionSheet => 'Data Transfer Instruction Sheet';

  @override
  String get malfunctionManual39534 => 'Malfunction Manual (395.34)';

  @override
  String get goldenFeatherEldInspectionMode =>
      'Golden Feather ELD Inspection Mode';

  @override
  String get tapDotInspectionInTheMenuPress =>
      'Tap \"DOT Inspection\" in the menu & press \"Start Inspection\". Let an officer to view your logs directly from your mobile device. Show this instruction card if requested.';

  @override
  String get anInspectorMayPressArrowsToVie =>
      'An inspector may press arrows to view previous or next day\\';

  @override
  String get theOfficerCannotLeaveInspectio =>
      'The officer cannot leave inspection. The driver exits with Driver Exit after entering the account password.';

  @override
  String get goldenFeatherEldIsCapableOfPro =>
      'Golden Feather ELD is capable of producing and transferring the ELD records via telematics transfer methods: Wireless Web services and Email. In order to send the ELD records via Web services a driver must press \"DOT Inspection\" menu item and then press \"Send Logs\" button. In order to send the ELD records via Email a driver must press \"DOT Inspection\" menu item, press \"Email Logs\", enter an email provided by an authorized safety official and press \"Send\" button.';

  @override
  String get goldenFeatherEldMalfunctionMan =>
      'Golden Feather ELD Malfunction Manual';

  @override
  String get inAccordanceWithTheGuidelinesS =>
      'In accordance with the guidelines set forth in 395.34';

  @override
  String get malfunctionIndication => 'Malfunction indication';

  @override
  String get immediatelyContactTheSupportIf =>
      'Immediately contact the support if LED light on the device is off when the device is plugged into the diagnostic port or if the malfunction reported by the app.';

  @override
  String get noteTheMalfunction => 'Note the malfunction';

  @override
  String get noteTheMalfunctionAndProvideAW =>
      'Note the malfunction and provide a written notice to your fleet within 24 hours.';

  @override
  String get switchToPaperLogs => 'Switch to paper logs';

  @override
  String get k8DaysRule => '8 days rule';

  @override
  String get contactTheSupportTeamAtTopceld =>
      'Contact the support team at topceld@gmail.com';

  @override
  String get eldUserManual => 'ELD User Manual';

  @override
  String get features => 'Features';

  @override
  String get installationAndSetup => 'Installation and Setup';

  @override
  String get logManagement => 'Log Management';

  @override
  String get roadsideInspections => 'Roadside Inspections';

  @override
  String get electronicDriverVehicleInspect =>
      'Electronic Driver Vehicle Inspection Reports (DVIR)';

  @override
  String get fleetManagerPortal => 'Fleet Manager Portal';

  @override
  String get electronicLoggingDeviceEld => 'Electronic Logging Device (ELD)';

  @override
  String get recordsOfNdutyStatus => 'Records of\\nDuty Status';

  @override
  String get easilyManageYourDutyStatusChan =>
      'Easily manage your duty status changes with our user-friendly ELD app. View, edit, and certify your logs for accurate and compliant records.';

  @override
  String get availableHoursAndNrequiredBrea =>
      'Available Hours and\\nRequired Breaks';

  @override
  String get stayInformedAboutYourAvailable =>
      'Stay informed about your available driving hours and mandatory rest breaks to ensure compliance with HOS regulations.';

  @override
  String get interAndIntrastateNhosRules => 'Inter- and Intrastate\\nHOS Rules';

  @override
  String get ourAppSupportsBothInterAndIntr =>
      'Our app supports both inter- and intrastate HOS rules, providing you with the flexibility to comply with specific regulations.';

  @override
  String get roadsideInspectionNfunction => 'Roadside Inspection\\nFunction';

  @override
  String get duringRoadsideInspectionsUseTh =>
      'During roadside inspections, use the DOT Inspection mode in the app to share your logs with ease.';

  @override
  String get vehicleInspectionNreports => 'Vehicle Inspection\\nReports';

  @override
  String get generatePreOrPostTripDvirsWith =>
      'Generate pre- or post-trip DVIRs within the app, notifying mechanics of any vehicle defects promptly.';

  @override
  String get onlineFleetNmanagerPortal => 'Online Fleet\\nManager Portal';

  @override
  String get accessTheFleetManagerPortalToM =>
      'Access the Fleet Manager Portal to monitor HOS compliance, view real-time data on driver duty status, and receive notifications on HOS violations.';

  @override
  String get gpsTracking => 'GPS Tracking';

  @override
  String get trackYourVehicle => 'Track your vehicle\\';

  @override
  String get iftaCalculations => 'IFTA Calculations';

  @override
  String get automaticallyCalculateIftaData =>
      'Automatically calculate IFTA data to simplify fuel tax reporting for interstate carriers.';

  @override
  String get setUpFleetNmanagerPortal => 'Set Up Fleet\\nManager Portal';

  @override
  String get useYourCredentialsToSignIntoTh =>
      'Use your credentials to sign into the online portal, providing essential information about your company, portal users, drivers, and vehicles.';

  @override
  String get monitorHosAndNfmcsaCompliance =>
      'Monitor HOS and\\nFMCSA-Compliance';

  @override
  String get stayOnTopOfDrivers => 'Stay on top of drivers\\';

  @override
  String get preconfiguredStatuses => 'Preconfigured Statuses';

  @override
  String get customizeDutyStatusesAccessByS =>
      'Customize duty statuses access by setting Yard Move and Personal Use as valid options.';

  @override
  String get driverAndVehicleInformation => 'Driver and Vehicle Information';

  @override
  String get trackYourDrivers => 'Track your drivers\\';

  @override
  String get downloadAndTransferLogs => 'Download and Transfer Logs';

  @override
  String get downloadAnyDrivers => 'Download any drivers\\';

  @override
  String get filterLogs => 'Filter Logs';

  @override
  String get saveTimeByQuicklyFindingLogsBy =>
      'Save time by quickly finding logs by date, driver, or vehicle using the filter option.';

  @override
  String get installEldHardware => 'Install ELD Hardware';

  @override
  String get beginByLocatingTheEcmDiagnosti =>
      'Begin by locating the ECM (diagnostic) port in your vehicle. This port is typically found on or near the dashboard, under the steering column, or close to the driver\\';

  @override
  String get installEldSoftware => 'Install ELD Software';

  @override
  String get beforeYouStartUsingTheEldEnsur =>
      'Before you start using the ELD, ensure that your mobile device is connected to the internet and Bluetooth is enabled:\\n\\n• Installing the ELD Software: Download the ELD app from your device\\';

  @override
  String get hoursOfService1 => 'Hours of Service';

  @override
  String get onceTheEldIsSetUpItAutomatical =>
      'Once the ELD is set up, it automatically records driving time. Any movement at 5 mph or faster is logged as driving. When stationary, the driver can select a different duty status. The system calculates and displays:\\n\\n• On-Duty Limits\\n• Available Driving Time\\n• Required Breaks and Off-Duty Periods\\n\\nThis information is shown in the app\\';

  @override
  String get accessingLogs => 'Accessing Logs';

  @override
  String get logInToTheEldAppWithYourUnique =>
      'Log in to the ELD app with your unique credentials and navigate to the \"Logs\" section to access your electronic HOS records.';

  @override
  String get viewingLogs1 => 'Viewing Logs';

  @override
  String get viewDetailedRodsForDifferentDa =>
      'View detailed RODS for different dates, including time, duration, and location of each duty status change.';

  @override
  String get editingLogs => 'Editing Logs';

  @override
  String get editDutyStatusEntriesExceptFor =>
      'Edit duty status entries (except for the automatically recorded driving logs) to ensure accuracy. Simply tap on a date, use the pencil icon to make changes, and save your edits.';

  @override
  String get certifyingLogs => 'Certifying Logs';

  @override
  String get certifyingLogsEndYourShiftByDi =>
      'Certifying Logs: End your shift by digitally certifying your logs for accuracy and compliance with the tap of a button.';

  @override
  String get duringARoadsideInspectionFollo =>
      'During a roadside inspection, follow these steps:\\n\\n• Access \"DOT Inspection\" mode from the Main Menu.\\n• Tap \"Start Inspection\" to display your Records of Duty Status (RODS) to the officer.\\n• Use the navigation arrows to review logs by date.\\n• If requested, send your RODS via web services or email by selecting the \"Send\" button.\\n• Once the inspection is complete, tap \"Back\" to return to your regular logs.';

  @override
  String get hosComplianceAlerts => 'HOS Compliance Alerts';

  @override
  String get stayCompliantWithHosRegulation =>
      'Stay compliant with HOS regulations by monitoring alerts:\\n\\n• On the main logs screen, watch for the red exclamation icon, which signals an HOS violation or Form/Certification warning.\\n• Review a list of HOS violations by scrolling below the log graph. Tapping on a violation provides more details.';

  @override
  String get createDvir => 'Create DVIR';

  @override
  String get createANewInspectionReportNNAc =>
      'Create a New Inspection Report:\\n\\n• Access the Menu and select DVIR.\\n• Tap the plus sign to start a new inspection.\\n• Review the list of vehicle components and mark any with detected defects.\\n• Add notes in the Remarks section if needed.\\n• Tap Sign to finalize and save the report in the DVIR history.';

  @override
  String get editDvir => 'Edit DVIR';

  @override
  String get editAnExistingReportNNGoToDvir =>
      'Edit an existing Report:\\n\\n• Go to DVIR History and select the report you wish to edit.\\n• Click the \"...\" button.\\n• Choose Edit to make changes.';

  @override
  String get deleteDvir => 'Delete DVIR';

  @override
  String get deleteAnExistingReportNNInDvir =>
      'Delete an existing Report:\\n\\n• In DVIR History, select the report to delete.\\n• Click the \"...\" button.\\n• Choose Remove and confirm the deletion.';

  @override
  String get infoPacketManualBlurb =>
      'The user\'s manual, instruction sheet, and malfunction instruction sheet can be in electronic form. This is in accordance with the federal register titled \"Regulatory Guidance Concerning Electronic Signatures and Documents\" (76 FR 411).';

  @override
  String get infoPacketInstructionsBlurb =>
      'In addition to the above, a supply of blank driver\'s records of duty status (RODS) graph-grids sufficient to record the driver\'s duty status and other related information for a minimum of 8 days must be onboard the commercial motor vehicle (CMV).';

  @override
  String packetIncompleteMissing(String missing) {
    return 'Packet incomplete: $missing';
  }

  @override
  String get recordsOfDutyStatus => 'Records of\nDuty Status';

  @override
  String get availableHoursAndRequiredBreaks =>
      'Available Hours and\nRequired Breaks';

  @override
  String get interAndIntrastateHosRules => 'Inter- and Intrastate\nHOS Rules';

  @override
  String get roadsideInspectionFunction => 'Roadside Inspection\nFunction';

  @override
  String get vehicleInspectionReports => 'Vehicle Inspection\nReports';

  @override
  String get onlineFleetManagerPortal => 'Online Fleet\nManager Portal';

  @override
  String get trackYourVehicleSLocationIn =>
      'Track your vehicle\'s location in real-time for improved fleet management and security.';

  @override
  String get setUpFleetManagerPortal => 'Set Up Fleet\nManager Portal';

  @override
  String get monitorHosAndFmcsaCompliance =>
      'Monitor HOS and\nFMCSA-Compliance';

  @override
  String get stayOnTopOfDriversDuty =>
      'Stay on top of drivers\' duty status and remaining hours in real-time. Receive notifications about HOS violations and access archived violation records.';

  @override
  String get trackYourDriversCurrentOrLast =>
      'Track your drivers\' current or last location, the vehicle driven, and their contact information effortlessly.';

  @override
  String get downloadAnyDriversLogsInPdf =>
      'Download any drivers\' logs in PDF format with a few clicks. In case of a roadside inspection, easily send logs to an FMCSA officer from the online portal.';

  @override
  String get beginByLocatingTheEcmDiagnostic =>
      'Begin by locating the ECM (diagnostic) port in your vehicle. This port is typically found on or near the dashboard, under the steering column, or close to the driver\'s seat. Depending on your vehicle type, use the appropriate connection:\n\n• 6-pin Connector: Common in older commercial vehicles.\n• 9-pin Connector: Standard in most modern commercial trucks.\n• OBDII Connector: Typically found in light commercial vehicles and passenger cars.\n\nOnce you\'ve identified the correct connector, securely attach the ELD hardware to the port using the appropriate cable provided. Ensure the ELD device is firmly mounted on your dashboard where it remains visible and accessible for operation. This placement is crucial for ease of use during your driving and inspection processes.';

  @override
  String get beforeYouStartUsingTheEld =>
      'Before you start using the ELD, ensure that your mobile device is connected to the internet and Bluetooth is enabled:\n\n• Installing the ELD Software: Download the ELD app from your device\'s app store and follow the on-screen instructions to complete the installation.\n• Logging In: Use your provided credentials to access the app. If you encounter login issues, verify your credentials with your fleet manager or contact customer support.\n• Syncing Your Device with ELD Hardware: After logging in, select your vehicle from the list to sync your mobile device with the ELD hardware.';

  @override
  String get onceTheEldIsSetUp =>
      'Once the ELD is set up, it automatically records driving time. Any movement at 5 mph or faster is logged as driving. When stationary, the driver can select a different duty status. The system calculates and displays:\n\n• On-Duty Limits\n• Available Driving Time\n• Required Breaks and Off-Duty Periods\n\nThis information is shown in the app\'s Status section for drivers and in the online portal for fleet managers, ensuring compliance with HOS regulations.';

  @override
  String get duringARoadsideInspectionFollowThese =>
      'During a roadside inspection, follow these steps:\n\n• Access \"DOT Inspection\" mode from the Main Menu.\n• Tap \"Start Inspection\" to display your Records of Duty Status (RODS) to the officer.\n• Use the navigation arrows to review logs by date.\n• If requested, send your RODS via web services or email by selecting the \"Send\" button.\n• Once the inspection is complete, tap \"Back\" to return to your regular logs.';

  @override
  String get stayCompliantWithHosRegulationsBy =>
      'Stay compliant with HOS regulations by monitoring alerts:\n\n• On the main logs screen, watch for the red exclamation icon, which signals an HOS violation or Form/Certification warning.\n• Review a list of HOS violations by scrolling below the log graph. Tapping on a violation provides more details.';

  @override
  String get createANewInspectionReportAccess =>
      'Create a New Inspection Report:\n\n• Access the Menu and select DVIR.\n• Tap the plus sign to start a new inspection.\n• Review the list of vehicle components and mark any with detected defects.\n• Add notes in the Remarks section if needed.\n• Tap Sign to finalize and save the report in the DVIR history.';

  @override
  String get editAnExistingReportGoTo =>
      'Edit an existing Report:\n\n• Go to DVIR History and select the report you wish to edit.\n• Click the \"...\" button.\n• Choose Edit to make changes.';

  @override
  String get deleteAnExistingReportInDvir =>
      'Delete an existing Report:\n\n• In DVIR History, select the report to delete.\n• Click the \"...\" button.\n• Choose Remove and confirm the deletion.';

  @override
  String get pleaseContactYourFleetManagerTo =>
      'Please contact your fleet manager to change your\naccount information.';

  @override
  String todayLogDate(Object date) {
    return 'Today - $date';
  }

  @override
  String get enterTheTrailerNumber => 'Enter the trailer number.';

  @override
  String get trailerNumberMustBeLettersNumbers =>
      'Trailer number must be letters, numbers, or hyphens (max 50).';

  @override
  String get enterTheDocumentNumber => 'Enter the document number.';

  @override
  String get shippingDocumentNumberIsTooLong =>
      'Shipping document number is too long (max 100).';

  @override
  String get enterOneDocumentAtATime =>
      'Enter one document at a time (no comma).';

  @override
  String get reasonForChange => 'Reason for Change';

  @override
  String get enterReasonRequired => 'Enter reason (Required)';

  @override
  String get aReasonForTheChangeIs => 'A reason for the change is required.';

  @override
  String get cannotSaveDriverSessionNotFound =>
      'Cannot save: driver session not found.';

  @override
  String get automaticDrivingTimeCannotBeShortened =>
      'Automatic driving time cannot be shortened or removed.';

  @override
  String get eventSavedSuccessfully => 'Event saved successfully';

  @override
  String get reCertificationRequiredEditsWereMade =>
      'Re-certification Required: Edits were made after your last signature.';

  @override
  String get typeHere => 'Type here';

  @override
  String get noDocumentsAdded => 'No documents added';

  @override
  String get delete => 'DELETE';

  @override
  String get carrierProposedEdits39530Are =>
      'Carrier-proposed edits (§395.30) are reviewed inside each log on the Certify tab (Accept / Reject).';

  @override
  String get unidentifiedDrivingIsReviewedInUnidentified =>
      'Unidentified driving is reviewed in Unidentified Events.';

  @override
  String get noTrailersAdded => 'No trailers added';

  @override
  String get noVehicleIsSelected => 'No vehicle is selected.';

  @override
  String get anAnnotationIsRequired => 'An annotation is required.';

  @override
  String get yourRecordWasUpdatedReviewThe =>
      'Your record was updated. Review the daily log; it may need re-certification.';

  @override
  String get assume => 'ASSUME';

  @override
  String get requiredAnnotationThisTimeIsAssumed =>
      'Required annotation. This time is assumed as driving.';

  @override
  String get notMine => 'NOT MINE';

  @override
  String get requiredRejectionReason => 'Required rejection reason';

  @override
  String get overdue => 'Overdue';

  @override
  String get originalRecordPreserved => 'Original record preserved';

  @override
  String get byDate => 'By date…';

  @override
  String get currentVehicleOnly => 'Current vehicle only';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get currentVehicle => 'Current vehicle';

  @override
  String get responseWasInterrupted => 'Response was interrupted.';

  @override
  String get pleaseDrawASignatureFirst => 'Please draw a signature first.';

  @override
  String get logSuccessfullyCertified => 'Log successfully certified.';

  @override
  String get notReadyForCertification => 'Not Ready for Certification';

  @override
  String get pleaseResolveTheFollowingIssuesBefore =>
      'Please resolve the following issues before certifying your log:';

  @override
  String get carrierEditsMustBeAcceptedOr =>
      'Carrier edits must be accepted or rejected before certification.';

  @override
  String get carrierEditAcceptedReCertifyThe =>
      'Carrier edit accepted. Re-certify the log.';

  @override
  String get carrierEditRejected => 'Carrier edit rejected.';

  @override
  String get sessionMissingPleaseLogInAgain =>
      'Session missing. Please log in again.';

  @override
  String get carrierProposedEdit => 'Carrier proposed edit';

  @override
  String get reject => 'REJECT';

  @override
  String get accept => 'ACCEPT';

  @override
  String get selectAVehicleBeforeSavingThe =>
      'Select a vehicle before saving the form.';

  @override
  String get coDriverMustBeAServer =>
      'Co-driver must be a server id before it can be saved.';

  @override
  String get keepAPaperLogForThatDayAndUnti =>
      'Keep a paper log for that day and until the device is repaired or replaced. In the event of an inspection, display the previous 7 days from the app.';

  @override
  String get inTheEventOfAnEldMalfunctionTh =>
      'In the event of an ELD malfunction, the motor carrier must take actions to correct the malfunction within 8 days of discovery.';

  @override
  String get anInspectorMayViewTheLogFormTh =>
      'An inspector may view the log form, the log graph and the log events with notes.';

  @override
  String get theEventCouldNotBeSaved => 'The event could not be saved.';

  @override
  String get theEventWasSavedButThe =>
      'The event was saved but the change audit could not be recorded.';

  @override
  String get transferAuditTitle => 'Transfer audit';

  @override
  String get noTransfersFromServer => 'The server returned no transfers.';

  @override
  String transferAuditNotLoaded(Object error) {
    return 'Transfer audit was not loaded: $error';
  }

  @override
  String get driving24h => 'DRIVING 24H';

  @override
  String pendingDays(Object days) {
    return 'Pending $days day(s)';
  }

  @override
  String get enterTrailerNumber => 'Enter the trailer number.';

  @override
  String get trailerNumberFormatError =>
      'Trailer number must be letters, numbers, or hyphens (max 50).';

  @override
  String get enterDocumentNumber => 'Enter the document number.';

  @override
  String get documentNumberTooLong =>
      'Shipping document number is too long (max 100).';

  @override
  String get oneDocumentAtATime => 'Enter one document at a time (no comma).';

  @override
  String get selectVehicleBeforeSavingForm =>
      'Select a vehicle before saving the form.';

  @override
  String get coDriverMustBeServerId =>
      'Co-driver must be a server id before it can be saved.';

  @override
  String get serverSavedFormIncomplete =>
      'The server saved the form and left it incomplete.';

  @override
  String get serverSavedFormNoStatus =>
      'The server saved the form but did not return a form status.';

  @override
  String get responseInterrupted => 'Response was interrupted.';

  @override
  String get drawSignatureFirst => 'Please draw a signature first.';

  @override
  String get drawYourSignatureHere => 'Draw your signature here';

  @override
  String get certifyLegalStatement =>
      'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.';

  @override
  String get errNoInternet =>
      'No internet connection. Check the network and try again.';

  @override
  String get errRequestFailed =>
      'The request could not be completed. Try again.';

  @override
  String get errRequestFailedNetwork =>
      'The request could not be completed. Check the network and try again.';

  @override
  String get errCannotReachServer =>
      'Could not reach the server. Check the network and try again.';

  @override
  String get errServerRejected => 'The server rejected this request.';

  @override
  String get errSessionExpiredAction => 'The session expired. Sign in again.';

  @override
  String get errPermissionDenied => 'You are not allowed to do this.';

  @override
  String get errNotFound => 'The server did not find this item.';

  @override
  String get errServerError => 'The server returned an error. Try again.';

  @override
  String get errGeneric => 'The request could not be completed.';

  @override
  String get enterAReasonForManualRecording =>
      'Enter a reason for manual recording.';

  @override
  String get couldNotUpdateManualRecordingM =>
      'Could not update manual recording mode. Try again.';

  @override
  String get unableToConnectToEld => 'Unable to connect to the ELD.';

  @override
  String get checkBluetoothAndRetry =>
      'Check that the device and Bluetooth are on, then try again.';

  @override
  String get checkNetworkAndRetry =>
      'Check the network and device, then try again.';

  @override
  String get driverSessionMissingSignIn =>
      'Driver session is missing. Sign in again before inspection.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'NEXT';

  @override
  String get onboardingGetStarted => 'GET STARTED';

  @override
  String get onboardingTitle1 => 'Your hours, recorded automatically';

  @override
  String get onboardingBody1 =>
      'The ELD tracks your driving status against FMCSA limits the moment the vehicle moves — no paperwork, no guessing.';

  @override
  String get onboardingTitle2 => 'Inspect your vehicle with confidence';

  @override
  String get onboardingBody2 =>
      'Daily DVIR before and after the trip, defect tracking with repair certifications, and §396.13 review — all in one place.';

  @override
  String get onboardingTitle3 => 'Always ready for the inspector';

  @override
  String get onboardingBody3 =>
      'Your records, information packet, and transfer options live on the device — even when there is no internet on the road.';

  @override
  String startedOnDate(Object date) {
    return 'Started: $date';
  }

  @override
  String get tableTimeEt => 'Time ET';

  @override
  String certEventStatus(Object status) {
    return 'Cert · $status';
  }

  @override
  String eventCodeNote(Object code) {
    return 'Code: $code';
  }

  @override
  String originNote(Object origin) {
    return 'Origin: $origin';
  }

  @override
  String notesNote(Object notes) {
    return 'Notes: $notes';
  }

  @override
  String get inspectionCommentErrorLength =>
      'The comment must be 4 to 60 characters.';

  @override
  String get enterValidEmail => 'Enter a valid email.';

  @override
  String get transferAccepted => 'The server accepted the transfer request.';

  @override
  String get sendLogsViaEmail => 'Send logs via email';

  @override
  String get send8Logs => 'Send 8 Logs';

  @override
  String get recipientEmail => 'Recipient Email';

  @override
  String get comment => 'Comment';

  @override
  String get dataTransferType => 'Data Transfer Type';

  @override
  String get sendAction => 'SEND';

  @override
  String get inspectLogs24 =>
      'Inspect logs for the 24-hour period and the previous days for one HOS cycle';

  @override
  String get setPinGuidance =>
      'Set a PIN, select \"Start Inspection\", and give your device to the officer';

  @override
  String get eldCertifies =>
      'This ELD certifies that use of the app with the ELD device complies with all requirements for ELD as defined in Federal Motor Carrier Safety regulation 49 CFR part 395 Subpart B.';

  @override
  String get notAllowedByServer =>
      'Not available for this account per the server.';

  @override
  String get startInspectionUpper => 'START INSPECTION';

  @override
  String get serverDoesNotAllow =>
      'The server does not allow starting an inspection right now.';

  @override
  String get sendLogsFor24 =>
      'Send logs for the 24-hour period and the previous days for one HOS cycle';

  @override
  String get sendLogsToOfficer =>
      'Send your logs to the officer if they request';

  @override
  String get sendLogsUpper => 'SEND LOGS';

  @override
  String get emailLogs24Pdf =>
      'Email logs for the 24-hour period and the previous days for one HOS cycle as PDF';

  @override
  String get emailLogsPdf => 'Email your logs in the PDF format';

  @override
  String get emailLogsUpper => 'EMAIL LOGS';

  @override
  String get infoPacketUpper => 'INFORMATION PACKET';

  @override
  String get inspectionPinTitle => 'Inspection PIN';

  @override
  String get enter4Digits => 'PIN must be 4 digits.';

  @override
  String get pinsDoNotMatch => 'The PINs do not match.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get confirmPinLabel => 'Confirm PIN';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get enterInspectionPin => 'Enter the inspection PIN.';

  @override
  String get incorrectPin => 'Incorrect PIN.';

  @override
  String get driverExit => 'Driver exit';

  @override
  String get exitAction => 'Exit';

  @override
  String get enterNewPinOfficer =>
      'Enter a new inspection PIN to be given to the officer';

  @override
  String get enterSamePinToExit =>
      'Enter the same PIN to exit the inspection mode';

  @override
  String get setPinGuidanceDialog =>
      'Set a 4-digit PIN to lock the screen. The officer can only view logs and cannot leave without the driver password.';

  @override
  String get enterPinToExitGuidance =>
      'Enter the inspection PIN you set when starting. The officer cannot leave here.';

  @override
  String get menuTitle => 'Menu';

  @override
  String get vehicleInMotionTitle => 'Vehicle in Motion';

  @override
  String get vehicleInMotionDesc =>
      'To comply with FMCSA regulations and safety rules, the application is locked while driving. It will unlock when the vehicle stops.';

  @override
  String get weakConnectionDelayedData =>
      'Weak connection. Some data may be delayed.';

  @override
  String get noInternetConnection => 'No internet connection.';

  @override
  String get connectionStatusUnknown => 'Connection status is unknown.';

  @override
  String driveLimitFormat(String drive) {
    return '$drive-Hour Driving Limit';
  }

  @override
  String shiftLimitFormat(String shift) {
    return '$shift-Hour On Duty Limit';
  }

  @override
  String breakLimitFormat(String rest) {
    return '$rest Minute Rest Break';
  }

  @override
  String usedFormat(String description) {
    return '$description · Used';
  }

  @override
  String get noticeTitle => 'Notice';

  @override
  String get gpsTurnedOff => 'GPS is turned off.';

  @override
  String get serverReportsEldAlert =>
      'The server reports an ELD operational alert. Open the Connection screen for details.';

  @override
  String get operationalAlertTooltip => 'Operational alert';

  @override
  String get noInternetBanner =>
      'No internet. You can continue with saved data.';

  @override
  String get dvirSatisfactory => 'Vehicle Condition Satisfactory';

  @override
  String get dvirHasDefects => 'Has Defects';

  @override
  String get dvirDefectsCorrected => 'Defects Corrected';

  @override
  String get dvirDefectsNotCorrected => 'Defects Need Not Be Corrected';

  @override
  String get dvirDefectRecorded => '— a defect is recorded';

  @override
  String get dvirNoRepairCert => 'No repair certification yet';

  @override
  String get dvirSetByCarrier => 'Set by the carrier, not the driver';

  @override
  String get dvirTimeUnavailable =>
      'Inspection time is unavailable. Connect and try again.';

  @override
  String get dvirSavedCannotEdit =>
      'A saved report cannot be edited on this device.';

  @override
  String get dvirSignatureRequired => 'A signature is required.';

  @override
  String get dvirDriverSessionMissing =>
      'Driver session is missing. Sign in again before signing the report.';

  @override
  String get dvirVehicleIdMissing =>
      'Vehicle id is missing. Select a vehicle before signing.';

  @override
  String get dvirPrevNoServerId =>
      'The previous report has no server id and cannot be reviewed.';

  @override
  String get dvirPreviousInspection => 'Previous inspection';

  @override
  String get dvirReviewBeforeDriving =>
      'Review and sign the previous report before driving.';

  @override
  String get dvirRecordedDefects => 'Recorded defects:';

  @override
  String get dvirNone => 'None.';

  @override
  String get dvirRepairStatus => 'Repair status: ';

  @override
  String get dvirReviewed => 'Reviewed';

  @override
  String get dvirLocationUnavailable => 'Location unavailable';

  @override
  String get dvirCompanyUnavailable => 'Company unavailable';

  @override
  String get dvirTimeUnavailableShort => 'Time unavailable';

  @override
  String get dvirInsertDvir => 'Insert DVIR';

  @override
  String get dvirPreviousReviewNotice =>
      'Previous DVIR Review — §396.13. Opening the report is not a review.';

  @override
  String get dvirTimeET => 'Time (ET)';

  @override
  String get dvirOdometerMi => 'Odometer (mi)';

  @override
  String get dvirOdometerHint => 'Odometer';

  @override
  String get company => 'Company';

  @override
  String get remarks => 'Remarks';

  @override
  String get dvirImageNotAvailable => 'Image not available.';

  @override
  String get dvirClearSignature => 'Clear signature';

  @override
  String get dvirSigned => 'SIGNED';

  @override
  String get dvirSign => 'SIGN';

  @override
  String get removeAction => 'Remove';

  @override
  String get addDefects => 'Add Defects';

  @override
  String get dvirDefects396_11 => 'Defects (§396.11)';

  @override
  String get dvirLoadDefectsFail =>
      'Could not load the defects list from the server.';

  @override
  String get retryAction => 'RETRY';

  @override
  String get dvirCatalogEmpty => 'The catalog is empty.';

  @override
  String get dvirSafetyAffecting => 'Safety affecting';

  @override
  String get dvirDescriptionOptional => 'Description (optional)';

  @override
  String get eldDiagnosticReading => 'Reading connection status...';

  @override
  String eldDiagnosticDiagnosticFormat(String diagnostics) {
    return 'Diagnostic: $diagnostics';
  }

  @override
  String eldDiagnosticMalfunctionFormat(String malfunctions) {
    return 'Malfunction: $malfunctions';
  }

  @override
  String eldDiagnosticLastValidDataFormat(String lastHeartbeat) {
    return 'Last valid data: $lastHeartbeat';
  }

  @override
  String eldDiagnosticDataAgeFormat(String dataAgeSeconds) {
    return 'Data age: $dataAgeSeconds seconds';
  }

  @override
  String get eldDiagnosticNotReady => 'Not ready for normal operation.';

  @override
  String get eldDiagnosticDataNotReliable => 'Data is not reliable.';

  @override
  String get eldDiagnosticConnected => 'Connected';

  @override
  String get eldDiagnosticDisconnected => 'Disconnected';

  @override
  String get eldDiagnosticUnavailable => 'Unavailable';

  @override
  String get eldDiagnosticMalfunction => 'Malfunction';

  @override
  String get eldDiagnosticNoConnectionStatus =>
      'The server did not return a connection status.';

  @override
  String get eldReadinessTitle => 'Pre-operation readiness';

  @override
  String get eldReadinessChecking => 'Checking readiness...';

  @override
  String get eldReadinessReady => 'Ready for operation';

  @override
  String get eldReadinessNotReady => 'Not ready for operation';

  @override
  String eldReadinessRecommendedActionFormat(String action) {
    return 'Recommended action: $action';
  }

  @override
  String get eldReadinessDevicePaired => 'Device paired';

  @override
  String get eldReadinessConnectionActive => 'Connection active';

  @override
  String get eldReadinessMotionData => 'Motion data';

  @override
  String get eldReadinessLocationData => 'Location data';

  @override
  String get eldReadinessEngineTelemetry => 'Engine telemetry (ECM)';

  @override
  String get eldMalfunctionTitle => 'If the ELD malfunctions (§395.34)';

  @override
  String get eldMalfunctionStep1 =>
      'Note the malfunction and notify the carrier in writing within 24 hours.';

  @override
  String get eldMalfunctionStep2 =>
      'Reconstruct the current 24 hours and the previous 7 days on paper if the ELD cannot provide them.';

  @override
  String get eldMalfunctionStep3 =>
      'Continue paper logs until the device is repaired.';

  @override
  String get eldMalfunctionManualActive => 'Manual recording is active.';

  @override
  String eldMalfunctionManualActiveWithReason(String reason) {
    return 'Manual recording is active — $reason.';
  }

  @override
  String get eldMalfunctionEndManual => 'END MANUAL RECORDING';

  @override
  String get eldMalfunctionServerNotAllow =>
      'The server does not allow manual recording for this vehicle.';

  @override
  String get eldMalfunctionStartManual => 'START MANUAL RECORDING';

  @override
  String get eldMalfunctionStartSuccess =>
      'Manual recording start was recorded on the server.';

  @override
  String get eldMalfunctionEndSuccess =>
      'Manual recording ended; electronic recording resumed.';

  @override
  String get eldMalfunctionReasonStart => 'Manual recording reason';

  @override
  String get eldMalfunctionReasonEnd => 'Reason for ending manual recording';

  @override
  String get eldMalfunctionHintStart => 'e.g. lost connection to the ELD';

  @override
  String get eldMalfunctionHintEnd => 'e.g. ELD connection restored';

  @override
  String get dvirListNoRecords => 'No Records';

  @override
  String get dvirListTotal => 'Total';

  @override
  String get dvirListOpen => 'Open';

  @override
  String get dvirListSigned => 'Signed';

  @override
  String get dvirListOos => 'OOS';

  @override
  String get serverAcceptedDisconnected =>
      'The server accepted disconnected mode. No local duty event was created.';

  @override
  String get macAddressRequired => 'MAC address is required.';

  @override
  String get coDriverSelectLabel => 'Select Co-driver';

  @override
  String get coDriverSelectHint => 'Select your co-driver';

  @override
  String get coDriverSwitchDrivers => 'Switch Drivers';

  @override
  String get coDriverSwitchHint =>
      'You will become co-driver. Your co-driver will stay driver.';

  @override
  String get coDriverSwitching => 'Switching...';

  @override
  String get coDriverSwitchAction => 'SWITCH';

  @override
  String get coDriverConfirmSwitchTitle => 'Confirm Switch';

  @override
  String get coDriverConfirmSwitchBody =>
      'This asks the server to switch roles. Hours are not copied and duty status is not changed.';

  @override
  String get coDriverRolesSwitchedTitle => 'Roles switched';

  @override
  String coDriverRolesSwitchedBody(String newPrimary) {
    return 'You are now the co-driver.\n$newPrimary is now the primary driver.\n\nHours were not copied and duty status was not changed. The new driver sets duty before moving.';
  }

  @override
  String get coDriverDefaultNewPrimary => 'The co-driver';

  @override
  String get coDriverNone => 'No co-driver';

  @override
  String get coDriverRefusalSessionMissing =>
      'Driver session is missing. Sign in before switching.';

  @override
  String get coDriverRefusalStillDriving =>
      'Change duty status before handover. The switch does not change it.';

  @override
  String get coDriverRefusalMotionUnknown =>
      'Vehicle motion is unknown. That is not treated as stopped.';

  @override
  String get coDriverRefusalThresholdMissing =>
      'The motion threshold is not available.';

  @override
  String get coDriverRefusalVehicleMoving =>
      'Roles can be switched only when the vehicle is stopped.';

  @override
  String get coDriverRefusalCoDriverMissing =>
      'Select a co-driver before switching.';

  @override
  String get coDriverRefusalSameDriver =>
      'The current account cannot be selected as the co-driver.';

  @override
  String get coDriverLinkedTitle => 'Linked co-driver';

  @override
  String get coDriverLinkNotRead => 'The link has not been read.';

  @override
  String get coDriverLinkNone => 'No linked co-driver.';

  @override
  String get coDriverTeamDrivingActive => 'Team driving active';

  @override
  String get coDriverTeamDrivingInactive => 'Team driving inactive';

  @override
  String get coDriverHosIsolationReadError =>
      'HOS isolation status could not be read.';

  @override
  String get coDriverHosIsolated => 'HOS records isolated';

  @override
  String get coDriverHosNotIsolated => 'HOS records not isolated';

  @override
  String get coDriverVehicleMissing =>
      'Select a vehicle before linking a co-driver.';

  @override
  String get dvirDefectsNone => 'No defects to report.';

  @override
  String dvirDefectsCount(int defectCount) {
    return '$defectCount defects selected.';
  }

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get reCertificationRequiredMsg =>
      'Re-certification Required: Edits were made after your last signature.';

  @override
  String get statusOff => 'Off Duty';

  @override
  String get statusSb => 'Sleeper Berth';

  @override
  String get statusD => 'Driving';

  @override
  String get statusOn => 'On Duty';

  @override
  String get statusPc => 'Personal Conveyance';

  @override
  String get statusYm => 'Yard Move';

  @override
  String get dvirPreTrip => 'Pre-Trip';

  @override
  String get dvirPostTrip => 'Post-Trip';

  @override
  String get dvirSafeToDrive => 'Safe to Drive';

  @override
  String get dvirNeedsRepair => 'Needs Repair';

  @override
  String get dvirUnsafe => 'Unsafe';

  @override
  String get dvirBrakes => 'Brakes';

  @override
  String get dvirTires => 'Tires';

  @override
  String get dvirLights => 'Lights';

  @override
  String get dvirSteering => 'Steering';

  @override
  String get dvirTrailerCoupling => 'Trailer Coupling';

  @override
  String get dvirEmergencyEquipment => 'Emergency Equipment';

  @override
  String get dvirEngine => 'Engine';

  @override
  String get dvirFuelSystem => 'Fuel System';

  @override
  String get dvirExhaustSystem => 'Exhaust System';

  @override
  String get dvirSuspension => 'Suspension';

  @override
  String get dvirMirrors => 'Mirrors';

  @override
  String get dvirWindshield => 'Windshield';

  @override
  String get routingCode => 'Routing Code';

  @override
  String get routingCodeHint => 'Enter the routing code from the inspector';

  @override
  String get tooManyPinAttempts =>
      'Too many incorrect attempts. Please wait and try again.';
}
