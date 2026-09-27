import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/theme/app_typography.dart';
// import '../../../../core/widgets/app_button.dart';

import '../../../vehicle/presentation/providers/vehicle_provider.dart';

class VehiclePickerDialog extends ConsumerStatefulWidget {
  final String? currentVehicleId;

  const VehiclePickerDialog({super.key, this.currentVehicleId});

  @override
  ConsumerState<VehiclePickerDialog> createState() => _VehiclePickerDialogState();
}

class _VehiclePickerDialogState extends ConsumerState<VehiclePickerDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleProvider.notifier).loadVehicles(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;

    return AlertDialog(
      title: Text(context.loc.selectVehicle),
      content: SizedBox(
        width: double.maxFinite,
        child: vehicleState.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : vehicleState.error != null
                ? Center(
                    child: Text(
                      vehicleState.error!,
                      style: const TextStyle(color: AppColors.dangerRed),
                    ),
                  )
                : vehicles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(context.loc.noVehiclesFound),
                        ),
                      )
                    : RadioGroup<String>(
                        groupValue: widget.currentVehicleId,
                        onChanged: (value) {
                          if (value == null) return;
                          final picked = vehicles.where((v) => v.id == value);
                          if (picked.isNotEmpty) Navigator.pop(context, picked.first);
                        },
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];

                            return RadioListTile<String>(
                              title: Text(vehicle.displayName),
                              subtitle: vehicle.vin != null
                                  ? Text(
                                      '${context.loc.vin}: ${_vinTail(vehicle.vin!)}',
                                      style: const TextStyle(fontSize: 12))
                                  : null,
                              value: vehicle.id,
                              activeColor: AppColors.primaryGold,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
      ),
      actions: [
        if (!vehicleState.isLoading && vehicleState.error != null)
          TextButton(
            onPressed: () => ref.read(vehicleProvider.notifier).loadVehicles(forceRefresh: true),
            child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إعادة المحاولة' : 'Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
      ],
    );
  }
}

/// Last 8 VIN characters; short/odd VINs are shown whole instead of throwing.
String _vinTail(String vin) {
  final v = vin.trim();
  return v.length > 8 ? v.substring(v.length - 8) : v;
}
