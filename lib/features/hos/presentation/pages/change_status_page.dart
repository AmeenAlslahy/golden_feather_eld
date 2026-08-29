import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/engine/hos_rules_engine.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../providers/hos_provider.dart';

class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key});

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  late DutyStatus _selectedStatus;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ضبط الحالة المبدئية بناءً على الحالة الحالية للسائق
    _selectedStatus = ref.read(hosStatusProvider).currentStatus;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.surface, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.loc.changeStatus,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قائمة الحالات
            _buildStatusRadio(DutyStatus.offDuty, context.loc.offDuty),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _buildStatusRadio(DutyStatus.sleeperBerth, context.loc.sleeperBerth),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _buildStatusRadio(DutyStatus.driving, context.loc.drivingStatus),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _buildStatusRadio(DutyStatus.onDutyNotDriving, context.loc.onDuty),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _buildStatusRadio(DutyStatus.personalUse, context.loc.personalUse),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            // Yard Moves (غير مدعومة حالياً في Engine الأساسي، لكن سنربطها بحالة OnDuty كإجراء فرعي إن لزم الأمر)
            _buildCustomRadio(context.loc.yardMoves),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            
            const SizedBox(height: 24),
            
            // الموقع الجغرافي (مبني ديناميكيا)
            Consumer(
              builder: (context, ref, child) {
                final trackingState = ref.watch(trackingStateProvider);
                final locString = trackingState.currentLocation != null 
                    ? '${trackingState.currentLocation!.latitude.toStringAsFixed(4)}, ${trackingState.currentLocation!.longitude.toStringAsFixed(4)}'
                    : context.loc.calculatingLocation;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    locString,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            
            // حقل الموقع المخصص
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: context.loc.customLocation,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            Divider(height: 1, color: Theme.of(context).dividerColor),
            
            // حقل الملاحظات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: context.loc.notes,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            Divider(height: 1, color: Theme.of(context).dividerColor),
            
            const SizedBox(height: 32),
            
            // زر الحفظ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  // جلب السرعة الحالية
                  final trackingState = ref.read(trackingStateProvider);
                  final speedMs = trackingState.currentLocation?.speed;
                  final currentSpeedKmh = speedMs != null ? speedMs * 3.6 : 0.0;

                  // تحديث الحالة في محرك HOS
                  final success = ref.read(hosStatusProvider.notifier).changeStatus(
                    _selectedStatus,
                    annotation: _notesController.text.isNotEmpty ? _notesController.text : null,
                    currentSpeed: currentSpeedKmh,
                  );
                  
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.loc.errorCannotChangeStatusWhileMoving),
                        backgroundColor: AppColors.dangerRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // لا تغلق النافذة
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen, // أخضر فاتح مطابق للتصميم
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  context.loc.updateButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRadio(DutyStatus status, String label) {
    // إذا كانت حالة القيادة وهي الحالة المحددة نلونها، وإن لم تكن لا يمكن للسائق اختيارها يدوياً عادة
    // ولكن للتصميم سنسمح بتحديدها
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: AppTypography.semiBold,
                color: status == DutyStatus.driving && !isSelected 
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5) 
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryBlue : Theme.of(context).dividerColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // لYard Moves الغير مدعومة بشكل مباشر في الإينام
  Widget _buildCustomRadio(String label) {
    return InkWell(
      onTap: () {
        // Handle yard moves
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: AppTypography.semiBold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Icon(
              Icons.radio_button_unchecked,
              color: Theme.of(context).dividerColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}



