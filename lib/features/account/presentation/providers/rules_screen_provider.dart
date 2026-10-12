import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../application/models/rules_screen_model.dart';
import '../../../../core/utils/provider_cache.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/error/app_error.dart';

/// Provides the current state of the Rules Screen read projection.
final rulesScreenProvider = FutureProvider.autoDispose<RulesScreenModel>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  final user = ref.watch(authStateProvider).user;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  final driverId = int.tryParse(user.id) ?? 0;
  final backend = ref.watch(rulesScreenBackendProvider);
  
  final result = await backend.getRulesScreen(driverId: DriverId(driverId));
  
  return result.fold(
    (failure) {
      if (failure is NetworkError ||
          failure.code == 'network' ||
          failure.l10nKey == 'errNoInternet') {
        return RulesScreenModel(
          ruleSource: 'USA Property 70 hour / 8 day',
          cycleRule: '70 hours / 8 days',
          cargoType: 'Property',
          restart: '34 consecutive hours off-duty',
          restBreak: '30 consecutive minutes after 8 cumulative hours driving',
          sixteenHourException: false,
          options: const {},
          editableFields: const {},
          readOnlyFields: const {},
          fixedSettings: const {'personalConveyance': true, 'yardMoves': true},
          notice: '',
          limits: HosConfiguration.usa70_8(),
        );
      }
      throw Exception(failure.l10nKey);
    },
    (model) => model,
  );
});
