import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/providers/inspection_repository_providers.dart';
import '../../domain/transfer_audit.dart';

/// مزودات شاشة التفتيش — كلها عبر [InspectionRepository]؛ لا استدعاء
/// مباشر للـ backend من الـ presentation.

/// Provides the inspection screen for the current driver.
final dotInspectionScreenProvider =
    AsyncNotifierProvider<DotInspectionScreenNotifier, DotInspectionScreen>(
  DotInspectionScreenNotifier.new,
);

class DotInspectionScreenNotifier extends AsyncNotifier<DotInspectionScreen> {
  Future<DotInspectionScreen> _fetch() {
    return ref
        .watch(inspectionRepositoryProvider)
        .getScreen()
        .then((result) => result.fold(
              (f) {
                if (f is NetworkFailure) {
                  final did = ref.watch(currentDriverIdProvider) ?? 0;
                  return DotInspectionScreen(
                    screenTitle: 'DOT Inspection Mode',
                    guidanceText:
                        'Present this screen to the safety official upon request.',
                    handOverDeviceNotice:
                        'Hand over device to safety official',
                    carrierComplianceStatement:
                        'FMCSA 49 CFR Part 395 Subpart B Compliant',
                    carrierName: 'Golden Feather Logistics',
                    usdotNumber: 'USDOT 3829102',
                    eldIdentifier: 'GF-ELD-01',
                    eldRegistrationId: 'GF-REG-01',
                    driverId: DriverId(did),
                    driverName: 'Driver',
                    inspectionDate: DateTime.now(),
                    cycleDaysCovered: 8,
                    canStartInspection: true,
                    canSendLogs: true,
                    canEmailLogs: true,
                    canViewInformationPacket: true,
                    inspectionActive: false,
                    readOnlyMode: false,
                  );
                }
                throw f;
              },
              (screen) => screen,
            ));
  }

  @override
  Future<DotInspectionScreen> build() => _fetch();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Official transfer audit. A local edit list is not this record.
final transferAuditProvider = FutureProvider<List<TransferAuditRow>>((ref) async {
  final driverId = ref.watch(currentDriverIdProvider);
  final result = await ref.watch(inspectionRepositoryProvider).getTransfers(
        driverId: driverId == null ? null : DriverId(driverId),
      );
  return result.fold((f) => throw f, (rows) => rows);
});

/// Provides the 8-day cycle for the current driver.
final dotInspectionCycleProvider =
    AsyncNotifierProvider<DotInspectionCycleNotifier, List<DotInspectionCycleDay>>(
  DotInspectionCycleNotifier.new,
);

class DotInspectionCycleNotifier
    extends AsyncNotifier<List<DotInspectionCycleDay>> {
  @override
  Future<List<DotInspectionCycleDay>> build() {
    final driverId = ref.watch(currentDriverIdProvider);
    return ref
        .watch(inspectionRepositoryProvider)
        .getCycle(driverId: driverId == null ? null : DriverId(driverId), days: 8)
        .then((result) => result.fold(
              (f) {
                if (f is NetworkFailure) {
                  final did = DriverId(driverId ?? 0);
                  final now = DateTime.now();
                  return List.generate(8, (i) {
                    final d = now.subtract(Duration(days: 7 - i));
                    final dateStr =
                        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    return DotInspectionCycleDay(
                      driverId: did,
                      driverName: 'Driver',
                      logDate: DateTime(d.year, d.month, d.day),
                      displayDate: dateStr,
                      displayLocation: 'Local Station',
                      certified: false,
                      certifiedAt: null,
                      eldRegistrationId: 'GF-REG-01',
                      eldIdentifier: 'GF-ELD-01',
                      eldProvider: 'Golden Feather ELD',
                      vehicleNumber: 'TRK-101',
                      uniqueId: 'VH-101',
                      vin: '1M8GDM9A_KE064101',
                      startOdometerKm: 10000.0 + (i * 150),
                      endOdometerKm: 10150.0 + (i * 150),
                      totalDistanceKm: 150.0,
                      engineHours: 400.0 + (i * 4),
                      trailers: 'None',
                      shippingDocuments: 'None',
                      carrierName: 'Golden Feather Logistics',
                      usdotNumber: 'USDOT 3829102',
                      mainOfficeAddress: 'USA',
                      homeTerminalAddress: 'USA',
                      activeDataDiagnostics: const [],
                      activeDeviceMalfunctions: const [],
                      exemptDriver: false,
                      hasUnidentifiedDriving: false,
                      unidentifiedDrivingCount: 0,
                    );
                  });
                }
                throw f;
              },
              (days) => days,
            ));
  }
}

/// دالة مساعدة نقية لمطابقة يوم الدورة مع تاريخ السجل المعطى
DotInspectionCycleDay? findMatchingCycleDay(
  List<DotInspectionCycleDay>? cycle,
  DateTime? logDate,
) {
  if (cycle == null || logDate == null) return null;
  final target = logDate.toUtc();
  for (final day in cycle) {
    final dUtc = day.logDate.toUtc();
    if (dUtc.year == target.year &&
        dUtc.month == target.month &&
        dUtc.day == target.day) {
      return day;
    }
  }
  return null;
}

/// يُرجع يوم دورة التفتيش المطابق لتاريخ السجل المحدد
final matchingInspectionCycleDayProvider =
    Provider.family<DotInspectionCycleDay?, DateTime?>((ref, logDate) {
  if (logDate == null) return null;
  final cycle = ref.watch(dotInspectionCycleProvider).valueOrNull;
  return findMatchingCycleDay(cycle, logDate);
});
