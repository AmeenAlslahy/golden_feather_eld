import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/event_screen_options.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/event_options_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/status_radio_group.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

class _MockLogRepository extends Fake implements LogRepository {
  EventScreenOptions? optionsToReturn;
  Failure? failureToReturn;

  @override
  Future<Either<Failure, EventScreenOptions>> getEventScreenOptions(
    DailyLogId logId,
  ) async {
    if (failureToReturn != null) {
      return Left(failureToReturn!);
    }
    return Right(optionsToReturn ?? EventScreenOptions.standardFallback);
  }
}

void main() {
  group('eventScreenOptionsProvider', () {
    test('returns options when repository succeeds', () async {
      final mockRepo = _MockLogRepository();
      const expected = EventScreenOptions(
        statuses: [
          EventOptionStatus(code: 'OFF_DUTY'),
          EventOptionStatus(code: 'DRIVING'),
        ],
        vehicles: [
          EventOptionVehicle(id: 101, identifier: 'Truck 101'),
        ],
        locationSources: ['ELD_AUTO'],
      );
      mockRepo.optionsToReturn = expected;

      final container = ProviderContainer(
        overrides: [
          logRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        eventScreenOptionsProvider(const DailyLogId(42)).future,
      );

      expect(result, expected);
      expect(result.statuses.length, 2);
    });

    test('falls back to standardFallback when repository fails', () async {
      final mockRepo = _MockLogRepository();
      mockRepo.failureToReturn = const ServerFailure(message: 'Server error');

      final container = ProviderContainer(
        overrides: [
          logRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        eventScreenOptionsProvider(const DailyLogId(42)).future,
      );

      expect(result, EventScreenOptions.standardFallback);
      expect(result.statuses.length, 6);
    });
  });

  group('StatusRadioGroup with allowedStatuses', () {
    Widget buildTestWidget({
      required String groupValue,
      required ValueChanged<String> onChanged,
      List<EventOptionStatus>? allowedStatuses,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatusRadioGroup(
            groupValue: groupValue,
            onChanged: onChanged,
            allowedStatuses: allowedStatuses,
          ),
        ),
      );
    }

    testWidgets('renders only filtered statuses when allowedStatuses is provided', (
      tester,
    ) async {
      String selected = 'OFF';
      await tester.pumpWidget(
        buildTestWidget(
          groupValue: selected,
          onChanged: (val) => selected = val,
          allowedStatuses: const [
            EventOptionStatus(code: 'OFF_DUTY'),
            EventOptionStatus(code: 'ON_DUTY'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Only OFF and ON should be rendered (+ dividers)
      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
    });

    testWidgets('renders all 6 statuses when allowedStatuses is null (default fallback)', (
      tester,
    ) async {
      String selected = 'OFF';
      await tester.pumpWidget(
        buildTestWidget(
          groupValue: selected,
          onChanged: (val) => selected = val,
          allowedStatuses: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<String>), findsNWidgets(6));
    });
  });
}
