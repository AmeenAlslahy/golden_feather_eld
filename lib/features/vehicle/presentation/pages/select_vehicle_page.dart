import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';
import '../providers/vehicle_provider.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/services/local_storage_service.dart';
import '../widget/vehicle_card.dart';

/// شاشة اختيار المركبة
class SelectVehiclePage extends ConsumerStatefulWidget {
  const SelectVehiclePage({super.key});

  @override
  ConsumerState<SelectVehiclePage> createState() => _SelectVehiclePageState();
}

class _SelectVehiclePageState extends ConsumerState<SelectVehiclePage> {
  final _searchController = TextEditingController();
  bool _askedUnassigned = false;
  bool _browsingCompany = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleVehicleSelected(Vehicle vehicle) async {
    if (!listedVehicleIsOperable(
      browsingCompanyFleet: _browsingCompany,
      vehicle: vehicle,
    )) {
      AppFeedback.error(
        context,
        vehicleErrorText(
          vehicle.inUseByOther == true ? 'in_use' : 'unauthorized',
          context.loc,
        ),
      );
      return;
    }
    await ref
        .read(vehicleProvider.notifier)
        .selectVehicle(
          vehicle,
          speedMps: ref.read(currentVehicleSpeedProvider),
          thresholdKmh: ref
              .read(hosConfigurationProvider)
              .movingSpeedThresholdKmh,
          // الحارس يعمل فقط حين يكون تيار الموقع حياً — تتبع مغلق =
          // لا دليل حركة، والاختيار بدء طبيعي لجلسة جديدة (SRS 9.3).
          trackingLive: ref.read(trackingStateProvider).isTracking,
        );
    // هوية موحّدة: نجاح الاختيار يكتب لوحة القيادة فوراً (uniqueId +
    // deviceId الرقمي) حتى لا يبقى نموذج الفحص وربط السائق على قيم افتراضية.
    final state = ref.read(vehicleProvider);
    if (state.isSuccess && state.selectedVehicle != null) {
      final v = state.selectedVehicle!;
      ref.read(dashboardDataProvider.notifier).updateVehicle(v);
      final uid = v.uniqueId;
      if (v.deviceId != null) {
        ref.read(localStorageProvider).setDeviceId(v.deviceId.toString());
      } else if (uid != null && uid.isNotEmpty) {
        ref.read(localStorageProvider).setDeviceId(uid);
      }
    }
  }

  void _showUnassignedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.loc.noVehiclesAssigned),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: context.loc.vehiclesAssignedViaPortal),
              TextSpan(
                text: context.loc.contactFleetManager,
                style: context.styles.error.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _browsingCompany = false);
                  ref
                      .read(vehicleProvider.notifier)
                      .loadVehicles(forceRefresh: true);
                },
                child: Text(
                  context.loc.viewMyVehicles,
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _browsingCompany = true);
                  ref.read(vehicleProvider.notifier).loadCompanyVehicles();
                },
                child: Text(
                  context.loc.viewAllVehicles,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغييرات الحالة من Provider للانتقال أو إظهار خطأ
    ref.listen<VehicleState>(vehicleProvider, (previous, current) {
      if (current.error != null && (previous?.error != current.error)) {
        AppFeedback.error(
          context,
          vehicleErrorText(current.error!, context.loc),
        );
      }

      // SRS 9.1 — the "No Vehicles Assigned" prompt is for drivers with no
      // assigned vehicle at all, not merely "nothing selected yet".
      if (!_askedUnassigned &&
          current.isInitialized &&
          !current.isLoading &&
          current.selectedVehicle == null &&
          current.vehicles.where((v) => v.isAssigned).isEmpty) {
        _askedUnassigned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showUnassignedDialog(context);
        });
      }

      if (current.isSuccess && !(previous?.isSuccess ?? false)) {
        final name = current.selectedVehicle?.displayName ?? '';
        AppFeedback.success(
          context,
          // Select ≠ Operate: the server session is opened on the
          // Connection page, so nothing is claimed as accepted here.
          context.loc.vehicleSelectedConnect(name),
        );
        // التوجيه إلى شاشة الاتصال بالجهاز بناءً على المتطلب 3.2
        context.go(AppRoutes.connection);
      }
    });

    final vehicleState = ref.watch(vehicleProvider);
    final filteredVehicles = vehicleState.filteredVehicles;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.selectVehicle,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,

        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const EldDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppTextField(
              controller: _searchController,
              hint: context.loc.searchVehicle,
              prefixIcon: const Icon(Icons.search),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                ref.read(vehicleProvider.notifier).search(value);
              },
            ),
          ),

          // ========== قائمة المركبات ==========
          Expanded(
            child: vehicleState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: context.colorScheme.surface,
                    onRefresh: () {
                      if (_browsingCompany) {
                        return ref
                            .read(vehicleProvider.notifier)
                            .loadCompanyVehicles();
                      }
                      return ref
                          .read(vehicleProvider.notifier)
                          .loadVehicles(forceRefresh: true);
                    },
                    child: filteredVehicles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                child: EldRetryView(
                                  message: vehicleState.error != null
                                      ? vehicleErrorText(
                                          vehicleState.error!,
                                          context.loc,
                                        )
                                      : context.loc.noVehiclesFound,
                                  isError: vehicleState.error != null,
                                  onRetry: () {
                                    if (_browsingCompany) {
                                      ref
                                          .read(vehicleProvider.notifier)
                                          .loadCompanyVehicles();
                                    } else {
                                      ref
                                          .read(vehicleProvider.notifier)
                                          .loadVehicles(forceRefresh: true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: filteredVehicles.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final vehicle = filteredVehicles[index];
                              return VehicleCard(
                                key: ValueKey(vehicle.id),
                                vehicle: vehicle,
                                operable: listedVehicleIsOperable(
                                  browsingCompanyFleet: _browsingCompany,
                                  vehicle: vehicle,
                                ),
                                onTap: () => _handleVehicleSelected(vehicle),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
