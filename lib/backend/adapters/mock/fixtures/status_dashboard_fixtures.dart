/// Static fixtures for [MockStatusDashboardBackend].
///
/// **Rule:** These match the shape returned by the real backend,
/// as documented in the Swagger spec (tags: "02.3 Status Dashboard").
library;

const statusDashboardFixture = <String, dynamic>{
  'driver': {
    'name': 'سعد بن محمد العتيبي',
    'id': 101,
    'displayText': 'سعد بن محمد العتيبي - 101',
  },
  'operationalAlerts': {
    'toolIcon': false,
    'warningTriangleIcon': false,
    'connectionStatus': 'OK',
  },
  'currentDutyStatus': 'ON_DUTY',
  'remainingCircle': {
    'time': '08:37',
    'label': 'Remaining',
    'progress': 0.62,
  },
  'hosIndicators': {
    'drive': {
      'label': 'DRIVE',
      'value': '02:23',
      'type': 'USED',
    },
    'shift': {
      'label': 'SHIFT',
      'value': '05:23',
      'type': 'USED',
    },
    'breakTime': {
      'label': 'BREAK',
      'value': '00:30',
      'type': 'REMAINING',
    },
    'cycle': {
      'label': 'CYCLE',
      'value': '61:23',
      'type': 'USED',
    },
  },
  'regulatoryConstraints': {
    'ruleSet': 'USA 70/8',
    'limits': [
      'maxDrivingHours: 11',
      'maxShiftHours: 14',
      'mandatoryRestHours: 10',
      'cycleHours: 70',
    ],
  },
};

const statusDashboardDrivingFixture = <String, dynamic>{
  'driver': {
    'name': 'سعد بن محمد العتيبي',
    'id': 101,
    'displayText': 'سعد بن محمد العتيبي - 101',
  },
  'operationalAlerts': {
    'toolIcon': false,
    'warningTriangleIcon': false,
    'connectionStatus': 'OK',
  },
  'currentDutyStatus': 'DRIVING',
  'remainingCircle': {
    'time': '08:37',
    'label': 'Remaining',
    'progress': 0.62,
  },
  'hosIndicators': {
    'drive': {
      'label': 'DRIVE',
      'value': '02:23',
      'type': 'USED',
    },
    'shift': {
      'label': 'SHIFT',
      'value': '05:23',
      'type': 'USED',
    },
    'breakTime': {
      'label': 'BREAK',
      'value': '00:30',
      'type': 'REMAINING',
    },
    'cycle': {
      'label': 'CYCLE',
      'value': '61:23',
      'type': 'USED',
    },
  },
  'regulatoryConstraints': {
    'ruleSet': 'USA 70/8',
    'limits': [
      'maxDrivingHours: 11',
      'maxShiftHours: 14',
      'mandatoryRestHours: 10',
      'cycleHours: 70',
    ],
  },
};

const weeklyRecapFixture = <String, dynamic>{
  'cycleRule': 'USA 70/8',
  'cycleUsed': '61:23',
  'cycleRemaining': '08:37',
  'availableTomorrow': '08:45',
  'days': [
    {
      'date': '2026-01-09',
      'dayOfWeek': 'Fri',
      'driving': '07:12',
      'onDuty': '07:45',
      'totalWork': '07:45',
    },
    {
      'date': '2026-01-10',
      'dayOfWeek': 'Sat',
      'driving': '05:03',
      'onDuty': '05:23',
      'totalWork': '05:23',
    },
    {
      'date': '2026-01-11',
      'dayOfWeek': 'Sun',
      'driving': '06:30',
      'onDuty': '06:50',
      'totalWork': '06:50',
    },
    {
      'date': '2026-01-12',
      'dayOfWeek': 'Mon',
      'driving': '08:00',
      'onDuty': '08:30',
      'totalWork': '08:30',
    },
    {
      'date': '2026-01-13',
      'dayOfWeek': 'Tue',
      'driving': '07:45',
      'onDuty': '08:15',
      'totalWork': '08:15',
    },
    {
      'date': '2026-01-14',
      'dayOfWeek': 'Wed',
      'driving': '06:20',
      'onDuty': '06:40',
      'totalWork': '06:40',
    },
    {
      'date': '2026-01-15',
      'dayOfWeek': 'Thu',
      'driving': '05:15',
      'onDuty': '05:30',
      'totalWork': '05:30',
    },
  ],
};
