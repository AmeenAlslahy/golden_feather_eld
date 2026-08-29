import 'package:equatable/equatable.dart';

/// كائن يمثل هوية الجهاز والمركبة والسائق في نظام التتبع،
/// لضمان فصل المُعرفات الخاصة بالتطبيق عن الخوادم الخارجية (مثل Traccar).
class DeviceIdentity extends Equatable {
  final String? appDeviceId;
  final String? traccarDeviceId;
  final String? vehicleId;
  final String? driverId;
  final String? eldHardwareId;

  const DeviceIdentity({
    this.appDeviceId,
    this.traccarDeviceId,
    this.vehicleId,
    this.driverId,
    this.eldHardwareId,
  });

  DeviceIdentity copyWith({
    String? appDeviceId,
    String? traccarDeviceId,
    String? vehicleId,
    String? driverId,
    String? eldHardwareId,
  }) {
    return DeviceIdentity(
      appDeviceId: appDeviceId ?? this.appDeviceId,
      traccarDeviceId: traccarDeviceId ?? this.traccarDeviceId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      eldHardwareId: eldHardwareId ?? this.eldHardwareId,
    );
  }

  @override
  List<Object?> get props => [
        appDeviceId,
        traccarDeviceId,
        vehicleId,
        driverId,
        eldHardwareId,
      ];
}
