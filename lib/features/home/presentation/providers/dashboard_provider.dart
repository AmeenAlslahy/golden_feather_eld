import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';

/// بيانات لوحة القيادة
class DashboardData {
  final String driverName;
  final String? driverLicense;
  final String vehicleId;
  final String vehicleDisplayName;
  final String? trailerId;
  final String? shippingDocuments;
  final String? coDriverName;
  final String? coDriverId;
  final String? documentsInfo;

  const DashboardData({
    required this.driverName,
    this.driverLicense,
    required this.vehicleId,
    required this.vehicleDisplayName,
    this.trailerId,
    this.shippingDocuments,
    this.coDriverName,
    this.coDriverId,
    this.documentsInfo,
  });

  DashboardData copyWith({
    String? driverName,
    String? driverLicense,
    String? vehicleId,
    String? vehicleDisplayName,
    String? trailerId,
    String? shippingDocuments,
    String? coDriverName,
    String? coDriverId,
    String? documentsInfo,
  }) {
    return DashboardData(
      driverName: driverName ?? this.driverName,
      driverLicense: driverLicense ?? this.driverLicense,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleDisplayName: vehicleDisplayName ?? this.vehicleDisplayName,
      trailerId: trailerId ?? this.trailerId,
      shippingDocuments: shippingDocuments ?? this.shippingDocuments,
      coDriverName: coDriverName ?? this.coDriverName,
      coDriverId: coDriverId ?? this.coDriverId,
      documentsInfo: documentsInfo ?? this.documentsInfo,
    );
  }

  static const empty = DashboardData(
    driverName: 'Unknown',
    driverLicense: '',
    vehicleId: 'No Vehicle',
    vehicleDisplayName: 'Select a vehicle',
    trailerId: 'None',
    shippingDocuments: 'None',
    coDriverName: 'None',
    coDriverId: 'none',
    documentsInfo: null,
  );
}

class DashboardNotifier extends StateNotifier<DashboardData> {
  DashboardNotifier() : super(DashboardData.empty);

  void updateUserData(String name, String? email) {
    state = state.copyWith(
      driverName: name,
    );
  }

  void updateVehicle(dynamic vehicle) {
    if (vehicle == null) {
      state = state.copyWith(
        vehicleId: 'No Vehicle',
        vehicleDisplayName: 'Select a vehicle',
      );
      return;
    }

    state = state.copyWith(
      vehicleId: vehicle.id?.toString() ?? '',
      vehicleDisplayName: vehicle.name ?? vehicle.year ?? '',
    );
  }

  void updateCoDriver(dynamic coDriver) {
    if (coDriver == null) return;
    state = state.copyWith(
      coDriverId: coDriver.id,
      coDriverName: coDriver.name,
    );
  }
}

final dashboardDataProvider =
    StateNotifierProvider<DashboardNotifier, DashboardData>((ref) {
  final notifier = DashboardNotifier();

  // Listen to Auth State
  ref.listen(
    authStateProvider,
    (previous, next) {
      if (next.user != null) {
        notifier.updateUserData(next.user!.fullName, next.user!.email);
      }
    },
    fireImmediately: true,
  );

  // Listen to Vehicle State
  ref.listen(
    vehicleProvider,
    (previous, next) {
      notifier.updateVehicle(next.selectedVehicle);
    },
    fireImmediately: true,
  );

  return notifier;
});
