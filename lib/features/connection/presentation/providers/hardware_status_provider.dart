import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';

class HardwareStatusData {
  final String engineVersion;
  final String deviceVersion;
  final String lastDataTime;

  HardwareStatusData({
    required this.engineVersion,
    required this.deviceVersion,
    required this.lastDataTime,
  });

  factory HardwareStatusData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return HardwareStatusData(
      engineVersion: data['engineVersion']?.toString() ?? 'Unknown Engine',
      deviceVersion: data['deviceVersion']?.toString() ?? 'Unknown Device',
      lastDataTime: data['lastDataTime']?.toString() ?? 'No data received yet',
    );
  }
}

final hardwareStatusProvider = FutureProvider.autoDispose<HardwareStatusData>((ref) async {
  final backend = ref.read(hardwareBackendProvider);
  final result = await backend.getStatus();

  return result.fold(
    (failure) => HardwareStatusData(
      engineVersion: 'Error fetching',
      deviceVersion: 'Error fetching',
      lastDataTime: 'Error fetching',
    ),
    (json) => HardwareStatusData.fromJson(json),
  );
});
