import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';
import '../providers/vehicle_provider.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../../core/widgets/app_feedback.dart';

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
      AppFeedback.error(context, _vehicleErrorText(vehicle.inUseByOther == true ? 'in_use' : 'unauthorized', context.loc));
      return;
    }
    await ref.read(vehicleProvider.notifier).selectVehicle(
          vehicle,
          speedMps: ref.read(currentVehicleSpeedProvider),
          thresholdKmh:
              ref.read(hosConfigurationProvider).movingSpeedThresholdKmh,
        );
  }

  void _showUnassignedDialog(BuildContext context) {
    
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.loc.noVehiclesAssigned),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: context.loc.vehiclesAssignedViaPortal,
              ),
              TextSpan(
                text: context.loc.contactFleetManager,
                style: context.styles.error.copyWith(fontWeight: FontWeight.w600),
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
        
        AppFeedback.error(context, _vehicleErrorText(current.error!, context.loc));
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
        AppFeedback.success(context, 
              // Select ≠ Operate: the server session is opened on the
              // Connection page, so nothing is claimed as accepted here.
              context.loc.vehicleSelectedConnect(name));
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
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
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: EldRetryView(
                              message: vehicleState.error != null
                                  ? _vehicleErrorText(vehicleState.error!, context.loc)
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
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final vehicle = filteredVehicles[index];
                          return _VehicleCard(
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

/// صف مركبة مطابق للقطة (رقم + سنة وموديل).
///
/// SRS 9.2/9.4: the row states *before* the tap whether the driver may
/// operate it. View-only rows (company fleet not assigned to the driver, or in
/// use by another driver) are dimmed and carry a badge; tapping them still
/// shows the refusal message instead of starting a session.
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool operable;
  final VoidCallback onTap;

  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.operable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    final subtitleBits = <String>[
      if (vehicle.year.isNotEmpty) vehicle.year,
      if (vehicle.name.isNotEmpty) vehicle.name,
    ];
    final badge = _rowBadge(context.loc);
    final reason = vehicle.statusReason?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black.withValues(alpha: 0.12),
      highlightColor: Colors.black.withValues(alpha: 0.06),
      child: Opacity(
        opacity: operable ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.id.isNotEmpty ? vehicle.id : vehicle.displayName,
                      style: context.styles.bodyBold,
                    ),
                    if (subtitleBits.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleBits.join(' '),
                        style: context.styles.caption,
                      ),
                    ],
                    if (!operable && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(reason, style: context.styles.caption),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                badge,
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppStatusBadge? _rowBadge(AppLocalizations loc) {
    if (vehicle.inUseByOther == true) {
      return AppStatusBadge(
        label: loc.inUse,
        type: AppStatusBadgeType.error,
      );
    }
    if (!operable) {
      return AppStatusBadge(
        label: loc.viewOnly,
        type: AppStatusBadgeType.warning,
      );
    }
    if (vehicle.isAssigned) {
      return AppStatusBadge(
        label: loc.assignedToYou,
        type: AppStatusBadgeType.success,
      );
    }
    return null;
  }
}

String _vehicleErrorText(String raw, AppLocalizations loc) {
  switch (raw) {
    case 'motionUnknown':
      return loc.errMotionUnknown;
    case 'vehicleMoving':
      return loc.errVehicleMoving;
    case 'identifierMissing':
    case 'vehicle_identifier_missing':
      return loc.errIdentifierMissing;
    case 'thresholdMissing':
      return loc.errThresholdMissing;
    case 'unauthorized':
      return loc.errUnauthorized;
    case 'unavailable':
      return loc.errUnavailable;
    case 'in_use':
      return loc.errInUse;
    case 'rejected':
      return loc.errRejected;
    case 'vehicle_list_unreadable':
      return loc.errListUnreadable;
    default:
      return raw;
  }
}

