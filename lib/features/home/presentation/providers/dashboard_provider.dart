import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../logs/domain/daily_form_rules.dart';
import '../../../logs/domain/entities/daily_form_data.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../codriver/domain/entities/codriver.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';

/// بيانات لوحة القيادة
class DashboardData {
  final String driverName;
  final String? driverLicense;
  final String vehicleId;

  /// معرف جهاز المركبة الرقمي — يمر إلى جسم إنشاء DVIR (شرط الخادم).
  final int? deviceId;
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
    this.deviceId,
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
    int? deviceId,
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
      deviceId: deviceId ?? this.deviceId,
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

  void updateVehicle(Vehicle? vehicle) {
    if (vehicle == null) {
      state = state.copyWith(
        vehicleId: 'No Vehicle',
        vehicleDisplayName: 'Select a vehicle',
      );
      return;
    }

    state = state.copyWith(
      vehicleId: vehicle.id.isNotEmpty ? vehicle.id : 'No Vehicle',
      deviceId: vehicle.deviceId,
      vehicleDisplayName: vehicle.displayName,
    );
  }

  /// Form tab → Trailers page. Stored as the comma-separated form value that
  /// the daily-form SAVE payload reads (SRS 5.5–5.13, one source of truth).
  void updateTrailers(List<String> trailers) {
    state = state.copyWith(trailerId: joinFormList(trailers));
  }

  /// Form tab → Shipping Documents page.
  void updateShippingDocuments(List<String> documents) {
    state = state.copyWith(shippingDocuments: joinFormList(documents));
  }

  void updateCoDriver(CoDriver? coDriver) {
    if (coDriver == null) return;
    state = state.copyWith(
      coDriverId: coDriver.id,
      coDriverName: coDriver.name,
    );
  }

  /// تطبيق نموذج اليوم المحفوظ في الخادم (`GET /eld/daily-logs/{id}/form`)
  /// على الحقول التي يديرها النموذج — ليقرأ تبويب النموذج قيم اليوم
  /// المحفوظة لا بيانات جلسة قديمة. لا يمس deviceId ولا بيانات الجلسة
  /// الحية، والقوائم الفارغة تُترك كما هي (الحفظ لاحقاً هو قرار السائق).
  void applyServerForm(DailyFormData form) {
    if (form.trailers.isNotEmpty) {
      updateTrailers(form.trailers);
    }
    if (form.shippingDocuments.isNotEmpty) {
      updateShippingDocuments(form.shippingDocuments);
    }
    if (form.coDriverId != null && form.coDriverId! > 0) {
      state = state.copyWith(coDriverId: '${form.coDriverId}');
    }
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
      if (next.selectedVehicle != null) {
        notifier.updateVehicle(next.selectedVehicle);
      }
    },
    fireImmediately: true,
  );

  return notifier;
});
