import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/rules_screen_model.dart';

/// Provides the current state of the Rules Screen read projection.
final rulesScreenProvider = FutureProvider.autoDispose<RulesScreenModel>((ref) async {
  final user = ref.watch(authStateProvider).user;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  final driverId = int.tryParse(user.id) ?? 0;
  final backend = ref.watch(rulesScreenBackendProvider);
  
  final result = await backend.getRulesScreen(driverId: DriverId(driverId));
  
  return result.fold(
    (failure) => throw Exception(failure.l10nKey),
    (model) => model,
  );
});
