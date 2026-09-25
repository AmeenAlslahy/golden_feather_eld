import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/transfer_audit.dart';

/// Provides the inspection screen for the current driver.
final dotInspectionScreenProvider =
    AsyncNotifierProvider<DotInspectionScreenNotifier, DotInspectionScreen>(
  DotInspectionScreenNotifier.new,
);

class DotInspectionScreenNotifier extends AsyncNotifier<DotInspectionScreen> {
  @override
  Future<DotInspectionScreen> build() async {
    final backend = ref.watch(activeBackendProvider);
    final inspectionBackend = backend.inspection;
    if (inspectionBackend == null) {
      throw StateError('Inspection backend not available');
    }

    final result = await inspectionBackend.getScreen();
    return result.fold((e) => throw e, (screen) => screen);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final backend = ref.read(activeBackendProvider);
      final inspectionBackend = backend.inspection;
      if (inspectionBackend == null) {
        throw StateError('Inspection backend not available');
      }
      final result = await inspectionBackend.getScreen();
      return result.fold((e) => throw e, (screen) => screen);
    });
  }
}

/// Official transfer audit. A local edit list is not this record.
final transferAuditProvider = FutureProvider<List<TransferAuditRow>>((ref) async {
  final backend = ref.watch(activeBackendProvider).inspection;
  if (backend == null) {
    throw StateError('Inspection backend not available');
  }
  final driverId = ref.watch(currentDriverIdProvider);
  final result = await backend.getTransfers(
    driverId: driverId == null ? null : DriverId(driverId),
  );
  return result.fold((error) => throw error, (json) {
    final rows = parseTransferAudit(json);
    if (rows == null) {
      throw StateError('Transfer audit response was not a list');
    }
    return rows;
  });
});

/// Provides the 8-day cycle for the current driver.
final dotInspectionCycleProvider =
    AsyncNotifierProvider<DotInspectionCycleNotifier, List<DotInspectionCycleDay>>(
  DotInspectionCycleNotifier.new,
);

class DotInspectionCycleNotifier
    extends AsyncNotifier<List<DotInspectionCycleDay>> {
  @override
  Future<List<DotInspectionCycleDay>> build() async {
    final backend = ref.watch(activeBackendProvider);
    final inspectionBackend = backend.inspection;
    if (inspectionBackend == null) {
      throw StateError('Inspection backend not available');
    }

    final result = await inspectionBackend.getCycle();
    return result.fold((e) => throw e, (days) => days);
  }
}
