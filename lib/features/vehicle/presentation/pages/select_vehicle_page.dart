import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../../routes.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber,
                color: AppColors.warningYellow, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(
              isArabic ? 'مركبات غير معينة' : 'Unassigned Vehicles',
              style: AppTextStyles(context).bodyBold,
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'المركبات غير المسندة لا يمكن اختيارها مباشرة. يتم تعيين المركبات للسائقين عبر البوابة الإلكترونية من قبل مدير الأسطول.\n\nيرجى الاتصال بمدير الأسطول لتعيين المركبة.'
              : 'Unassigned vehicles cannot be selected directly. Vehicles are assigned to drivers through the web portal by the fleet manager.\n\nPlease contact your fleet manager to assign the vehicle.',
          style: isArabic
              ? AppTextStyles(context).arabicBody
              : AppTextStyles(context).body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'موافق' : 'OK',
              style: AppTextStyles(context)
                  .buttonText
                  .copyWith(color: AppColors.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'اتصل بالمدير' : 'Contact Manager',
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
        context.go(AppRoutes.home);
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
                : filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: AppSpacing.md),
                            Text(context.loc.noVehiclesFound),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: filteredVehicles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.md),

              // ========== معلومات المركبة ==========
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: AppTextStyles(context).bodyBold,
                    ),
                    const SizedBox(height: 4),
                    if (vehicle.vin != null)
                      Text(
                        'VIN: ${vehicle.vin!.length > 8 ? vehicle.vin!.substring(vehicle.vin!.length - 8) : vehicle.vin}',
                        style: AppTextStyles(context)
                            .caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    if (!vehicle.isAssigned) ...[
                      const SizedBox(height: 4),
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
