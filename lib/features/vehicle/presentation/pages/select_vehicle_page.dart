import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/routes/app_routes.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';
import '../providers/vehicle_provider.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // P0 corrections: التحميل الأولي تقوده الصفحة (لا كونستركتر المزود،
    // حتى لا يُطلق مجرد الاستماع GET عند الإقلاع البارد). الـ latch داخل
    // loadVehicles يجعل الاستدعاء المكرر آمناً.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(vehicleProvider.notifier);
      // H-D1: لا طلب مكرر — إن كان المصنع قد بدأ تحميل المالك (جارٍ)
      // أو اكتمل، تُترك النتيجة؛ التحميل هنا لحالة الفراغ التام فقط.
      if (!notifier.isInitialized && !notifier.isLoading) {
        notifier.loadVehicles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleVehicleSelected(Vehicle vehicle) {
    if (!listedVehicleIsOperable(
      browsingCompanyFleet: ref.read(vehicleProvider).isCompanyFleet,
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
    if (readOperableUniqueId(vehicle.uniqueId) == null) {
      AppFeedback.error(
        context,
        vehicleErrorText('identifierMissing', context.loc),
      );
      return;
    }
    ref
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
      // حفظ الاختيار يتم داخل VehicleNotifier موسوماً بمالكه؛ لا نكتب هنا
      // قيمة مجرّدة حتى لا نمحو وسم المالك.
      // رسالة حالة مختصرة: نجاح الاختيار فقط، بلا بيانات المركبة الكاملة.
      // رقم المركبة يظهر في شريط صفحة الاتصال بعد الانتقال.
      AppFeedback.success(context, context.loc.vehicleSelected);
      context.go(AppRoutes.connection);
    }
  }

  void _showUnassignedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: context.loc.noVehiclesAssigned,
        type: AppDialogType.informational,
        contentWidget: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: context.loc.vehiclesAssignedViaPortal,
                style: context.styles.body,
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: context.loc.contactFleetManager,
                style: context.styles.error.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        primaryActionLabel: context.loc.viewAllVehicles,
        onPrimaryAction: () {
          Navigator.pop(dialogContext);
          ref.read(vehicleProvider.notifier).loadCompanyVehicles();
        },
        secondaryActionLabel: context.loc.viewMyVehicles,
        onSecondaryAction: () {
          Navigator.pop(dialogContext);
          ref
              .read(vehicleProvider.notifier)
              .loadVehicles(forceRefresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغييرات الحالة من Provider للانتقال أو إظهار خطأ
    ref.listen<VehicleState>(vehicleProvider, (previous, current) {
      if (current.error != null &&
          previous?.error != current.error &&
          current.vehicles.isNotEmpty) {
        AppFeedback.error(
          context,
          vehicleErrorText(current.error!, context.loc),
        );
      }

      // SRS 9.1 — the "No Vehicles Assigned" prompt is for drivers with no
      // assigned vehicle at all, not merely "nothing selected yet".
      if (!_askedUnassigned &&
          !current.isCompanyFleet &&
          current.isInitialized &&
          !current.isLoading &&
          current.selectedVehicle == null &&
          current.vehicles.where((v) => v.isAssigned).isEmpty) {
        _askedUnassigned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showUnassignedDialog(context);
        });
      }
    });

    final vehicleState = ref.watch(vehicleProvider);
    final filteredVehicles = vehicleState.filteredVehicles;
    final browsingCompany = vehicleState.isCompanyFleet;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
        variant: GoldenAppBarVariant.brand,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: context.onGold,
            size: AppSpacing.iconSize,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        titleText: context.loc.selectVehicle,
        actions: [
          IconButton(
            icon: Icon(
              browsingCompany ? Icons.directions_car : Icons.filter_list,
              color: context.onGold,
              size: AppSpacing.iconSize,
            ),
            tooltip: browsingCompany
                ? context.loc.viewMyVehicles
                : context.loc.viewAllVehicles,
            onPressed: () {
              if (!browsingCompany) {
                ref.read(vehicleProvider.notifier).loadCompanyVehicles();
              } else {
                ref
                    .read(vehicleProvider.notifier)
                    .loadVehicles(forceRefresh: true);
              }
            },
          ),
        ],
      ),
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
                      if (browsingCompany) {
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
                                    if (browsingCompany) {
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
                                isCurrent:
                                    vehicle.id ==
                                        vehicleState.selectedVehicle?.id ||
                                    vehicle.activeForCurrentDriver == true,
                                operable: listedVehicleIsOperable(
                                  browsingCompanyFleet: browsingCompany,
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
