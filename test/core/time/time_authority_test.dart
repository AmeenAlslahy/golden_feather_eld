import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/time/fake_time_authority.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';

void main() {
  group('TrustLevel enum', () {
    test('has 4 values', () {
      expect(TrustLevel.values, hasLength(4));
    });

    test('ordering is from least to most trusted', () {
      expect(
        TrustLevel.values,
        [
          TrustLevel.untrusted,
          TrustLevel.localDevice,
          TrustLevel.serverSynced,
          TrustLevel.ntpSynced,
        ],
      );
    });
  });

  group('TimeAuthority contract', () {
    test('FakeTimeAuthority implements TimeAuthority', () {
      expect(FakeTimeAuthority(), isA<TimeAuthority>());
    });
  });
}
