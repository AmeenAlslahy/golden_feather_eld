import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/battery_optimization_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/tracking_repository.dart';
import 'tracking_providers.dart';

/// حالة التتبع
enum TrackingStatus { initial, active, stopped, loading, error }

enum TrackingErrorType { permission, technical }

/// حالة شاشة التتبع
class TrackingState {
  final TrackingStatus status;
  final LocationEntity? currentLocation;
  final List<TrackingLogEntity> logs;
  final String? errorMessage;
  final String? arabicErrorMessage;
  final TrackingErrorType? errorType;
  final bool isTracking;
  final bool showBatteryDialog; // 🆕

  const TrackingState({
    this.status = TrackingStatus.initial,
    this.currentLocation,
    this.logs = const [],
    this.errorMessage,
    this.arabicErrorMessage,
    this.errorType,
    this.isTracking = false,
    this.showBatteryDialog = false, // 🆕
  });

  TrackingState copyWith({
    TrackingStatus? status,
    LocationEntity? currentLocation,
    List<TrackingLogEntity>? logs,
    String? errorMessage,
    TrackingErrorType? errorType,
    bool? isTracking,
    bool? showBatteryDialog,
  }) {
    return TrackingState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      logs: logs ?? this.logs,
      errorMessage: errorMessage,
      errorType: errorType,
      isTracking: isTracking ?? this.isTracking,
      showBatteryDialog: showBatteryDialog ?? this.showBatteryDialog,
    );
  }
}

/// مزود مستقل للسرعة الحالية لكسر الاعتمادية الدائرية (Circular Dependency)
final currentVehicleSpeedProvider = StateProvider<double?>((ref) => null);

/// مزود حالة التتبع
final trackingStateProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final repository = ref.watch(trackingRepositoryProvider);
  final notifier = TrackingNotifier(repository, ref);

  return notifier;
});

class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingRepository _repository;
  final Ref ref;
  bool Function()? isDrivingChecker;
  StreamSubscription<LocationEntity>? _locationSubscription;
  Timer? _gpsTimeoutTimer;

  TrackingNotifier(this._repository, this.ref) : super(const TrackingState());

  /// Helper getters to safely access state from the provider definition
  TrackingStatus get currentStatus => state.status;
  bool get isActiveOrLoading =>
      state.status == TrackingStatus.active ||
      state.status == TrackingStatus.loading;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _gpsTimeoutTimer?.cancel();
    super.dispose();
  }

  /// بدء التتبع
  Future<void> startTracking({bool skipBatteryCheck = false}) async {
    state = state.copyWith(status: TrackingStatus.loading);

    // ✅ فحص تحسين البطارية
    if (!skipBatteryCheck) {
      final batteryService = ref.read(batteryOptimizationServiceProvider);
      final isBatteryOptimized =
          await batteryService.isBatteryOptimizationEnabled();

      if (isBatteryOptimized) {
        // نحتاج context لإظهار الحوار - نمرر إشارة للـ UI
        state = state.copyWith(
          status: TrackingStatus.initial,
          showBatteryDialog: true,
        );
        return; // نوقف التتبع مؤقتاً حتى يستجيب المستخدم للحوار
      }
    }

    // بدء الاستماع لتدفق المواقع قبل بدء الخدمة لتجنب فقدان أول موقع (Race Condition)
    _listenToLocationStream();

    final result = await _repository.startTracking();

    result.match(
      (failure) {
        // إيقاف الاستماع في حال الفشل
        _locationSubscription?.cancel();
        _gpsTimeoutTimer?.cancel();

        if (failure is PermissionFailure) {
          state = state.copyWith(
            status: TrackingStatus.error,
            errorMessage: failure.message,
            errorType: TrackingErrorType.permission,
          );
        } else {
          state = state.copyWith(
            status: TrackingStatus.error,
            errorMessage: failure.message,
            errorType: TrackingErrorType.technical,
          );
        }
      },
      (_) {
        AppLogger.info(
            'Tracking service started. Waiting for first location...');
      },
    );
  }

  void _listenToLocationStream() {
    _locationSubscription?.cancel();
    _gpsTimeoutTimer?.cancel();

    // إظهار خطأ واضح في حال تأخر النيتف عن إرسال إحداثيات (البقاء في حالة الانتظار)
    _gpsTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!state.isTracking) {
        state = state.copyWith(
          errorMessage: 'No GPS signal received from device',
          errorType: TrackingErrorType.technical,
        );
      }
    });

    _locationSubscription = _repository.locationStream.listen(
      (location) {
        _gpsTimeoutTimer?.cancel();
        if (!state.isTracking) {
          AppLogger.info('First location received, tracking is now active');
        }

        state = state.copyWith(
          status: TrackingStatus.active,
          isTracking: true,
          currentLocation: location,
          errorMessage: null,
          errorType: null,
        );
        ref.read(currentVehicleSpeedProvider.notifier).state = location.speed;
      },
      onError: (error) {
        AppLogger.error('Location stream error: $error');
        state = state.copyWith(
          status: TrackingStatus.error,
          errorMessage: 'Stream error',
          errorType: TrackingErrorType.technical,
          isTracking: false,
        );
      },
    );
  }

  /// إيقاف التتبع
  Future<void> stopTracking({bool force = false}) async {
    if (!force) {
      final isDriving = isDrivingChecker?.call() ?? false;
      if (isDriving) {
        state = state.copyWith(
          errorMessage: 'Cannot stop tracking while driving',
          errorType: TrackingErrorType.technical,
        );
        return;
      }
    }

    state = state.copyWith(status: TrackingStatus.loading);
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _gpsTimeoutTimer?.cancel();

    final result = await _repository.stopTracking();

    result.match(
      (failure) {
        state = state.copyWith(
          status: TrackingStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          status: TrackingStatus.stopped,
          isTracking: false,
          errorMessage: null,
        );
        AppLogger.info('Tracking stopped successfully');
      },
    );
  }

  /// طلب الموقع الحالي
  Future<void> requestPosition({String? alarm}) async {
    final result = await _repository.requestPosition(alarm: alarm);

    result.match(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
        );
      },
      (location) {
        state = state.copyWith(
          currentLocation: location,
          errorMessage: null,
        );
      },
    );
  }

  /// تحميل السجلات
  Future<void> loadLogs() async {
    final result = await _repository.getLogs();

    result.match(
      (_) {},
      (logs) {
        state = state.copyWith(logs: logs);
      },
    );
  }

  /// مسح السجلات
  Future<void> clearLogs() async {
    await _repository.clearLogs();
    state = state.copyWith(logs: []);
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      errorType: null,
    );
  }

  void clearBatteryDialog() {
    state = state.copyWith(showBatteryDialog: false);
  }
}
