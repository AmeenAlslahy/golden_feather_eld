import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../backend/contracts/account_backend.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../domain/account/driver_account.dart';

class AccountState {
  final DriverAccount? accountData;
  final bool isLoading;
  final String? error;

  const AccountState({this.accountData, this.isLoading = false, this.error});

  AccountState copyWith({
    DriverAccount? accountData,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AccountState(
      accountData: accountData ?? this.accountData,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  final AccountBackend _backend;
  final Ref _ref;

  /// P0 Stage 1 — مالك الحالة + تسلسل الطلبات لسياج الردود المتأخرة.
  String? _ownerDriverId;
  int? _ownerEpoch;
  int _requestSeq = 0;

  String? get ownerDriverId => _ownerDriverId;

  AccountNotifier(this._backend, this._ref) : super(const AccountState());

  DriverAccount _synthesizeFromAuth(dynamic user) {
    return DriverAccount(
      driverId: int.tryParse(user.id.toString()) ?? 0,
      email: user.email.toString(),
      phone: user.phone?.toString() ?? '',
      license: const LicenseInfo(state: '', number: '', formatted: 'N/A'),
      carrier: '',
      mainOfficeAddress: '',
      homeTerminalAddress: '',
      timeZone: 'UTC',
      language: 'English',
      odometer: 'mi',
    );
  }

  void _saveCachedAccount(String owner, DriverAccount account) {
    try {
      final storage = _ref.read(localStorageProvider);
      storage.prefs.setString(
        'driver_account_cache_$owner',
        jsonEncode(account.toJson()),
      );
    } catch (e) {
      AppLogger.warning('Failed to save account to disk: $e');
    }
  }

  DriverAccount? _loadCachedAccount(String owner) {
    try {
      final storage = _ref.read(localStorageProvider);
      final rawStr = storage.prefs.getString('driver_account_cache_$owner');
      if (rawStr != null && rawStr.isNotEmpty) {
        final json = jsonDecode(rawStr) as Map<String, dynamic>;
        return DriverAccount.fromJson(json);
      }
    } catch (e) {
      AppLogger.warning('Failed to load account from disk: $e');
    }
    return null;
  }

  /// ربط بمالك جديد: إسقاط متزامن (بلا API) وإبطال الطلبات الجارية.
  /// الجلب اللاحق مسؤولية صفحة الحساب عند فتحها (تجنب عاصفة طلبات).
  void bindOwner(String? driverId, int? epoch) {
    if (_ownerDriverId == driverId && _ownerEpoch == epoch) return;
    _requestSeq++;
    _ownerDriverId = driverId;
    _ownerEpoch = epoch;
    state = const AccountState();
  }

  /// إسقاط فوري (عند بدء logout) — متزامن، بلا API.
  void reset() => bindOwner(null, null);

  bool _isCurrent(int seq, String? owner, int? epoch) {
    return mounted &&
        seq == _requestSeq &&
        owner == _ownerDriverId &&
        epoch == _ownerEpoch;
  }

  Future<void> fetchMyAccount() async {
    final authState = _ref.read(authStateProvider);
    // بلا هوية مثبتة أو أثناء انتقال: لا طلب، ولا عرض قديم.
    if (authState.user == null || authState.transitioning) return;
    final owner = authState.user!.id;
    final epoch = authState.sessionEpoch;
    // توحيد المالك قبل الطلب حتى لا يُنسب رد B لمالك قديم.
    bindOwner(owner, epoch);
    // P0 corrections: تسلسل جديد لكل طلب فعلي (latest-wins للقراءة).
    final seq = ++_requestSeq;

    final isOnline = _ref.read(networkInfoProvider).isConnected;
    if (!isOnline) {
      final cached = _loadCachedAccount(owner);
      final account = cached ?? _synthesizeFromAuth(authState.user!);
      state = state.copyWith(
        isLoading: false,
        accountData: account,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final userIdStr = authState.user?.id;

    DriverId? driverId;
    if (userIdStr != null && int.tryParse(userIdStr) != null) {
      driverId = DriverId(int.parse(userIdStr));
    }

    try {
      final result = await _backend.getMyAccount(driverId: driverId);

      // P0 Stage 1 — سياج: تجاهل الرد المتأخر دون تحويله لخطأ في جلسة جديدة.
      if (!_isCurrent(seq, owner, epoch)) return;
      result.fold(
        (failure) {
          final cached = _loadCachedAccount(owner);
          if (cached != null) {
            state = state.copyWith(
              isLoading: false,
              accountData: cached,
              clearError: true,
            );
          } else if (failure.code.startsWith('network') ||
              failure.code.contains('timeout') ||
              failure.code.contains('offline')) {
            final fallback = _synthesizeFromAuth(authState.user!);
            state = state.copyWith(
              isLoading: false,
              accountData: fallback,
              clearError: true,
            );
          } else {
            state = state.copyWith(isLoading: false, error: failure.l10nKey);
          }
        },
        (driverAccount) {
          _saveCachedAccount(owner, driverAccount);
          state = state.copyWith(
            isLoading: false,
            accountData: driverAccount,
            clearError: true,
          );
        },
      );
    } catch (_) {
      if (!_isCurrent(seq, owner, epoch)) return;
      final cached = _loadCachedAccount(owner);
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          accountData: cached,
          clearError: true,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'unexpected');
      }
    }
  }

  Future<bool> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async {
    // P0 corrections: تسلسل جديد لكل عملية — إكمال الأحدث فقط يُطبق.
    final seq = ++_requestSeq;
    final owner = _ownerDriverId;
    final epoch = _ownerEpoch;

    // الخادم هو المرجع: لا "نجاح" محلي بلا وصول الطلب — الرفض صريح
    // حتى لا يُفقد التغيير صامتاً عند الجلب التالي.
    final isOnline = _ref.read(networkInfoProvider).isConnected;
    if (!isOnline) {
      state = state.copyWith(isLoading: false, error: 'noInternet');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _backend.updatePreferences(
        language: language,
        odometerUnit: odometerUnit,
      );

      // P0 Stage 1 — سياج الردود المتأخرة.
      if (!_isCurrent(seq, owner, epoch)) return false;
      return await result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.l10nKey);
          return false;
        },
        (driverAccount) {
          if (owner != null) _saveCachedAccount(owner, driverAccount);
          // تحديث البيانات المرجعة في الشاشة
          state = state.copyWith(
            isLoading: false,
            accountData: driverAccount,
            clearError: true,
          );
          return true;
        },
      );
    } catch (_) {
      if (!_isCurrent(seq, owner, epoch)) return false;
      state = state.copyWith(isLoading: false, error: 'unexpected');
      return false;
    }
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((
  ref,
) {
  final notifier = AccountNotifier(ref.watch(accountBackendProvider), ref);

  // P0 Stage 1: أي غياب هوية أو انتقال أو تغير مالك يُسقط الحالة فوراً
  // (متزامن، بلا API). الجلب لمالك جديد يتم عند فتح صفحة الحساب.
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.user == null || next.transitioning) {
      notifier.reset();
      return;
    }
    notifier.bindOwner(next.user!.id, next.sessionEpoch);
  }, fireImmediately: true);

  return notifier;
});
