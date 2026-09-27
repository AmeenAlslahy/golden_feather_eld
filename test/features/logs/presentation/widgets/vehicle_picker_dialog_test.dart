import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/vehicle_picker_dialog.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements VehicleRepository {}

void main() {
  testWidgets('short VIN is shown whole instead of throwing RangeError',
      (tester) async {
    final repo = _Repo();
    when(() => repo.getVehicles()).thenAnswer((_) async => const Right([
          Vehicle(id: 'T-1', name: 'Truck 1', year: '2020', vin: 'ABC12'),
          Vehicle(
              id: 'T-2', name: 'Truck 2', year: '2021', vin: '1FTFW1E58MFA12345'),
        ]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProvider.overrideWith((ref) => VehicleNotifier(repo)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: VehiclePickerDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ABC12'), findsOneWidget);
    expect(find.textContaining('MFA12345'), findsOneWidget);
  });
}
