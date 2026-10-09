import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/account/presentation/providers/rules_screen_provider.dart';

/// A pure domain representation of the driver's active rules and permissions.
class DriverRules {
  final bool isPersonalConveyanceAllowed;
  final bool isYardMoveAllowed;

  const DriverRules({
    required this.isPersonalConveyanceAllowed,
    required this.isYardMoveAllowed,
  });
}

/// A core provider exposing the driver's active rules.
/// Must be autoDispose because it watches rulesScreenProvider (which is autoDispose).
final driverRulesProvider = Provider.autoDispose<AsyncValue<DriverRules>>((ref) {
  return ref.watch(rulesScreenProvider).whenData((model) {
    return DriverRules(
      isPersonalConveyanceAllowed: model.isPersonalConveyanceAllowed,
      isYardMoveAllowed: model.isYardMoveAllowed,
    );
  });
});
