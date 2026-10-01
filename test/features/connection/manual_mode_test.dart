import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_hardware_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/features/connection/presentation/pages/eld_connection_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      hardwareBackendProvider.overrideWithValue(MockHardwareBackend()),
    ]);
  });

  tearDown(() => container.dispose());

  test('manual recording needs a reason (§395.34 request requires it)', () async {
    final notifier = container.read(eldConnectionProvider.notifier);
    final message = await notifier.setManualMode(
      enable: true,
      reason: '   ',
      loc: lookupAppLocalizations(const Locale('en')),
    );
    expect(message, isNotNull);
    expect(message, contains('reason'));
  });

  test('manual recording start is accepted with a reason', () async {
    final notifier = container.read(eldConnectionProvider.notifier);
    final message = await notifier.setManualMode(
      enable: true,
      reason: 'lost connection to the ELD',
      loc: lookupAppLocalizations(const Locale('en')),
    );
    expect(message, isNull);
  });
}
