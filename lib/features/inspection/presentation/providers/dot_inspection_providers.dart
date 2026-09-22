import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/domain/inspection/dot_inspection.dart';

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
