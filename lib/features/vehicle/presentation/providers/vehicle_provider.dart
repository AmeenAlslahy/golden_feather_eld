import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/vehicle_repository_providers.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// حالة شاشة المركبات
class VehicleState {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool isSuccess;
  // Nullable storage keeps pre-hot-reload VehicleState instances readable
  // after this field is introduced; null means the personal list.
  final bool? _isCompanyFleet;

  bool get isCompanyFleet => _isCompanyFleet ?? false;

  const VehicleState({
    this.vehicles = const [],
    this.selectedVehicle,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.isSuccess = false,
    bool isCompanyFleet = false,
  }) : _isCompanyFleet = isCompanyFleet;

  List<Vehicle> get filteredVehicles {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return vehicles;
    return vehicles.where((v) {
      return v.id.toLowerCase().contains(query) ||
          v.name.toLowerCase().contains(query) ||
          v.year.toLowerCase().contains(query);
    }).toList();
  }

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    Vehicle? selectedVehicle,
    bool clearSelected = false,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? isSuccess,
    bool? isCompanyFleet,
    bool clearError = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: clearSelected
          ? selectedVehicle
          : (selectedVehicle ?? this.selectedVehicle),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
      isSuccess: isSuccess ?? this.isSuccess,
      isCompanyFleet: isCompanyFleet ?? this.isCompanyFleet,
    );
  }
}

/// مزود المركبات
///
/// P0 Stage 1 — ملكية الجلسة: المصنع يُبقي اعتمادية المستودع فقط (كما كان
/// تماماً حفاظاً على التوافق)، ويستمع لتغيرات المصادقة: أي غياب هوية أو
/// انتقال أو تغير مالك/جيل يُسقط الحالة متزامناً (بلا API) ثم يُعاد الجلب
/// للمالك الجديد وحده (طلب واحد). الردود مسيّجة فلا يكتب رد A فوق حالة B.
///
/// H-D1: ربط أولي لمرة واحدة — إن أُنشئ المزود وجلسة مستقرة قائمة
/// (فتح مباشر بعد login) يُربط مالكها ويُجلب مرة واحدة موسومة.
/// قراءة واحدة بلا اشتراك: لا حلقة إعادة بناء ولا كسر توافق.
/// بلا مصادقة: صمت تام بلا أي طلب.
final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((
  ref,
) {
  final notifier = VehicleNotifier(ref.watch(vehicleRepositoryProvider));
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.user == null || next.transitioning) {
      notifier.reset();
      return;
    }
    final id = next.user!.id;
    if (id != notifier.ownerDriverId ||
        next.sessionEpoch != notifier.ownerEpoch) {
      notifier.bindOwner(id, next.sessionEpoch);
      notifier.loadVehicles(forceRefresh: true);
    }
  });
  final auth = ref.read(authStateProvider);
  if (auth.user != null && !auth.transitioning) {
    notifier.bindOwner(auth.user!.id, auth.sessionEpoch);
    notifier.loadVehicles();
  }
  return notifier;
});

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _repository;

  /// P0 Stage 1 — مالك الحالة + تسلسل الطلبات لسياج الردود المتأخرة.
  String? _ownerDriverId;
  int? _ownerEpoch;
  int _loadSeq = 0;

  String? get ownerDriverId => _ownerDriverId;
  int? get ownerEpoch => _ownerEpoch;

  /// للودجات التي تحتاج قراراً خارج build (تحديث عند الفتح).
  bool get hasVehicles => state.vehicles.isNotEmpty;
  Vehicle? get selectedVehicle => state.selectedVehicle;

  /// Public read-only for page-driven initial-load decisions
  /// (avoids protected `state` access from widgets).
  bool get isInitialized => state.isInitialized;

  /// H-D1: تحميل جارٍ — الصفحة تتخطى التحميل الأولي حين يكون المصنع
  /// قد أطلقه (طلب واحد فقط، بلا Double Fetch).
  bool get isLoading => state.isLoading;

  // P0 corrections: لا تحميل تلقائي في الكونستركتر — الاستماع المجرد
  // (مثل tracking_orchestrator) كان يُطلق GET مالك-بلا-مالك عند كل إقلاع
  // بارد. التحميل الأولي تقوده الصفحة (SelectVehiclePage.initState) أو
  // تغير المالك، وكلاهما محمي بالتسلسل أدناه.
  VehicleNotifier(this._repository) : super(const VehicleState());

  /// ربط بمالك جديد: إسقاط متزامن للحالة (بلا API) وإبطال أي طلب جارٍ.
  void bindOwner(String? driverId, int? epoch) {
    if (_ownerDriverId == driverId && _ownerEpoch == epoch) return;
    _loadSeq++; // إبطال الطلبات الجارية للمالك السابق
    _ownerDriverId = driverId;
    _ownerEpoch = epoch;
    state = const VehicleState();
  }

  /// إسقاط فوري (عند بدء logout) — متزامن، بلا API.
  void reset() => bindOwner(null, null);

  Future<void> loadVehicles({
    bool forceRefresh = false,
    bool background = false,
  }) async {
    // P0 corrections: تسلسل جديد لكل طلب فعلي — الأحدث فقط يكتب
    // (latest-wins لكل قراءة)، والأقدم يُتجاهل بصمت دون تحويله لخطأ
    // جلسة جديدة. الزيادة بعد فحص الـ latch حتى لا يُبطل فحصٌ لا يُرسل
    // طلباً حقيقياً جارٍ.
    if (state.isInitialized && !state.isCompanyFleet && !forceRefresh) return;
    final seq = ++_loadSeq;
    final owner = _ownerDriverId;
    final switchingFromCompanyFleet = state.isCompanyFleet;

    if (!background) {
      state = state.copyWith(
        vehicles: switchingFromCompanyFleet ? const [] : null,
        isLoading: true,
        isInitialized: false,
        isCompanyFleet: false,
        clearError: true,
        isSuccess: false,
      );
    } else {
      state = state.copyWith(
        vehicles: switchingFromCompanyFleet ? const [] : null,
        isCompanyFleet: false,
        isInitialized: false,
      );
    }

    final result = await _repository.getVehicles();

    // P0 Stage 1 — سياج: تجاهل الرد إن تبدلت الهوية أثناء الطيران،
    // ولا تحويله لخطأ يظهر في جلسة جديدة.
    if (!mounted || seq != _loadSeq || owner != _ownerDriverId) return;

    result.match(
      (failure) {
        if (!background) {
          state = state.copyWith(isLoading: false, error: failure.message);
        }
      },
      (vehicles) {
        final currentSelectedId = state.selectedVehicle?.id;
        final serverSelected = _serverSelected(vehicles);
        final selected =
            serverSelected ??
            (currentSelectedId != null
                ? vehicles.where((v) => v.id == currentSelectedId).firstOrNull
                : null);

        state = state.copyWith(
          vehicles: vehicles,
          selectedVehicle: selected,
          clearSelected: selected == null,
          isLoading: false,
          isInitialized: true,
          isCompanyFleet: false,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadCompanyVehicles() async {
    final seq = ++_loadSeq;
    final owner = _ownerDriverId;
    final switchingFromPersonal = !state.isCompanyFleet;
    state = state.copyWith(
      vehicles: switchingFromPersonal ? const [] : null,
      isLoading: true,
      isInitialized: false,
      isCompanyFleet: true,
      clearError: true,
      isSuccess: false,
    );
    final result = await _repository.getCompanyVehicles();
    // P0 Stage 1 — سياج الردود المتأخرة.
    if (!mounted || seq != _loadSeq || owner != _ownerDriverId) return;
    result.match(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (vehicles) {
        state = state.copyWith(
          vehicles: vehicles,
          isLoading: false,
          isInitialized: true,
          isCompanyFleet: true,
          clearError: true,
        );
      },
    );
  }

  Vehicle? _serverSelected(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.activeForCurrentDriver == true ||
          vehicle.selectedByServer == true) {
        return vehicle;
      }
    }
    return null;
  }

  /// البحث عن مركبة
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// اختيار مركبة — SRS 9.3/9.4: حركة غير معروفة ≠ متوقفة،
  /// والحركة فوق العتبة تمنع الاختيار.
  void selectVehicle(
    Vehicle vehicle, {
    required double? speedMps,
    required double thresholdKmh,
    required bool trackingLive,
  }) {
    if (state.isLoading) return;

    // SRS 9.4: المركبة قيد الحركة فعلياً (تيار موقع حي) — رفض فوري.
    if (trackingLive && speedMps != null && speedMps * 3.6 >= thresholdKmh) {
      state = state.copyWith(error: 'vehicleMoving', isSuccess: false);
      return;
    }

    // SRS 9.3: حارس التبديل يعمل فقط حين يكون تيار الموقع حياً —
    // تتبع مغلق يعني لا دليل قيادة أصلاً؛ الاختيار هو بدء الجلسة الجديدة
    // والتحقق القانوني يتكفل به الخادم عند connectSession.
    final hasActiveSession =
        state.vehicles.any((v) => v.activeForCurrentDriver == true) ||
        (state.selectedVehicle != null &&
            state.selectedVehicle?.id != 'No Vehicle');

    if (hasActiveSession && trackingLive && speedMps == null) {
      state = state.copyWith(error: 'motionUnknown', isSuccess: false);
      return;
    }

    if (readOperableUniqueId(vehicle.uniqueId) == null) {
      state = state.copyWith(error: 'identifierMissing', isSuccess: false);
      return;
    }

    state = state.copyWith(
      isLoading: false,
      // This is only the driver's local choice. The server session is opened
      // after Bluetooth succeeds on the Connection page.
      selectedVehicle: vehicle,
      isSuccess: true,
      clearError: true,
    );
  }
}
