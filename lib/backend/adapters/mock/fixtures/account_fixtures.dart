/// Static fixtures for [MockAccountBackend].
///
/// **Rule:** These match the shape returned by the real backend,
/// as documented in the Swagger spec (tags: "01. Account & Profile").
///
/// **Note on duplicates:** The real backend returns duplicate fields
/// (`mainOfficeAddress` + `mainofficeaddress`, `timezone` + `timeZone`).
/// The mock returns only the canonical fields — the mapper's job to
/// handle both shapes is verified with separate fixtures.
library;

const accountProfileFixture = <String, dynamic>{
  'id': 101,
  'name': 'سعد بن محمد العتيبي',
  'email': 'driver101@eld.com',
  'phone': '+966501234567',
  'licenseNumber': 'TX-DL-123456',
  'licenseState': 'TX',
  'carrierName': 'Top Compliance Logistics LLC',
  'carrierUsdot': '1234567',
  'status': 'ACTIVE',
  'mainOfficeAddress': '100 Logistics Blvd, Dallas, TX 75001',
  'homeTerminalAddress': 'طريق الملك فهد، الرياض',
  'timezone': 'Asia/Riyadh',
  'language': 'ar',
  'availableLanguages': ['ar', 'en', 'es'],
  'odometer': 'mi',
  'availableOdometerUnits': ['mi', 'km'],
  'canEdit': false,
  'editRestrictionNotice':
      'لا يمكن تغيير معلومات الحساب إلا بواسطة مدير الأسطول',
};

const accountMyAccountFixture = <String, dynamic>{
  'driverId': 101,
  'email': 'driver@example.com',
  'name': 'Naseem Hassan Ali Adam',
  'phone': '+1 555-0199',
  'license': {
    'state': 'MI',
    'number': 'A350622298913',
    'formatted': 'MI, A350622298913'
  },
  'carrier': 'Top Logistics LLC',
  'mainOfficeAddress': '100 Main St, Dallas, TX',
  'homeTerminalAddress': 'Dallas Terminal, TX',
  'language': 'English',
  'odometer': 'mi',
  'availableLanguages': ['English', 'Spanish', 'Arabic'],
  'availableOdometerUnits': ['mi', 'km'],
  'notice':
      'Please contact your fleet manager to change your account information',
  'editableFields': ['language', 'odometer'],
  'readOnlyFields': [
    'email',
    'name',
    'phone',
    'license',
    'carrier',
    'mainOfficeAddress',
    'homeTerminalAddress',
    'timeZone',
  ],
  'timeZone': 'ET',
};
