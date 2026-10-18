/// A pure domain representation of the driver's active rules and permissions.
class DriverRules {
  final bool isPersonalConveyanceAllowed;
  final bool isYardMoveAllowed;

  const DriverRules({
    required this.isPersonalConveyanceAllowed,
    required this.isYardMoveAllowed,
  });
}
