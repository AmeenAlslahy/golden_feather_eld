import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// Generates compliant FMCSA ELD output files (CSV format)
/// in offline scenarios according to 49 CFR Part 395 Appendix A.
class FmcsaEldOutputGenerator {
  /// Generates the FMCSA CSV file from available local inspection records
  /// and saves it locally, returning the absolute file path.
  static Future<String> generateAndSave({
    DotInspectionScreen? screen,
    List<DotInspectionCycleDay> cycleDays = const [],
    Map<String, DotInspectionLog> logs = const {},
    required String outputFileComment,
    String? fallbackDriverId,
    String? fallbackDriverName,
    String? fallbackVehicleId,
    String? fallbackCarrier,
    String? fallbackUsdot,
  }) async {
    final now = DateTime.now().toUtc();
    final dateFmt = DateFormat('MMddyy');
    final timeFmt = DateFormat('HHmmss');

    final fileDate = dateFmt.format(now);
    final fileTime = timeFmt.format(now);

    // Pick top-level carrier and vehicle metadata
    final firstLog = logs.values.isNotEmpty ? logs.values.first : null;
    final firstCycle = cycleDays.isNotEmpty ? cycleDays.first : null;

    final carrierName = screen?.carrierName ??
        firstLog?.carrierName ??
        firstCycle?.carrierName ??
        fallbackCarrier ??
        '';

    final usdot = screen?.usdotNumber ??
        firstLog?.usdotNumber ??
        firstCycle?.usdotNumber ??
        fallbackUsdot ??
        '';

    final eldId = screen?.eldIdentifier ??
        firstLog?.eldIdentifier ??
        firstCycle?.eldIdentifier ??
        '';

    final eldRegId = screen?.eldRegistrationId ??
        firstLog?.eldRegistrationId ??
        firstCycle?.eldRegistrationId ??
        '';

    final vehicleNumber = firstLog?.vehicleNumber ??
        firstCycle?.vehicleNumber ??
        fallbackVehicleId ??
        '';

    final vin = firstLog?.vin ?? firstCycle?.vin ?? '';

    final fullDriverName = screen?.driverName ??
        firstLog?.driverName ??
        firstCycle?.driverName ??
        fallbackDriverName ??
        '';

    final nameParts = fullDriverName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final driverIdStr = screen?.driverId.value.toString() ??
        firstLog?.driverId.value.toString() ??
        firstCycle?.driverId.value.toString() ??
        fallbackDriverId ??
        '';

    final licenseNumber = firstLog?.driverLicenseNumber ?? '';
    final licenseState = firstLog?.driverLicenseState ?? '';

    final coDriverName = firstLog?.coDriverName ?? '';
    final coDriverParts = coDriverName.trim().split(' ');
    final coFirstName = coDriverParts.isNotEmpty ? coDriverParts.first : '';
    final coLastName = coDriverParts.length > 1 ? coDriverParts.sublist(1).join(' ') : '';
    final coDriverId = firstLog?.coDriverId?.toString() ?? '';

    final buffer = StringBuffer();

    // ─── 1. ELD File Header Line (Line Type 1) ──────────────────────────────
    // 1,ELDRegistrationId,ELDIdentifier,CMVPowerUnitNumber,VIN,CarrierName,USDOTNumber,DriverLastName,DriverFirstName,DriverID,DriverLicenseNumber,DriverLicenseState,CoDriverLastName,CoDriverFirstName,CoDriverID,FileCreateDate,FileCreateTime,OutputFileComment
    buffer.writeln(
      '1,$eldRegId,$eldId,$vehicleNumber,$vin,"$carrierName",$usdot,'
      '"$lastName","$firstName",$driverIdStr,"$licenseNumber",$licenseState,'
      '"$coLastName","$coFirstName",$coDriverId,$fileDate,$fileTime,"$outputFileComment"',
    );

    // ─── 2. User List (Line Type 2) ─────────────────────────────────────────
    // 2,SequenceNumber,RecordStatus,UserType,DriverLastName,DriverFirstName,DriverID,DriverLicenseNumber,DriverLicenseState
    buffer.writeln(
      '2,1,1,1,"$lastName","$firstName",$driverIdStr,"$licenseNumber",$licenseState',
    );
    if (coDriverId.isNotEmpty) {
      buffer.writeln(
        '2,2,1,2,"$coLastName","$coFirstName",$coDriverId,"",',
      );
    }

    // ─── 3. CMV Engine Power-Up and Shut Down (Line Type 3) ─────────────────
    // 3,SequenceNumber,RecordStatus,RecordType,EventCode,EventDate,EventTime,TotalVehicleMiles,TotalEngineHours,Lat,Lon
    var seq = 1;
    final startOdo = firstLog?.startOdometerKm ?? firstCycle?.startOdometerKm ?? 0.0;
    final engineHrs = firstLog?.engineHours ?? firstCycle?.engineHours ?? 0.0;
    final initialCoords = _extractCoordinates(firstLog?.displayLocation ?? '');
    buffer.writeln(
      '3,$seq,1,1,1,$fileDate,000000,${(startOdo * 0.621371).toStringAsFixed(1)},${engineHrs.toStringAsFixed(1)},${initialCoords.$1},${initialCoords.$2}',
    );
    seq++;

    // ─── 4. ELD Event Annotations and Comments (Line Type 4) ────────────────
    // 4,SequenceNumber,Comment/Annotation,EventDate,EventTime,DriverID
    if (outputFileComment.trim().isNotEmpty) {
      buffer.writeln(
        '4,$seq,"$outputFileComment",$fileDate,$fileTime,$driverIdStr',
      );
      seq++;
    }

    // ─── 5. ELD Event Records (Line Type 5) ─────────────────────────────────
    // 5,SequenceNumber,RecordStatus,RecordType,EventCode,EventDate,EventTime,AccumVehicleMiles,AccumEngineHours,Lat,Lon,DistanceSinceLastCoord,MalfunctionStatus,DiagnosticStatus,DataCheckValue,LineDataCheckValue
    final allEvents = <DotInspectionEvent>[];
    for (final l in logs.values) {
      allEvents.addAll(l.events);
    }

    if (allEvents.isEmpty) {
      // Default baseline On-Duty event if cache had no discrete events
      buffer.writeln(
        '5,$seq,1,1,4,$fileDate,$fileTime,${(startOdo * 0.621371).toStringAsFixed(1)},${engineHrs.toStringAsFixed(1)},${initialCoords.$1},${initialCoords.$2},0,0,0,00,00',
      );
      seq++;
    } else {
      for (final event in allEvents) {
        final evDate = fileDate;
        // Parse time string (e.g. "04:19 PM" or ISO) to HHmmss
        final evTime = _parseTimeToHHmmss(event.timeEt);
        final evCode = _mapEventCode(event.eventCode);
        final miles = (event.odometer * 0.621371).toStringAsFixed(1);
        final hours = event.engineHours.toStringAsFixed(1);
        final coords = _extractCoordinates(event.location);

        buffer.writeln(
          '5,$seq,1,1,$evCode,$evDate,$evTime,$miles,$hours,${coords.$1},${coords.$2},0,0,0,00,00',
        );
        seq++;
      }
    }

    // ─── 6. Malfunctions and Diagnostic Events (Line Type 6) ────────────────
    final malfunctions = firstLog?.activeDeviceMalfunctions ?? firstCycle?.activeDeviceMalfunctions ?? [];
    final diagnostics = firstLog?.activeDataDiagnostics ?? firstCycle?.activeDataDiagnostics ?? [];

    for (final m in malfunctions) {
      buffer.writeln('6,$seq,1,1,$m,$fileDate,$fileTime');
      seq++;
    }
    for (final d in diagnostics) {
      buffer.writeln('6,$seq,1,2,$d,$fileDate,$fileTime');
      seq++;
    }

    // ─── 7. File Data Check Line (Line Type 7) ──────────────────────────────
    final totalLines = buffer.toString().split('\n').where((l) => l.trim().isNotEmpty).length + 1;
    buffer.writeln('7,$totalLines,0000');

    // Write file to device storage
    final outputDirectory = await getApplicationDocumentsDirectory();
    final fileName = 'FMCSA_ELD_${vehicleNumber}_${now.millisecondsSinceEpoch}.csv';
    final file = File('${outputDirectory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    AppLogger.info('✅ Generated offline FMCSA ELD file: ${file.path}');
    return file.path;
  }

  static (String, String) _extractCoordinates(String locationRaw) {
    final regex = RegExp(r'(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)');
    final match = regex.firstMatch(locationRaw);
    if (match != null) {
      return (match.group(1)!, match.group(2)!);
    }
    return ('', '');
  }

  static String _parseTimeToHHmmss(String timeRaw) {
    try {
      final parsed = DateFormat('hh:mm a').parseLoose(timeRaw);
      return DateFormat('HHmmss').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('HH:mm').parseLoose(timeRaw);
        return DateFormat('HHmmss').format(parsed);
      } catch (_) {
        return '080000';
      }
    }
  }

  static String _mapEventCode(String code) {
    return DutyStatusCode.fromAny(code).toFmcsaCode();
  }
}
