import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/services/local_storage_service.dart';
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
  final driverId = int.tryParse(user.id) ?? 0;
  final backend = ref.watch(rulesScreenBackendProvider);
  final storage = ref.watch(localStorageProvider);
  final cache = ref.watch(rulesScreenLocalCacheProvider);
  
  final result = await backend.getRulesScreen(driverId: DriverId(driverId));
  
  return await result.fold(
    (failure) async {
      if (failure is NetworkError ||
          failure.l10nKey == 'errNoInternet' ||
          failure.code.startsWith('network')) {
        final cached = cache.loadRulesScreen();
        if (cached != null) {
          return cached;
        }

        final localConfig = storage.hosConfiguration;
        final standardOptions = {
          'cycleRule': [
            '${localConfig.cycleLimitHours} hours / ${localConfig.maxConsecutiveDays} days',
            '60 hours / 7 days',
            '70 hours / 8 days',
          ],
          'cargoType': const ['Property', 'Passenger'],
          'restart': [
            '${localConfig.weeklyRestartHours} consecutive hours off-duty',
            '34 consecutive hours off-duty',
            '24 consecutive hours off-duty',
          ],
          'restBreak': [
            '${localConfig.breakDurationMinutes} consecutive minutes after ${localConfig.driveBeforeBreakMinutes ~/ 60} cumulative hours driving',
            '30 consecutive minutes after 8 cumulative hours driving',
          ],
        };
        const standardEditable = {
          'cycleRule',
          'cargoType',
          'restart',
          'restBreak',
          'sixteenHourException',
        };

        return RulesScreenModel(
          ruleSource: '${localConfig.cycleLimitHours}h / ${localConfig.maxConsecutiveDays}d',
          cycleRule: '${localConfig.cycleLimitHours} hours / ${localConfig.maxConsecutiveDays} days',
          cargoType: 'Property',
          restart: '${localConfig.weeklyRestartHours} consecutive hours off-duty',
          restBreak: '${localConfig.breakDurationMinutes} consecutive minutes after ${localConfig.driveBeforeBreakMinutes ~/ 60} cumulative hours driving',
          sixteenHourException: false,
          options: standardOptions,
          editableFields: standardEditable,
          readOnlyFields: const {},
          fixedSettings: const {'personalConveyance': false, 'yardMoves': false},
          notice: '',
          limits: localConfig,
        );
      }
      throw failure;
    },
    (model) async {
      await cache.saveRulesScreen(model);
      return model;
    },
  );
});
