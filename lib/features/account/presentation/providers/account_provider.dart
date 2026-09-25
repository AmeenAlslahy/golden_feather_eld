import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/account_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

class AccountState {
  final DriverAccount? accountData;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.accountData,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    DriverAccount? accountData,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accountData: accountData ?? this.accountData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  final AccountBackend _backend;
  final Ref _ref;

  AccountNotifier(this._backend, this._ref) : super(const AccountState());

  Future<void> fetchMyAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authStateProvider);
    final userIdStr = authState.user?.id;
    
    DriverId? driverId;
    if (userIdStr != null && int.tryParse(userIdStr) != null) {
      driverId = DriverId(int.parse(userIdStr));
    }

    try {
      final result = await _backend.getMyAccount(driverId: driverId);
      
      result.fold(
        (failure) => state = state.copyWith(isLoading: false, error: failure.l10nKey),
        (driverAccount) => state = state.copyWith(isLoading: false, accountData: driverAccount, error: null),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _backend.updatePreferences(
        language: language,
        odometerUnit: odometerUnit,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.l10nKey);
          return false;
        },
        (driverAccount) {
          // تحديث البيانات المرجعة في الشاشة
          state = state.copyWith(isLoading: false, accountData: driverAccount, error: null);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(
    ref.watch(accountBackendProvider),
    ref,
  );
});
