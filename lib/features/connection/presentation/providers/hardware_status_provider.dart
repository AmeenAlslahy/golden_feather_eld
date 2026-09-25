import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../domain/connectivity_status.dart';

export '../../domain/connectivity_status.dart';

final hardwareStatusProvider =
    FutureProvider.autoDispose<ConnectivityStatus>((ref) async {
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
