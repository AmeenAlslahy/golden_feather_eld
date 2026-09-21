import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags — default', () {
    test('useNewStatusDashboard is true by default', () {
      const flags = FeatureFlags();
      expect(flags.useNewStatusDashboard, isTrue);
    });

    test('default fromEnvironment defaults to true in test environment', () {
      final flags = FeatureFlags.fromEnvironment();
      expect(flags.useNewStatusDashboard, true);
    });

    test('fromEnvironment defaults to true in test environment', () {
      // Tests run without --dart-define=USE_NEW_STATUS_DASHBOARD.
      final flags = FeatureFlags.fromEnvironment();
      expect(flags.useNewStatusDashboard, isTrue);
    });
  });

  group('FeatureFlags — explicit values', () {
    test('can be constructed with useNewStatusDashboard=true', () {
      const flags = FeatureFlags(useNewStatusDashboard: true);
      expect(flags.useNewStatusDashboard, isTrue);
    });

    test('can be constructed with useNewStatusDashboard=false', () {
      const flags = FeatureFlags(useNewStatusDashboard: false);
      expect(flags.useNewStatusDashboard, isFalse);
    });
  });
}
