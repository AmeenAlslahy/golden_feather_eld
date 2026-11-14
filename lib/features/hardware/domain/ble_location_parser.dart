import 'dart:convert';
import 'dart:typed_data';

/// A location fix decoded from a BLE ELD stream.
///
/// `speedMps` is metres per second (the app/native queue stores m/s and converts
/// to knots only at upload time), `bearing` is degrees clockwise from north.
class BleLocationFix {
  const BleLocationFix({
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.bearing,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.protocol,
    this.alarm,
  });

  final double latitude;
  final double longitude;
  final double speedMps;
  final double bearing;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
  final String protocol;
  final String? alarm;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  Map<String, dynamic> toNativeMap({String source = 'ble'}) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speedMps,
      'bearing': bearing,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source': source,
      if (alarm != null) 'alarm': alarm,
    };
  }
}

/// Incremental parser for BLE payloads that carry ASCII lines.
///
/// Supported today:
///  - NMEA 0183: `$GPRMC`, `$GNRMC`, `$GPGGA`, `$GNGGA`, `$GPGNS`, `$GNGNS`, `$GPGLL`
///  - one JSON object per line (many ELD gateways stream this)
///
/// Pacific Track's proprietary binary frame layout is not public. Frames that do
/// not decode are still surfaced to diagnostics by the data source, so a live
/// capture can be used to finish the decoder without changing the pipeline.
class BleLocationFrameParser {
  final List<int> _buffer = <int>[];

  static const int _maxBufferBytes = 8192;
  static const double _knotsToMps = 0.5144444444;

  /// Feeds raw bytes and returns every complete fix found in the buffer.
  List<BleLocationFix> addBytes(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    _buffer.addAll(bytes);
    if (_buffer.length > _maxBufferBytes) {
      _buffer.removeRange(0, _buffer.length - _maxBufferBytes);
    }

    final fixes = <BleLocationFix>[];
    while (true) {
      final newline = _buffer.indexOf(0x0A);
      final carriage = _buffer.indexOf(0x0D);
      final separator = switch ((newline, carriage)) {
        (-1, -1) => -1,
        (-1, _) => carriage,
        (_, -1) => newline,
        _ => newline < carriage ? newline : carriage,
      };
      if (separator < 0) break;

      final lineBytes = _buffer.sublist(0, separator);
      _buffer.removeRange(0, separator + 1);
      if (lineBytes.isEmpty) continue;

      final line = latin1.decode(lineBytes, allowInvalid: true).trim();
      if (line.isEmpty) continue;

      final fix = parseLine(line);
      if (fix != null) fixes.add(fix);
    }
    return fixes;
  }

  void reset() => _buffer.clear();

  /// Parses a single complete line (exposed for tests and for payloads delivered
  /// as text instead of a byte stream).
  BleLocationFix? parseLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return null;

    if (line.startsWith('{')) {
      return _parseJson(line);
    }

    final dollar = line.indexOf(r'$');
    if (dollar >= 0) {
      final sentence = line.substring(dollar);
      if (!_hasValidChecksum(sentence)) return null;
      return _parseNmea(sentence);
    }

    return null;
  }

  bool _hasValidChecksum(String sentence) {
    final star = sentence.indexOf('*');
    if (star < 0) return true; // Some gateways omit the checksum.
    if (star + 3 > sentence.length) return false;
    var checksum = 0;
    for (var i = 1; i < star; i++) {
      checksum ^= sentence.codeUnitAt(i);
    }
    final expected = int.tryParse(
      sentence.substring(star + 1, star + 3),
      radix: 16,
    );
    if (expected == null) return false;
    return checksum == expected;
  }

  BleLocationFix? _parseNmea(String sentence) {
    final body = sentence.substring(1).split('*').first;
    final parts = body.split(',');
    if (parts.length < 6) return null;

    final type = parts[0].toUpperCase();
    switch (type) {
      case 'GPRMC':
      case 'GNRMC':
      case 'GLRMC':
        return _parseRmc(parts);
      case 'GPGGA':
      case 'GNGGA':
      case 'GLGGA':
        return _parseGga(parts);
      case 'GPGNS':
      case 'GNGNS':
      case 'GLGNS':
        return _parseGns(parts);
      case 'GPGLL':
      case 'GNGLL':
      case 'GLGLL':
        return _parseGll(parts);
      default:
        return null;
    }
  }

  BleLocationFix? _parseRmc(List<String> parts) {
    // $GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,speedKnots,course,ddmmyy,...
    if (parts.length < 10) return null;
    final status = parts[2].toUpperCase();
    if (status != 'A') return null;

    final position = _position(parts[3], parts[4], parts[5], parts[6]);
    if (position == null) return null;

    final speedKnots = double.tryParse(parts[7]) ?? 0;
    final bearing = double.tryParse(parts[8]) ?? 0;

    return BleLocationFix(
      latitude: position.$1,
      longitude: position.$2,
      speedMps: speedKnots * _knotsToMps,
      bearing: bearing,
      altitude: 0,
      accuracy: 0,
      timestamp: _timestamp(parts[1], parts[9]),
      protocol: 'nmea-rmc',
    );
  }

  BleLocationFix? _parseGga(List<String> parts) {
    // $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,fixQuality,sats,hdop,alt,M,...
    if (parts.length < 10) return null;
    final fixQuality = int.tryParse(parts[6]) ?? 0;
    if (fixQuality == 0) return null;

    final position = _position(parts[2], parts[3], parts[4], parts[5]);
    if (position == null) return null;

    final hdop = double.tryParse(parts[8]) ?? 0;
    final altitude = double.tryParse(parts[9]) ?? 0;

    return BleLocationFix(
      latitude: position.$1,
      longitude: position.$2,
      speedMps: 0,
      bearing: 0,
      altitude: altitude,
      accuracy: hdop > 0 ? hdop * 5 : 0,
      timestamp: _timestamp(parts[1], null),
      protocol: 'nmea-gga',
    );
  }

  BleLocationFix? _parseGns(List<String> parts) {
    // $GNGNS,hhmmss.ss,llll.ll,a,yyyyy.yy,a,mode,sats,hdop,alt,...
    if (parts.length < 9) return null;
    final mode = parts[6].toUpperCase();
    if (mode.isEmpty || mode == 'N') return null;

    final position = _position(parts[2], parts[3], parts[4], parts[5]);
    if (position == null) return null;

    final hdop = double.tryParse(parts[8]) ?? 0;
    final altitude = parts.length > 9 ? double.tryParse(parts[9]) ?? 0.0 : 0.0;

    return BleLocationFix(
      latitude: position.$1,
      longitude: position.$2,
      speedMps: 0,
      bearing: 0,
      altitude: altitude,
      accuracy: hdop > 0 ? hdop * 5 : 0,
      timestamp: _timestamp(parts[1], null),
      protocol: 'nmea-gns',
    );
  }

  BleLocationFix? _parseGll(List<String> parts) {
    // $GPGLL,llll.ll,a,yyyyy.yy,a,hhmmss.ss,A,...
    if (parts.length < 7) return null;
    final status = parts[6].toUpperCase();
    if (status.isNotEmpty && status != 'A') return null;

    final position = _position(parts[1], parts[2], parts[3], parts[4]);
    if (position == null) return null;

    return BleLocationFix(
      latitude: position.$1,
      longitude: position.$2,
      speedMps: 0,
      bearing: 0,
      altitude: 0,
      accuracy: 0,
      timestamp: _timestamp(parts[5], null),
      protocol: 'nmea-gll',
    );
  }

  BleLocationFix? _parseJson(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) return null;

      final latitude = _firstDouble(decoded, const ['lat', 'latitude']);
      final longitude = _firstDouble(decoded, const [
        'lon',
        'lng',
        'longitude',
      ]);
      if (latitude == null || longitude == null) return null;

      final speedKnots = _firstDouble(decoded, const ['speedKnots', 'sog']);
      final speed = speedKnots != null
          ? speedKnots * _knotsToMps
          : _firstDouble(decoded, const ['speed', 'speedMps']) ?? 0;

      return BleLocationFix(
        latitude: latitude,
        longitude: longitude,
        speedMps: speed,
        bearing:
            _firstDouble(decoded, const ['bearing', 'heading', 'course']) ?? 0,
        altitude: _firstDouble(decoded, const ['altitude', 'alt', 'ele']) ?? 0,
        accuracy: _firstDouble(decoded, const ['accuracy', 'hdop']) ?? 0,
        timestamp: _jsonTimestamp(decoded),
        protocol: 'json',
        alarm: decoded['alarm']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  (double, double)? _position(
    String latRaw,
    String latHemisphere,
    String lonRaw,
    String lonHemisphere,
  ) {
    final latitude = _nmeaCoordinate(latRaw, latHemisphere);
    final longitude = _nmeaCoordinate(lonRaw, lonHemisphere);
    if (latitude == null || longitude == null) return null;
    return (latitude, longitude);
  }

  double? _nmeaCoordinate(String raw, String hemisphere) {
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;

    final degrees = (value / 100).floorToDouble();
    final minutes = value - degrees * 100;
    var result = degrees + minutes / 60;

    final hemi = hemisphere.toUpperCase();
    if (hemi == 'S' || hemi == 'W') result = -result;
    return result;
  }

  double? _firstDouble(Map<dynamic, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  DateTime _jsonTimestamp(Map<dynamic, dynamic> json) {
    final raw = json['timestamp'] ?? json['ts'] ?? json['time'];
    if (raw is num) {
      final value = raw.toInt();
      return value > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
      final numeric = int.tryParse(raw);
      if (numeric != null) {
        return numeric > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true)
            : DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true);
      }
    }
    return DateTime.now().toUtc();
  }

  DateTime _timestamp(String timeRaw, String? dateRaw) {
    final now = DateTime.now().toUtc();
    var year = now.year;
    var month = now.month;
    var day = now.day;

    if (dateRaw != null && dateRaw.length >= 6) {
      day = int.tryParse(dateRaw.substring(0, 2)) ?? day;
      month = int.tryParse(dateRaw.substring(2, 4)) ?? month;
      final shortYear = int.tryParse(dateRaw.substring(4, 6));
      if (shortYear != null) year = 2000 + shortYear;
    }

    var hour = 0;
    var minute = 0;
    var second = 0;
    var millisecond = 0;

    if (timeRaw.length >= 6) {
      hour = int.tryParse(timeRaw.substring(0, 2)) ?? 0;
      minute = int.tryParse(timeRaw.substring(2, 4)) ?? 0;
      final secondsPart = timeRaw.substring(4);
      final dot = secondsPart.indexOf('.');
      if (dot >= 0) {
        second = int.tryParse(secondsPart.substring(0, dot)) ?? 0;
        final fraction = secondsPart.substring(dot + 1);
        final padded = fraction.padRight(3, '0').substring(0, 3);
        millisecond = int.tryParse(padded) ?? 0;
      } else {
        second = int.tryParse(secondsPart) ?? 0;
      }
    }

    return DateTime.utc(year, month, day, hour, minute, second, millisecond);
  }
}

/// Convenience for callers that receive a comma-separated byte string from the
/// legacy native event format (`"36,71,80,82,77,67,..."`).
Uint8List bytesFromCommaSeparated(String raw) {
  final bytes = <int>[];
  for (final token in raw.split(',')) {
    final parsed = int.tryParse(token.trim());
    if (parsed != null) bytes.add(parsed & 0xFF);
  }
  return Uint8List.fromList(bytes);
}
