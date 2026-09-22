import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_provider.dart';

/// شاشة اختيار المركبة
class SelectVehiclePage extends ConsumerStatefulWidget {
  const SelectVehiclePage({super.key});

  @override
  ConsumerState<SelectVehiclePage> createState() => _SelectVehiclePageState();
}

class _SelectVehiclePageState extends ConsumerState<SelectVehiclePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleProvider.notifier).loadVehicles(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleVehicleSelected(Vehicle vehicle) async {
    final notifier = ref.read(vehicleProvider.notifier);
    await notifier.selectVehicle(vehicle);
  }

  /// إظهار Dialog المركبات غير المسندة
  void _showUnassignedVehicleDialog() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber,
                color: AppColors.warningYellow, size: 28),
            AppGap.hSm,
            Text(
              context.loc.unassignedVehicles,
              style: AppTextStyles(context).bodyBold,
            ),
          ],
        ),
        content: Text(
          context.loc.unassignedVehiclesCannotBeSelected,
          style: isArabic
              ? AppTextStyles(context).arabicBody
              : AppTextStyles(context).body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.loc.okButton,
              style: AppTextStyles(context)
                  .buttonText
                  .copyWith(color: AppColors.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.loc.contactManager,
              style: AppTextStyles(context)
                  .buttonText
                  .copyWith(color: AppColors.dangerRed),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.error!),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }

      if (current.isSuccess && !(previous?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.loc.vehicleSelected}: ${current.selectedVehicle?.displayName ?? ""}'),
            backgroundColor: AppColors.successGreen,
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
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          context.loc.selectVehicle,
          style: AppTextStyles(context)
              .pageTitle
              .copyWith(color: AppColors.surface),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: Column(
        children: [
          // ========== حقل البحث ==========
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
                    onRefresh: () => ref
                        .read(vehicleProvider.notifier)
                        .loadVehicles(forceRefresh: true),
                    child: filteredVehicles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_shipping,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.outline),
                                      AppGap.md,
                                      Text(context.loc.noVehiclesFound),
                                    ],
                                  ),
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
                            separatorBuilder: (_, __) => AppGap.sm,
                            itemBuilder: (context, index) {
                              final vehicle = filteredVehicles[index];
                              return _VehicleCard(
                                key: ValueKey(vehicle.id),
                                vehicle: vehicle,
                                onTap: () {
                                  if (!vehicle.isAssigned) {
                                    _showUnassignedVehicleDialog();
                                  } else {
                                    _handleVehicleSelected(vehicle);
                                  }
                                },
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

/// بطاقة مركبة
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({super.key, required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // ========== أيقونة المركبة ==========
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: vehicle.isAssigned
                      ? Theme.of(context).infoLightBackground
                      : Theme.of(context).warningLightBackground,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: vehicle.isAssigned
                      ? AppColors.primaryBlue
                      : AppColors.warningYellow,
                  size: 28,
                ),
              ),
              AppGap.hMd,

              // ========== معلومات المركبة ==========
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: AppTextStyles(context).bodyBold,
                    ),
                    AppGap.xs,
                    if (vehicle.vin != null)
                      Text(
                        'VIN: ${vehicle.vin!.length > 8 ? vehicle.vin!.substring(vehicle.vin!.length - 8) : vehicle.vin}',
                        style: AppTextStyles(context)
                            .caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    if (!vehicle.isAssigned) ...[
                      AppGap.xs,
                      AppStatusBadge(
                        label: context.loc.unassigned,
                        type: AppStatusBadgeType.warning,
                      ),
                    ],
                  ],
                ),
              ),

              // ========== سهم التوجيه ==========
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
