import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../application/models/rules_screen_model.dart';
import '../../data/providers/rules_screen_providers.dart';

/// Provides the current state of the Rules Screen read projection.
final rulesScreenProvider = FutureProvider.autoDispose<RulesScreenModel>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  final user = ref.watch(authStateProvider).user;
  if (user == null) {
    throw const SessionExpiredError();
  }
  final parsedId = int.tryParse(user.id);
  final repository = ref.watch(rulesScreenRepositoryProvider);

  final result = await repository.getRulesScreen(
    driverId: parsedId == null ? null : DriverId(parsedId),
  );

  return result.fold((failure) => throw failure, (model) => model);
});
