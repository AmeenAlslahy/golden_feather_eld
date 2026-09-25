import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';
import '../providers/vehicle_provider.dart';

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!listedVehicleIsOperable(
      browsingCompanyFleet: _browsingCompany,
      vehicle: vehicle,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vehicleErrorText(
            vehicle.inUseByOther == true ? 'in_use' : 'unauthorized',
            isArabic,
          )),
          backgroundColor: context.colors.error,
        ),
      );
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'مركبات غير معيّنة' : 'Unassigned Vehicles'),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: isArabic
                    ? 'تُعيَّن المركبات عبر البوابة. '
                    : 'Vehicles are assigned via the portal. ',
              ),
              TextSpan(
                text: isArabic
                    ? 'تواصل مع مدير الأسطول للمزيد.'
                    : 'Contact your fleet manager for more info.',
                style: const TextStyle(color: Color(0xFFE53935)),
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
                  isArabic ? 'عرض مركباتي' : 'VIEW MY VEHICLES',
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
                  isArabic ? 'عرض كل المركبات' : 'VIEW ALL VEHICLES',
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
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_vehicleErrorText(current.error!, isArabic)),
            backgroundColor: context.colors.error,
          ),
        );
      }

      if (!_askedUnassigned &&
          current.isInitialized &&
          !current.isLoading &&
          current.selectedVehicle == null) {
        _askedUnassigned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showUnassignedDialog(context);
        });
      }

      if (current.isSuccess && !(previous?.isSuccess ?? false)) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final name = current.selectedVehicle?.displayName ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // Select ≠ Operate: the server session is opened on the
              // Connection page, so nothing is claimed as accepted here.
              isArabic
                  ? 'تم اختيار $name. اتصل بجهاز ELD لتشغيلها. لم تُنقل ساعات الخدمة.'
                  : 'Selected $name. Connect to the ELD to operate it. Hours were not copied.',
            ),
            backgroundColor: context.eld.successFg,
          ),
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
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.onPrimary),
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
              icon: Icon(Icons.menu, color: context.colors.onPrimary),
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
                                  ? _vehicleErrorText(
                                      vehicleState.error!,
                                      Localizations.localeOf(context)
                                              .languageCode ==
                                          'ar',
                                    )
                                  : context.loc.noVehiclesFound,
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final subtitleBits = <String>[
      if (vehicle.year.isNotEmpty) vehicle.year,
      if (vehicle.name.isNotEmpty) vehicle.name,
    ];
    final badge = _rowBadge(isArabic);
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

  AppStatusBadge? _rowBadge(bool isArabic) {
    if (vehicle.inUseByOther == true) {
      return AppStatusBadge(
        label: isArabic ? 'قيد الاستخدام' : 'In use',
        type: AppStatusBadgeType.error,
      );
    }
    if (!operable) {
      return AppStatusBadge(
        label: isArabic ? 'عرض فقط' : 'View only',
        type: AppStatusBadgeType.warning,
      );
    }
    if (vehicle.isAssigned) {
      return AppStatusBadge(
        label: isArabic ? 'معيّنة لك' : 'Assigned to you',
        type: AppStatusBadgeType.success,
      );
    }
    return null;
  }
}

String _vehicleErrorText(String raw, bool isArabic) {
  switch (raw) {
    case 'motionUnknown':
      return isArabic
          ? 'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.'
          : 'Vehicle motion is unknown. That is not treated as stopped.';
    case 'vehicleMoving':
      return isArabic
          ? 'لا يمكن تبديل المركبة وهي تتحرك. لم تُنقل الساعات.'
          : 'The vehicle cannot be changed while moving. Hours were not copied.';
    case 'identifierMissing':
    case 'vehicle_identifier_missing':
      return isArabic
          ? 'الخادم لم يُرجع معرف المركبة. لن يُخترع معرف.'
          : 'The server did not return a vehicle identifier. One will not be invented.';
    case 'thresholdMissing':
      return isArabic
          ? 'عتبة الحركة غير متوفرة من الإعداد.'
          : 'The motion threshold is not available.';
    case 'unauthorized':
      return isArabic
          ? 'غير مصرح بتشغيل هذه المركبة.'
          : 'Not authorized to operate this vehicle.';
    case 'unavailable':
      return isArabic ? 'المركبة غير متاحة.' : 'The vehicle is unavailable.';
    case 'in_use':
      return isArabic ? 'المركبة قيد الاستخدام.' : 'The vehicle is in use.';
    case 'rejected':
      return isArabic
          ? 'رفض الخادم تشغيل المركبة.'
          : 'The server rejected vehicle operation.';
    case 'vehicle_list_unreadable':
      return isArabic
          ? 'تعذر قراءة قائمة المركبات.'
          : 'The vehicle list could not be read.';
    default:
      return raw;
  }
}

