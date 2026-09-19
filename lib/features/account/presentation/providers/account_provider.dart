import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:golden_feather_eld/core/domain/entities/user.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/network/network_providers.dart'; // Keep for networkInfoProvider until completely removed

import '../../../../core/di/app_providers.dart';

class AccountState {
  final User? userProfile;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.userProfile,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    User? userProfile,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  final AccountRepository _repository;
  final Ref _ref;

  AccountNotifier(this._repository, this._ref) : super(const AccountState());

  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authStateProvider);
    final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;

    if (userId == 0) {
      state = state.copyWith(isLoading: false, error: 'User ID not found');
      return;
    }

    final result = await _repository.getUserProfile(userId);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (user) => state =
          state.copyWith(isLoading: false, userProfile: user, error: null),
    );
  }

  Future<bool> updateUserProfile(User updatedUser) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateUserProfile(updatedUser);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state =
            state.copyWith(isLoading: false, userProfile: user, error: null);
        return true;
      },
    );
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(
    ref.watch(accountRepositoryProvider),
    ref,
  );
});
