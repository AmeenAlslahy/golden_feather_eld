import 'package:flutter/material.dart';

import '../../../../domain/inspection/dot_inspection.dart';

/// Dense striped header matching the Inspection Logs screenshot.
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
  bool get _malf =>
      (day?.activeDeviceMalfunctions ?? log?.activeDeviceMalfunctions ?? const <String>[])
          .isNotEmpty;

  String get _odometer {
    final start = day?.startOdometerKm ?? log?.startOdometerKm;
    final end = day?.endOdometerKm ?? log?.endOdometerKm;
    if (start == null && end == null) return '';
    if (start != null && end != null && start != end) {
      return '${start.toStringAsFixed(0)} - ${end.toStringAsFixed(0)}';
    }
    return (end ?? start)!.toStringAsFixed(0);
  }

  String get _distance {
    final d = day?.totalDistanceKm ?? log?.totalDistanceKm;
    if (d == null) return '';
    return d.toStringAsFixed(0);
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
        _headerRow(const [
          'Driver Name',
          'Driver ID',
          'Driver License',
          'Driver License State',
        ]),
        _valueRow([_driverName, _driverId, driverLicense, driverLicenseState]),
        _headerRow(const [
          'Exempt Driver Status',
          'Unidentified Driving Records',
          'Co-driver',
          'Co-driver ID',
        ]),
        _valueRow([
          _exempt ? 'Yes' : 'No',
          _unidentified ? 'Yes' : 'No',
          coDriver.isEmpty ? '' : coDriver,
          coDriverId,
        ]),
        _headerRow(const [
          'Log Date',
          'Display Date',
          'Display Location',
          'Driver Certified',
        ]),
        _valueRow([
          _logDate,
          _logDate,
          _location,
          _certified ? 'Yes' : 'No',
        ]),
        _headerRow(const [
          'ELD Registration ID',
          'ELD Identifier',
          'Provider',
        ]),
        _valueRow([_reg, _eldId, _provider]),
        _headerRow(const [
          '24 Period Starting Time',
          'Data Diag. Indicators',
          'Device Malfn. Indicators',
        ]),
        _valueRow([
          '—',
          _diag ? 'Yes' : 'No',
          _malf ? 'Yes' : 'No',
        ]),
        _headerRow(const [
          'Vehicle',
          'VIN',
          'Odometer',
          'Distance',
          'Engine Hours',
        ]),
        _valueRow([_vehicle, _vin, _odometer, _distance, _engine]),
        _headerRow(const [
          'Trailers',
          'Shipping Docs',
          'Carrier',
          'Main Office',
          'Home Terminal',
        ]),
        _valueRow([_trailers, _shipping, _carrier, _office, _terminal]),
      ],
    );
  }

  Widget _headerRow(List<String> labels) {
    return Container(
      color: const Color(0xFFF2F2F2),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueRow(List<String> values) {
    return Container(
      color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
