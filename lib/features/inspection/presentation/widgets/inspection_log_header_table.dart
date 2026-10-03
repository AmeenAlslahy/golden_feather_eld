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

  String get _driverName =>
      day?.driverName ?? log?.driverName ?? screen?.driverName ?? '';
  String get _driverId {
    final id = day?.driverId.value ?? log?.driverId.value ?? screen?.driverId.value;
    return id?.toString() ?? '';
  }

  String get _vehicle => day?.vehicleNumber ?? log?.vehicleNumber ?? '';
  String get _vin => day?.vin ?? log?.vin ?? '';
  String get _trailers => day?.trailers ?? log?.trailers ?? '';
  String get _shipping => day?.shippingDocuments ?? log?.shippingDocuments ?? '';
  String get _carrier {
    final name = day?.carrierName ?? log?.carrierName ?? screen?.carrierName ?? '';
    final usdot = day?.usdotNumber ?? log?.usdotNumber ?? screen?.usdotNumber ?? '';
    if (usdot.isEmpty) return name;
    return '$name (DOT # $usdot)';
  }

  String get _office => day?.mainOfficeAddress ?? log?.mainOfficeAddress ?? '';
  String get _terminal => day?.homeTerminalAddress ?? log?.homeTerminalAddress ?? '';
  String get _reg =>
      day?.eldRegistrationId ?? log?.eldRegistrationId ?? screen?.eldRegistrationId ?? '';
  String get _eldId =>
      day?.eldIdentifier ?? log?.eldIdentifier ?? screen?.eldIdentifier ?? '';
  String get _provider => day?.eldProvider ?? log?.eldProvider ?? '';
  String get _location => day?.displayLocation ?? log?.displayLocation ?? '';
  String get _logDate => day?.displayDate ?? log?.displayDate ?? '';
  bool get _certified => day?.certified ?? log?.certified ?? false;
  bool get _exempt => day?.exemptDriver ?? false;
  bool get _unidentified =>
      day?.hasUnidentifiedDriving ?? ((day?.unidentifiedDrivingCount ?? 0) > 0);
  bool get _diag =>
      (day?.activeDataDiagnostics ?? log?.activeDataDiagnostics ?? const <String>[])
          .isNotEmpty;
  // 395.8(k)/8.3 — an indicator that is ON must say which code(s) are active.
  String get _diagCodes =>
      (day?.activeDataDiagnostics ?? log?.activeDataDiagnostics ?? const <String>[])
          .join(', ');
  String get _malfCodes =>
      (day?.activeDeviceMalfunctions ?? log?.activeDeviceMalfunctions ?? const <String>[])
          .join(', ');

  bool get _malf =>
      (day?.activeDeviceMalfunctions ?? log?.activeDeviceMalfunctions ?? const <String>[])
          .isNotEmpty;

  // 49 CFR 395.8 / SRS 8.3 — the roadside display is in miles.
  static const double _kmPerMile = 1.609344;
  static String _mi(double km) => (km / _kmPerMile).toStringAsFixed(0);

  String get _odometer {
    final start = day?.startOdometerKm ?? log?.startOdometerKm;
    final end = day?.endOdometerKm ?? log?.endOdometerKm;
    if (start == null && end == null) return '';
    if (start != null && end != null && start != end) {
      return '${_mi(start)} - ${_mi(end)} mi';
    }
    return '${_mi((end ?? start)!)} mi';
  }

  String get _distance {
    final d = day?.totalDistanceKm ?? log?.totalDistanceKm;
    if (d == null) return '';
    return '${_mi(d)} mi';
  }

  String get _engine {
    final h = day?.engineHours ?? log?.engineHours;
    if (h == null) return '';
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
