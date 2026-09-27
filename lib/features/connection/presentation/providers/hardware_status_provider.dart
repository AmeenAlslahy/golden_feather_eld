import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../domain/connectivity_status.dart';
import '../../domain/hardware_readiness.dart';
import '../../../../core/utils/provider_cache.dart';

export '../../domain/connectivity_status.dart';
export '../../domain/hardware_readiness.dart';

final hardwareStatusProvider =
    FutureProvider.autoDispose<ConnectivityStatus>((ref) async {
  // Short: hardware status must stay fresh, but not re-fetched on every rebuild.
  cacheFor(ref, const Duration(seconds: 30));
  final backend = ref.read(hardwareBackendProvider);
  final uniqueId = ref.watch(vehicleProvider).selectedVehicle?.uniqueId;
  final result = await backend.getStatus(uniqueId: uniqueId);
  return result.fold((failure) => throw failure, (json) {
    final read = parseConnectivityStatus(json);
    if (read == null) {
      throw const FormatException('connectivity body is not an object');
    }
    return read;
  });
});

/// `GET /eld/hardware/readiness` — pre-operation checklist for the selected
/// vehicle. Same freshness policy as the status above.
final hardwareReadinessProvider =
    FutureProvider.autoDispose<HardwareReadiness>((ref) async {
  cacheFor(ref, const Duration(seconds: 30));
  final backend = ref.read(hardwareBackendProvider);
  final uniqueId = ref.watch(vehicleProvider).selectedVehicle?.uniqueId;
  final result = await backend.getReadiness(uniqueId: uniqueId);
  return result.fold((failure) => throw failure, (json) {
    final read = parseHardwareReadiness(json);
    if (read == null) {
      throw const FormatException('readiness body is not an object');
    }
    return read;
  });
});
