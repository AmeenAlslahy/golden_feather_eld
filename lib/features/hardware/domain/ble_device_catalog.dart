/// Catalog of BLE ELD devices the app knows how to recognise.
///
/// Discovery itself is generic (any advertising device), but classification lets
/// the UI show a useful name and lets the parser know which transport to expect.
class BleDeviceProfile {
  const BleDeviceProfile({
    required this.id,
    required this.displayName,
    this.namePrefixes = const [],
    this.macPrefixes = const [],
    this.serviceUuids = const [],
    this.supportsLocationStream = true,
    this.notes,
  });

  final String id;
  final String displayName;
  final List<String> namePrefixes;
  final List<String> macPrefixes;
  final List<String> serviceUuids;
  final bool supportsLocationStream;
  final String? notes;

  bool matches({
    required String name,
    required String macAddress,
    required List<String> advertisedServiceUuids,
  }) {
    final upperName = name.toUpperCase();
    final upperMac = macAddress.toUpperCase();
    final services = advertisedServiceUuids.map((e) => e.toLowerCase()).toSet();

    if (namePrefixes.any(
      (prefix) => upperName.startsWith(prefix.toUpperCase()),
    )) {
      return true;
    }
    if (macPrefixes.any(
      (prefix) => upperMac.startsWith(prefix.toUpperCase()),
    )) {
      return true;
    }
    if (serviceUuids.any((uuid) => services.contains(uuid.toLowerCase()))) {
      return true;
    }
    return false;
  }
}

const String ffe0ServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
const String ffe1CharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';
const String nusServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String nusRxCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
const String nusTxCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

/// Pacific Track PT30-U (FCC ID 2ALBDPT30U) and its siblings.
///
/// The vendor does not publish the proprietary frame layout. Until a live
/// capture/spec is available, the app still:
///  - discovers the device (no FFE0-only filter),
///  - connects, negotiates MTU and subscribes to every notify characteristic,
///  - decodes NMEA/JSON payloads if the module exposes them,
///  - keeps raw hex frames for diagnostics.
const BleDeviceProfile pacificTrackPt30Profile = BleDeviceProfile(
  id: 'pacific_track_pt30',
  displayName: 'Pacific Track PT30/PT40',
  namePrefixes: ['PT30', 'PT40', 'PACIFIC'],
  macPrefixes: ['E0:B4:88'],
  notes:
      'Proprietary binary protocol. NMEA/JSON payloads are decoded when present; '
      'raw frames are kept for diagnostics.',
);

const BleDeviceProfile genericFfe0Profile = BleDeviceProfile(
  id: 'generic_ffe0',
  displayName: 'ELD adapter (FFE0)',
  serviceUuids: [ffe0ServiceUuid],
);

const BleDeviceProfile genericNusProfile = BleDeviceProfile(
  id: 'generic_nus',
  displayName: 'ELD adapter (NUS UART)',
  serviceUuids: [nusServiceUuid],
);

const BleDeviceProfile genericEldProfile = BleDeviceProfile(
  id: 'generic_eld',
  displayName: 'ELD device',
  namePrefixes: ['ELD', 'OBD'],
);

const List<BleDeviceProfile> knownBleDeviceProfiles = [
  pacificTrackPt30Profile,
  genericFfe0Profile,
  genericNusProfile,
  genericEldProfile,
];

/// Best-effort profile lookup for a scan result or a connected device.
BleDeviceProfile? matchBleDeviceProfile({
  required String name,
  required String macAddress,
  List<String> serviceUuids = const [],
}) {
  for (final profile in knownBleDeviceProfiles) {
    if (profile.matches(
      name: name,
      macAddress: macAddress,
      advertisedServiceUuids: serviceUuids,
    )) {
      return profile;
    }
  }
  return null;
}

/// Human readable kind sent by the native scanner (`kind` field).
String describeBleKind(String? kind) {
  switch (kind) {
    case 'pacificTrack':
      return 'Pacific Track';
    case 'nus':
      return 'NUS UART';
    case 'ffe0':
      return 'FFE0 UART';
    case 'eld':
      return 'ELD';
    default:
      return 'Unknown';
  }
}

/// Normalises a MAC typed by the driver (`e0b488c7cae9` -> `E0:B4:88:C7:CA:E9`).
String normalizeMacAddress(String raw) {
  final trimmed = raw.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
  if (trimmed.length != 12) return raw.trim().toUpperCase();
  final parts = <String>[];
  for (var i = 0; i < 12; i += 2) {
    parts.add(trimmed.substring(i, i + 2));
  }
  return parts.join(':');
}
