import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';

import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/theme/app_typography.dart';
// import '../../../../core/widgets/app_button.dart';

import '../../../vehicle/presentation/providers/vehicle_provider.dart';

/// Dialog اختيار المركبة
class VehiclePickerDialog extends ConsumerWidget {
  final String? currentVehicleId;

  const VehiclePickerDialog({super.key, this.currentVehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;

    return AlertDialog(
      title: Text(context.loc.selectVehicle),
      content: SizedBox(
        width: double.maxFinite,
        child: vehicles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RadioGroup<String>(
                groupValue: currentVehicleId,
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
                              '${context.loc.vin}: ${vehicle.vin!.substring(vehicle.vin!.length - 8)}',
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
      ],
    );
  }
}
