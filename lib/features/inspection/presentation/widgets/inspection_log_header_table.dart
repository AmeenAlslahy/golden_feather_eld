import 'package:flutter/material.dart';

import '../../../../domain/inspection/dot_inspection.dart';

/// Dense striped header matching the Inspection Logs screenshot.
///
/// العناوين إنجليزية عمداً: هذا شكل RODS الورقي الرسمي (49 CFR 395.8 /
/// SRS 8.3) الذي يقرؤه الضابط على الطريق — ليست رسالة مترجمة، لذا لا
/// تمر عبر arb. الألوان من السمة حتى لا ينكسر الوضع الداكن.
class InspectionLogHeaderTable extends StatelessWidget {
  const InspectionLogHeaderTable({
    super.key,
    this.screen,
    this.day,
    this.log,
    this.driverLicense = '-',
    this.driverLicenseState = '-',
    this.coDriver = '',
    this.coDriverId = '',
  });

  final DotInspectionScreen? screen;
  final DotInspectionCycleDay? day;
  final DotInspectionLog? log;
  final String driverLicense;
  final String driverLicenseState;
  final String coDriver;
  final String coDriverId;

  /// السجل المجلوب لليوم المحدد هو الأحدث دائماً؛ بيانات الدورة لقطة
  /// بداية التفتيش وقد تكون فارغة. القاعدة: أول قيمة غير فارغة بترتيب
  /// (log → day → screen) — وإلا تبقى قيمة قديمة/فارغة معروضة رغم تغير اليوم.
  static String _pick(String? fresh, String? snap, [String? fallback = '']) {
    if (fresh != null && fresh.trim().isNotEmpty) return fresh;
    if (snap != null && snap.trim().isNotEmpty) return snap;
    return fallback ?? '';
  }

  String get _driverName =>
      _pick(log?.driverName, day?.driverName, screen?.driverName);
  String get _driverId {
    final id =
        log?.driverId.value ?? day?.driverId.value ?? screen?.driverId.value;
    return id?.toString() ?? '';
  }

  String get _vehicle =>
      _pick(log?.vehicleNumber, day?.vehicleNumber);
  String get _vin => _pick(log?.vin, day?.vin);
  String get _trailers => _pick(log?.trailers, day?.trailers);
  String get _shipping =>
      _pick(log?.shippingDocuments, day?.shippingDocuments);
  String get _carrier {
    final name =
        _pick(log?.carrierName, day?.carrierName, screen?.carrierName);
    final usdot =
        _pick(log?.usdotNumber, day?.usdotNumber, screen?.usdotNumber);
    if (usdot.isEmpty) return name;
    return '$name (DOT # $usdot)';
  }

  String get _office =>
      _pick(log?.mainOfficeAddress, day?.mainOfficeAddress);
  String get _terminal =>
      _pick(log?.homeTerminalAddress, day?.homeTerminalAddress);
  String get _reg => _pick(log?.eldRegistrationId, day?.eldRegistrationId,
      screen?.eldRegistrationId);
  String get _eldId => _pick(
      log?.eldIdentifier, day?.eldIdentifier, screen?.eldIdentifier);
  String get _provider => _pick(log?.eldProvider, day?.eldProvider);
  String get _location =>
      _pick(log?.displayLocation, day?.displayLocation);
  String get _logDate => _pick(log?.displayDate, day?.displayDate);
  bool get _certified => log?.certified ?? day?.certified ?? false;
  bool get _exempt => day?.exemptDriver ?? false;
  bool get _unidentified =>
      day?.hasUnidentifiedDriving ?? ((day?.unidentifiedDrivingCount ?? 0) > 0);
  // اتحاد المصدرين: مؤشر نشط في أي منهما يجب أن يظهر (395.8(k)).
  List<String> get _diagList => {
        ...?day?.activeDataDiagnostics,
        ...?log?.activeDataDiagnostics,
      }.toList();
  List<String> get _malfList => {
        ...?day?.activeDeviceMalfunctions,
        ...?log?.activeDeviceMalfunctions,
      }.toList();

  bool get _diag => _diagList.isNotEmpty;
  // 395.8(k)/8.3 — an indicator that is ON must say which code(s) are active.
  String get _diagCodes => _diagList.join(', ');
  String get _malfCodes => _malfList.join(', ');

  bool get _malf => _malfList.isNotEmpty;

  // 49 CFR 395.8 / SRS 8.3 — the roadside display is in miles.
  static const double _kmPerMile = 1.609344;
  static String _mi(double km) => (km / _kmPerMile).toStringAsFixed(0);

  /// الأصفار تعني غياب القراءة غالباً ( freezeds غير nullable) —
  /// القيمة غير الصفرية من السجل المجلوب أولاً.
  static double _num(double? fresh, double? snap) {
    if (fresh != null && fresh != 0) return fresh;
    if (snap != null && snap != 0) return snap;
    return fresh ?? snap ?? 0;
  }

  String get _odometer {
    final start = _num(log?.startOdometerKm, day?.startOdometerKm);
    final end = _num(log?.endOdometerKm, day?.endOdometerKm);
    if (start == 0 && end == 0) return '';
    if (start != end) {
      return '${_mi(start)} - ${_mi(end)} mi';
    }
    return '${_mi(end)} mi';
  }

  String get _distance {
    final d = _num(log?.totalDistanceKm, day?.totalDistanceKm);
    if (d == 0) return '';
    return '${_mi(d)} mi';
  }

  String get _engine {
    final h = _num(log?.engineHours, day?.engineHours);
    if (h == 0) return '';
    return h.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _headerRow(context, const [
          'Driver Name',
          'Driver ID',
          'Driver License',
          'Driver License State',
        ]),
        _valueRow(context, [
          _driverName,
          _driverId,
          log?.driverLicenseNumber ?? driverLicense,
          log?.driverLicenseState ?? driverLicenseState,
        ]),
        _headerRow(context, const [
          'Exempt Driver Status',
          'Unidentified Driving Records',
          'Co-driver',
          'Co-driver ID',
        ]),
        _valueRow(context, [
          _exempt ? 'Yes' : 'No',
          _unidentified ? 'Yes' : 'No',
          log?.coDriverName ?? coDriver,
          log?.coDriverId?.toString() ?? coDriverId,
        ]),
        _headerRow(context, const [
          'Log Date',
          'Display Date',
          'Display Location',
          'Driver Certified',
        ]),
        _valueRow(context, [
          _logDate,
          _logDate,
          _location,
          _certified ? 'Yes' : 'No',
        ]),
        _headerRow(context, const [
          'ELD Registration ID',
          'ELD Identifier',
          'Provider',
        ]),
        _valueRow(context, [_reg, _eldId, _provider]),
        _headerRow(context, const [
          '24 Period Starting Time',
          'Data Diag. Indicators',
          'Device Malfn. Indicators',
        ]),
        _valueRow(context, [
          log?.period24HourStartTime ?? '—',
          _diag ? _diagCodes : 'No',
          _malf ? _malfCodes : 'No',
        ]),
        _headerRow(context, const [
          'Vehicle',
          'VIN',
          'Odometer',
          'Distance',
          'Engine Hours',
        ]),
        _valueRow(context, [_vehicle, _vin, _odometer, _distance, _engine]),
        _headerRow(context, const [
          'Trailers',
          'Shipping Docs',
          'Carrier',
          'Main Office',
          'Home Terminal',
        ]),
        _valueRow(context, [_trailers, _shipping, _carrier, _office, _terminal]),
      ],
    );
  }

  Widget _headerRow(BuildContext context, List<String> labels) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final label in labels)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueRow(BuildContext context, List<String> values) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
