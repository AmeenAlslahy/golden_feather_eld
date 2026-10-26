import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
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

  String get _vehicle => _pick(log?.vehicleNumber, day?.vehicleNumber);
  String get _vin => _pick(log?.vin, day?.vin);
  String get _trailers => _pick(log?.trailers, day?.trailers);
  String get _shipping => _pick(log?.shippingDocuments, day?.shippingDocuments);
  String get _carrier {
    final name = _pick(log?.carrierName, day?.carrierName, screen?.carrierName);
    final usdot = _pick(
      log?.usdotNumber,
      day?.usdotNumber,
      screen?.usdotNumber,
    );
    if (usdot.isEmpty) return name;
    return '$name (DOT # $usdot)';
  }

  String get _office => _pick(log?.mainOfficeAddress, day?.mainOfficeAddress);
  String get _terminal =>
      _pick(log?.homeTerminalAddress, day?.homeTerminalAddress);
  String get _reg => _pick(
    log?.eldRegistrationId,
    day?.eldRegistrationId,
    screen?.eldRegistrationId,
  );
  String get _eldId =>
      _pick(log?.eldIdentifier, day?.eldIdentifier, screen?.eldIdentifier);
  String get _provider => _pick(log?.eldProvider, day?.eldProvider);
  String get _location => _pick(log?.displayLocation, day?.displayLocation);
  static String _formatHeaderDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatDisplayDate(String? direct, DateTime? fallbackDt) {
    if (direct != null && direct.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(direct.trim());
      if (parsed != null) {
        return _formatHeaderDate(parsed);
      }
      return direct.trim();
    }
    return _formatHeaderDate(fallbackDt);
  }

  String get _logDate {
    final dt = log?.logDate ?? day?.logDate;
    return _formatHeaderDate(dt);
  }

  String get _displayDate {
    final direct = _pick(log?.displayDate, day?.displayDate);
    final fallbackDt = log?.logDate ?? day?.logDate ?? screen?.inspectionDate;
    return _formatDisplayDate(direct, fallbackDt);
  }

  String get _periodStartTime {
    final raw = log?.period24HourStartTime;
    if (raw != null && raw.trim().isNotEmpty && raw != '—') {
      final trimmed = raw.trim();
      if (trimmed.length == 8 && trimmed.endsWith(':00')) {
        return trimmed.substring(0, 5);
      }
      return trimmed;
    }
    return '00:00';
  }

  bool get _certified => log?.certified ?? day?.certified ?? false;
  bool get _exempt => day?.exemptDriver ?? false;
  bool get _unidentified =>
      day?.hasUnidentifiedDriving ?? ((day?.unidentifiedDrivingCount ?? 0) > 0);
  // اتحاد المصدرين: مؤشر نشط في أي منهما يجب أن يظهر (395.8(k)).
  List<String> get _diagList =>
      {...?day?.activeDataDiagnostics, ...?log?.activeDataDiagnostics}.toList();
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
      return '${_mi(start)} - ${_mi(end)}';
    }
    return _mi(end);
  }

  String get _distance {
    final d = _num(log?.totalDistanceKm, day?.totalDistanceKm);
    if (d == 0) return '';
    return _mi(d);
  }

  String get _engine {
    final h = _num(log?.engineHours, day?.engineHours);
    if (h == 0) return '';
    return h.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    const fourColFlex = [26, 24, 28, 22];
    const threeColFlex = [1, 1, 1];
    const vehicleColFlex = [14, 32, 24, 14, 16];
    const carrierColFlex = [12, 18, 26, 22, 22];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerRow(context, const [
          'Driver Name',
          'Driver ID',
          'Driver License',
          'Driver License State',
        ], fourColFlex),
        _valueRow(
          context,
          [
            _driverName,
            _driverId,
            log?.driverLicenseNumber ?? driverLicense,
            log?.driverLicenseState ?? driverLicenseState,
          ],
          fourColFlex,
          fitScale: const [false, true, true, true],
        ),
        _headerRow(context, const [
          'Exempt Driver Status',
          'Unidentified Driving Records',
          'Co-driver',
          'Co-driver ID',
        ], fourColFlex),
        _valueRow(
          context,
          [
            _exempt ? 'Yes' : 'No',
            _unidentified ? 'Yes' : 'No',
            log?.coDriverName ?? coDriver,
            log?.coDriverId?.toString() ?? coDriverId,
          ],
          fourColFlex,
          fitScale: const [true, true, false, true],
        ),
        _headerRow(context, const [
          'Log Date',
          'Display Date',
          'Display Location',
          'Driver Certified',
        ], fourColFlex),
        _valueRow(
          context,
          [_logDate, _displayDate, _location, _certified ? 'Yes' : 'No'],
          fourColFlex,
          fitScale: const [true, true, false, true],
        ),
        _headerRow(context, const [
          'ELD Registration ID',
          'ELD Identifier',
          'Provider',
        ], threeColFlex),
        _valueRow(
          context,
          [_reg, _eldId, _provider],
          threeColFlex,
          fitScale: const [true, true, false],
        ),
        _headerRow(context, const [
          '24 Period Starting Time',
          'Data Diag. Indicators',
          'Device Malfn. Indicators',
        ], threeColFlex),
        _valueRow(
          context,
          [
            _periodStartTime,
            _diag ? _diagCodes : 'No',
            _malf ? _malfCodes : 'No',
          ],
          threeColFlex,
          fitScale: const [true, false, false],
        ),
        _headerRow(context, const [
          'Vehicle',
          'VIN',
          'Odometer',
          'Distance',
          'Engine Hours',
        ], vehicleColFlex),
        _valueRow(
          context,
          [_vehicle, _vin, _odometer, _distance, _engine],
          vehicleColFlex,
          fitScale: const [true, true, true, true, true],
        ),
        _headerRow(context, const [
          'Trailers',
          'Shipping Docs',
          'Carrier',
          'Main Office',
          'Home Terminal',
        ], carrierColFlex),
        _valueRow(
          context,
          [_trailers, _shipping, _carrier, _office, _terminal],
          carrierColFlex,
          fitScale: const [true, true, false, false, false],
        ),
      ],
    );
  }

  Widget _headerRow(
    BuildContext context,
    List<String> labels,
    List<int> flexes,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? cs.surfaceContainerHighest : context.rodsHeaderBg;
    final headerTextColor = isDark ? cs.onSurface : context.rodsHeaderText;

    final headerStyle = context.styles.caption.copyWith(
      fontSize: AppTypography.smallSize,
      fontWeight: AppTypography.bold,
      color: headerTextColor,
      height: 1.2,
    );

    return Container(
      color: headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Text(labels[i], style: headerStyle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueRow(
    BuildContext context,
    List<String> values,
    List<int> flexes, {
    List<bool>? fitScale,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueBg = cs.surface;
    final valueTextColor = isDark ? cs.onSurface : context.textPrimary;

    final valueStyle = context.styles.caption.copyWith(
      fontSize: AppTypography.smallSize,
      fontWeight: AppTypography.regular,
      color: valueTextColor,
      height: 1.25,
    );

    return Container(
      color: valueBg,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: (fitScale != null && i < fitScale.length && fitScale[i])
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          values[i].isEmpty ? ' ' : values[i],
                          style: valueStyle,
                        ),
                      )
                    : Text(
                        values[i].isEmpty ? ' ' : values[i],
                        style: valueStyle,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
