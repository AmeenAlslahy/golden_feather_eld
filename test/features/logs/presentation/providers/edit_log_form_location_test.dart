// test/features/logs/presentation/providers/edit_log_form_location_test.dart
//
// Location Isolation Tests — Step 3c
// Proves that editing status/reason/startTime does NOT overwrite the
// original server-provided event location, and that the manualLocation
// override / fallback logic is correct.
//
// Classification: DRIVER_VIEW tests (read-only state machine, no network)

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_form_provider.dart';

void main() {
  group('EditLogFormState — Location Isolation (Step 3c)', () {
    late EditLogFormState base;

    setUp(() {
      base = EditLogFormState(
        selectedStatus: 'ON',
        startTime: '08:00:00 AM',
        duration: '01:00',
        originalLocation: 'Server Location Dallas TX',
        manualLocation: '',
        reason: '',
      );
    });

    // Test 1
    test('changing selectedStatus does NOT clear originalLocation', () {
      final updated = base.copyWith(selectedStatus: 'OFF');
      expect(
        updated.originalLocation,
        'Server Location Dallas TX',
        reason: 'status change must not wipe the server-provided location',
      );
      // location getter falls back to original when no manual override
      expect(updated.location, 'Server Location Dallas TX');
    });

    // Test 2
    test(
        'clearing manualLocation reverts location getter to originalLocation '
        '(not empty string)', () {
      final withManual = base.copyWith(manualLocation: 'Manual Override');
      expect(withManual.location, 'Manual Override');

      // User clears the field
      final cleared = withManual.copyWith(manualLocation: '');
      expect(
        cleared.location,
        'Server Location Dallas TX',
        reason: 'clearing manual input must revert to original, not send empty',
      );
      expect(cleared.manualLocation, '');
      expect(cleared.originalLocation, 'Server Location Dallas TX');
    });

    // Test 3
    test('manual location overrides original in location getter', () {
      final withManual = base.copyWith(manualLocation: 'New Manual City');
      expect(
        withManual.location,
        'New Manual City',
        reason: 'non-empty manualLocation must take priority over original',
      );
    });

    // Test 4
    test('whitespace-only manualLocation falls back to originalLocation', () {
      final withWhitespace = base.copyWith(manualLocation: '   ');
      expect(
        withWhitespace.location,
        'Server Location Dallas TX',
        reason: 'whitespace-only manual input counts as empty => fall back',
      );
    });

    // Test 5 — offline queue scenario
    test(
        'offline payload: when no manual override, '
        'location getter returns originalLocation', () {
      // Represents the value written into PendingEvent.payload['locationText']
      final offlineState = base; // manualLocation = ''
      expect(
        offlineState.location,
        'Server Location Dallas TX',
        reason:
            'offline queued payload must carry original location, not empty string',
      );
    });

    // Test 6
    test('originalLocation is preserved when only reason changes', () {
      final copy = base.copyWith(reason: 'Corrected duty status');
      expect(copy.originalLocation, 'Server Location Dallas TX');
      expect(copy.reason, 'Corrected duty status');
      expect(copy.location, 'Server Location Dallas TX');
    });

    // Test 7 — startTime change must not affect location
    test('changing startTime does NOT affect originalLocation or location', () {
      final copy = base.copyWith(startTime: '09:00:00 AM', duration: '03:00');
      expect(copy.originalLocation, 'Server Location Dallas TX');
      expect(copy.location, 'Server Location Dallas TX');
      expect(copy.startTime, '09:00:00 AM');
    });

    // Test 8 — both manual and original empty => empty string (edge case)
    test('when both originalLocation and manualLocation are empty, '
        'location getter returns empty string', () {
      final empty = EditLogFormState(
        selectedStatus: 'OFF',
        startTime: '08:00:00 AM',
        duration: '01:00',
        originalLocation: '',
        manualLocation: '',
        reason: '',
      );
      expect(empty.location, '');
    });
  });
}
