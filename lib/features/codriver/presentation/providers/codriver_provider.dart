import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/providers/codriver_repository_providers.dart';
import '../../domain/current_codriver.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';

// --- State and Notifier ---

/// حالة شاشة السائق المساعد
class CoDriverState {
  final List<CoDriver> availableDrivers;
  final CoDriver? selectedCoDriver;
  final CurrentCoDriverRead? currentCoDriver;
  final String? currentError;
  final bool isLoading;
  final bool isSwitching;
  final String? error;

  const CoDriverState({
    this.availableDrivers = const [],
    this.selectedCoDriver,
    this.currentCoDriver,
    this.currentError,
    this.isLoading = false,
    this.isSwitching = false,
    this.error,
  });

  CoDriverState copyWith({
    List<CoDriver>? availableDrivers,
    CoDriver? selectedCoDriver,
    CurrentCoDriverRead? currentCoDriver,
    bool clearCurrent = false,
    String? currentError,
    bool clearCurrentError = false,
    bool? isLoading,
    bool? isSwitching,
    String? error,
  }) {
    return CoDriverState(
      availableDrivers: availableDrivers ?? this.availableDrivers,
      selectedCoDriver: selectedCoDriver ?? this.selectedCoDriver,
      currentCoDriver: clearCurrent
          ? currentCoDriver
          : (currentCoDriver ?? this.currentCoDriver),
      currentError: clearCurrentError
          ? currentError
          : (currentError ?? this.currentError),
      isLoading: isLoading ?? this.isLoading,
      isSwitching: isSwitching ?? this.isSwitching,
      error: error,
    );
  }
}

/// مزود السائق المساعد
///
/// P0 leak fix — ملكية الجلسة (نمط vehicle H-D1): المصنع يستمع لتغيرات
/// المصادقة (بلا اعتمادات جديدة)، وأي غياب هوية/انتقال/تغير مالك يُسقط
/// الحالة متزامناً ثم يُعاد الجلب للمالك وحده. الربط الأولي لمرة واحدة
/// يغطي الإنشاء بعد login مكتمل؛ بلا مصادقة: صمت تام بلا أي طلب
/// (يمنع GET الإقلاع البارد).
final codriverProvider = StateNotifierProvider<CoDriverNotifier, CoDriverState>(
  (ref) {
    final notifier = CoDriverNotifier(
      repository: ref.watch(coDriverRepositoryProvider),
    );
    ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (next.user == null || next.transitioning) {
          notifier.reset();
          return;
        }
        final id = int.tryParse(next.user!.id);
        if (id != notifier.ownerDriverId ||
            next.sessionEpoch != notifier.ownerEpoch) {
          notifier.bindOwner(id, next.sessionEpoch);
          notifier.reload();
        }
      },
    );
    final auth = ref.read(authStateProvider);
    if (auth.user != null && !auth.transitioning) {
      notifier.bindOwner(
          int.tryParse(auth.user!.id), auth.sessionEpoch);
      notifier.reload();
    }
    return notifier;
  },
);

class CoDriverNotifier extends StateNotifier<CoDriverState> {
  final CoDriverRepository _repository;

  /// P0 leak fix — مالك الحالة (يُستبعد من قائمة المساعدين دائماً: لا
  /// يربط السائق نفسه كمساعد ولا يبدّل الأدوار مع نفسه) + تسلسل الطلبات.
  int? _ownerDriverId;
  int? _ownerEpoch;
  int _reqSeq = 0;

  int? get ownerDriverId => _ownerDriverId;
  int? get ownerEpoch => _ownerEpoch;

  CoDriverNotifier({required CoDriverRepository repository, int driverId = 0})
    : _repository = repository,
      _ownerDriverId = driverId == 0 ? null : driverId,
      super(const CoDriverState());

  /// ربط بمالك جديد: إسقاط متزامن (بلا API) وإبطال الطلبات الجارية.
  void bindOwner(int? driverId, int? epoch) {
    if (_ownerDriverId == driverId && _ownerEpoch == epoch) return;
    _reqSeq++;
    _ownerDriverId = driverId;
    _ownerEpoch = epoch;
    state = const CoDriverState();
  }

  /// إسقاط فوري (عند بدء logout) — متزامن، بلا API.
  void reset() => bindOwner(null, null);

  bool _isCurrent(int seq, int? owner, int? epoch) {
    return mounted &&
        seq == _reqSeq &&
        owner == _ownerDriverId &&
        epoch == _ownerEpoch;
  }

  /// Pull-to-refresh / retry: re-reads the driver list and the current link.
  Future<void> reload() => _loadDrivers();

  Future<void> _loadDrivers({bool background = false}) async {
    // P0 leak fix: تسلسل جديد لكل طلب فعلي (latest-wins)؛ بلا مالك صمت تام.
    final seq = ++_reqSeq;
    final owner = _ownerDriverId;
    final epoch = _ownerEpoch;
    if (owner == null || owner <= 0) return;
    if (!background) {
      state = state.copyWith(isLoading: true, error: null);
    }
    final driversResult = await _repository.getAvailableDrivers();
    // P0 leak fix: إعادة التحقق بعد كل await وقبل أي طلب محمي متسلسل —
    // logout بين الطلبين يمنع الثاني (حالة 55.313) دون تحويله لخطأ.
    if (!_isCurrent(seq, owner, epoch)) return;
    final currentResult = await _repository.getCurrentCoDriver();
    if (!_isCurrent(seq, owner, epoch)) return;

    var next = state.copyWith(isLoading: false, error: null);
    driversResult.fold(
      (failure) {
        if (!background) next = next.copyWith(error: failure.message);
      },
      (drivers) => next = next.copyWith(
        // استبعاد السائق نفسه من قائمة المساعدين (الرد قد يتضمنه).
        availableDrivers: drivers
            .where((d) => int.tryParse(d.id) != _ownerDriverId)
            .toList(),
        error: null,
      ),
    );
    currentResult.fold(
      (failure) {
        if (!background) {
          next = next.copyWith(
            error: next.error,
            currentError: failure.message,
            clearCurrent: true,
            clearCurrentError: true,
          );
        }
      },
      (current) => next = next.copyWith(
        error: next.error,
        currentCoDriver: current,
        clearCurrentError: true,
      ),
    );
    state = next;
  }

  Future<void> _refreshCurrent() async {
    final currentResult = await _repository.getCurrentCoDriver();
    if (!mounted) return;
    currentResult.fold(
      (failure) => state = state.copyWith(
        error: state.error,
        currentError: failure.message,
        clearCurrent: true,
        clearCurrentError: true,
      ),
      (current) => state = state.copyWith(
        error: state.error,
        currentCoDriver: current,
        clearCurrentError: true,
      ),
    );
  }

  /// اختيار سائق مساعد
  void selectCoDriver(CoDriver driver) {
    state = state.copyWith(
      selectedCoDriver: driver.id == 'none' ? null : driver,
    );
  }

  /// تبديل الأدوار
  Future<String?> switchDrivers({String? reason}) async {
    final id = int.tryParse(state.selectedCoDriver?.id ?? '');
    if (id == null || id <= 0) {
      const message = 'Select a co-driver before switching.';
      state = state.copyWith(isSwitching: false, error: message);
      return message;
    }
    state = state.copyWith(isSwitching: true, error: null);
    final result = await _repository.switchPrimary(
      coDriverId: id,
      reason: reason,
    );
    if (!mounted) return 'Switch was interrupted.';
    final message = result.fold(
      (failure) {
        state = state.copyWith(isSwitching: false, error: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(isSwitching: false, error: null);
        return null;
      },
    );
    if (message == null) await _refreshCurrent();
    return message;
  }
}
