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

  /// تقييد الحوار بمركبات السائق — يُستخدم في النموذج اليومي كي لا يُلحق
  /// أي مركبة من أسطول الشركة بالسجل (الافتراضي true للتوافق مع بقية
  /// المستخدمين، ومعه يعود التحويل التلقائي لأسطول الشركة عند قائمة فارغة).
  final bool allowCompanyFleet;

  const VehiclePickerDialog({
    super.key,
    this.currentVehicleId,
    this.allowCompanyFleet = true,
  });

  @override
  ConsumerState<VehiclePickerDialog> createState() => _VehiclePickerDialogState();
}

class _VehiclePickerDialogState extends ConsumerState<VehiclePickerDialog> {
  bool _browsingCompany = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(vehicleProvider.notifier);
      await notifier.loadVehicles(forceRefresh: true);
      if (mounted &&
          widget.allowCompanyFleet &&
          ref.read(vehicleProvider).vehicles.isEmpty) {
        setState(() => _browsingCompany = true);
        await notifier.loadCompanyVehicles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;

    return AlertDialog(
      title: Text(
        _browsingCompany
            ? '${context.loc.selectVehicle} (${context.loc.viewAllVehicles})'
            : context.loc.selectVehicle,
      ),
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
                      style: context.styles.error,
                    ),
                  )
                : vehicles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.loc.noVehiclesFound),
                              if (!_browsingCompany && widget.allowCompanyFleet) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _browsingCompany = true);
                                    ref
                                        .read(vehicleProvider.notifier)
                                        .loadCompanyVehicles();
                                  },
                                  child: Text(context.loc.viewAllVehicles),
                                ),
                              ],
                            ],
                          ),
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
                                      style: context.styles.caption)
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
        if (widget.allowCompanyFleet)
          TextButton(
            onPressed: vehicleState.isLoading
                ? null
                : () {
                    final nextBrowsing = !_browsingCompany;
                    setState(() => _browsingCompany = nextBrowsing);
                    if (nextBrowsing) {
                      ref.read(vehicleProvider.notifier).loadCompanyVehicles();
                    } else {
                      ref
                          .read(vehicleProvider.notifier)
                          .loadVehicles(forceRefresh: true);
                    }
                  },
            child: Text(
              _browsingCompany
                  ? context.loc.viewMyVehicles
                  : context.loc.viewAllVehicles,
            ),
          ),
        if (!vehicleState.isLoading && vehicleState.error != null)
          TextButton(
            onPressed: () => _browsingCompany
                ? ref.read(vehicleProvider.notifier).loadCompanyVehicles()
                : ref.read(vehicleProvider.notifier).loadVehicles(forceRefresh: true),
            child: Text(context.loc.retryButton),
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
