import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/account/driver_rules.dart';
import 'rules_screen_provider.dart';

/// Exposes the driver's active rules, derived from the rules screen projection.
/// Must be autoDispose because it watches rulesScreenProvider (which is autoDispose).
final driverRulesProvider = Provider.autoDispose<AsyncValue<DriverRules>>((
  ref,
) {
  return ref.watch(rulesScreenProvider).whenData((model) {
    return DriverRules(
      isPersonalConveyanceAllowed: model.isPersonalConveyanceAllowed,
      isYardMoveAllowed: model.isYardMoveAllowed,
    );
  });
});
