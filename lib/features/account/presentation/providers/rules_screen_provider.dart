import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../application/models/rules_screen_model.dart';
import '../../data/providers/rules_screen_providers.dart';

/// Provides the current state of the Rules Screen read projection.
final rulesScreenProvider = FutureProvider.autoDispose<RulesScreenModel>((
  ref,
) async {
  cacheFor(ref, const Duration(minutes: 5));
  final user = ref.watch(authStateProvider.select((s) => s.user));
  if (user == null) {
    throw const SessionExpiredError();
  }
  final repository = ref.watch(rulesScreenRepositoryProvider);

  // الخادم يستخرج هوية السائق تلقائياً من توكن المصادقة (Bearer token) على المسار /eld/driver-rules
  final result = await repository.getRulesScreen();

  return result.fold((failure) => throw failure, (model) => model);
});
