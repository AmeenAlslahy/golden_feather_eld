import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        .then((result) => result.fold((f) => throw f, (screen) => screen));
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
        .then((result) => result.fold((f) => throw f, (days) => days));
  }
}
