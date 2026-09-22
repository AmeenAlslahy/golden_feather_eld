import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/dvir_report.dart';
import '../providers/dvir_provider.dart';

class DvirFormPage extends ConsumerStatefulWidget {
  final DvirReport? existingReport;

  const DvirFormPage({super.key, this.existingReport});

  @override
  ConsumerState<DvirFormPage> createState() => _DvirFormPageState();
}

class _DvirFormPageState extends ConsumerState<DvirFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the new flat layout
  late TextEditingController _locationController;
  late TextEditingController _odometerController;
  late TextEditingController _vehicleDefectsController;
  late TextEditingController _trailerDefectsController;
  late TextEditingController _companyController;
  late TextEditingController _remarksController;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.black,
    exportBackgroundColor: AppColors.surface,
  );

  bool _isSubmitting = false;

  String _selectedStatus = 'Safe to Drive';
  final List<String> _statusOptions = [
    'Safe to Drive',
    'Needs Repair',
    'Unsafe'
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingReport;
    _locationController = TextEditingController(
        text: r?.location ?? '8257mi SE from Isla Mujeres, Quintana Roo');
    _odometerController =
        TextEditingController(text: r?.odometer?.toString() ?? '');
    _vehicleDefectsController =
        TextEditingController(text: r?.vehicleDefects ?? '');
    _trailerDefectsController =
        TextEditingController(text: r?.trailerDefects ?? '');
    _companyController = TextEditingController(
        text:
            r?.companyName ?? 'GOLDEN GATE TRANSPORT LLC');
    _remarksController = TextEditingController(text: r?.notes ?? '');
    if (r != null) {
      _selectedStatus = r.condition.englishName;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _odometerController.dispose();
    _vehicleDefectsController.dispose();
    _trailerDefectsController.dispose();
    _companyController.dispose();
    _remarksController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final dashboard = ref.read(dashboardDataProvider);
    final signatureData = await _signatureController.toPngBytes();

    VehicleCondition condition = VehicleCondition.safe;
    if (_selectedStatus == 'Needs Repair') condition = VehicleCondition.needsRepair;
    if (_selectedStatus == 'Unsafe') condition = VehicleCondition.unsafe;

    bool hasDefects = _vehicleDefectsController.text.isNotEmpty || _trailerDefectsController.text.isNotEmpty;

    final List<ItemInspectionResult> items = [];
    if (_vehicleDefectsController.text.isNotEmpty) {
      items.add(ItemInspectionResult(
        item: InspectionItem.engine, // Using a generic item since we don't have 'vehicle' enum
        isDefective: true,
        defectDescription: 'Vehicle: ${_vehicleDefectsController.text}',
      ));
    }
    if (_trailerDefectsController.text.isNotEmpty) {
      items.add(ItemInspectionResult(
        item: InspectionItem.trailerCoupling,
        isDefective: true,
        defectDescription: 'Trailer: ${_trailerDefectsController.text}',
      ));
    }

    final report = DvirReport(
      id: widget.existingReport?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: InspectionType.preTrip,
      date: widget.existingReport?.date ?? DateTime.now(),
      driverName: dashboard.driverName,
      vehicleId: dashboard.vehicleId,
      trailerId: dashboard.trailerId,
      odometer: double.tryParse(_odometerController.text),
      items: items,
      notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      signature: signatureData != null
          ? base64Encode(signatureData)
          : null,
      condition: condition,
      isSubmitted: true,

      // New fields
      location: _locationController.text,
      companyName: _companyController.text,
      vehicleDefects: _vehicleDefectsController.text,
      trailerDefects: _trailerDefectsController.text,
      hasDefects: hasDefects,
      defectsCount: hasDefects ? 1 : 0, // Simplified for this layout
      defectsSummary: hasDefects ? '${_vehicleDefectsController.text} | ${_trailerDefectsController.text}' : null,
    );

    bool success = false;
    if (widget.existingReport != null) {
      final res = await ref.read(dvirProvider.notifier).updateReport(report);
      success = res.isRight();
    } else {
      final res = await ref.read(dvirProvider.notifier).createReport(report);
      success = res.isRight();
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.reportSavedSuccess),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save report'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final borderColor = AppColors.borderFor(brightness);

    final String currentTime =
        DateFormat('d MMM yy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Insert DVIR', // Using English exactly as in screenshot
          style: TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildFieldGroup(
              title: 'Time (ET)',
              child: Text(currentTime,
                  style: context.textTheme.bodyMedium?.copyWith(color: textColor)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Location',
              child: _buildFlatTextField(
                  _locationController, 'Location', textColor),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Odometer (mi)',
              child: _buildFlatTextField(
                  _odometerController, 'Odometer', textColor,
                  keyboardType: TextInputType.number),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Grid for Vehicle and Trailers
            Container(
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor))),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc.vehicle,
                            style: context.textTheme.labelSmall?.copyWith(color: textColor)),
                        AppGap.xs,
                        Text(dashboard.vehicleDisplayName,
                            style: context.textTheme.bodyMedium?.copyWith(color: textColor)),
                        AppGap.md,
                        Text(context.loc.trailers,
                            style: context.textTheme.labelSmall?.copyWith(color: textColor)),
                        AppGap.xs,
                        Text(dashboard.trailerId ?? context.loc.trailers,
                            style: TextStyle(
                                color: AppColors.textSecondaryFor(
                                    brightness),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc.defectsTitle,
                            style: context.textTheme.labelSmall?.copyWith(color: textColor)),
                        _buildFlatTextField(_vehicleDefectsController,
                            context.loc.defectsTitle, textColor),
                        AppGap.sm,
                        Text(context.loc.defectsTitle,
                            style: context.textTheme.labelSmall?.copyWith(color: textColor)),
                        _buildFlatTextField(_trailerDefectsController,
                            context.loc.defectsTitle, textColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildFieldGroup(
              title: 'Company',
              child:
                  _buildFlatTextField(_companyController, 'Company', textColor),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Remarks',
              child:
                  _buildFlatTextField(_remarksController, 'Remarks', textColor),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Status',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                dropdownColor: surfaceColor,
                items: _statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status, style: context.textTheme.bodyMedium?.copyWith(color: textColor)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.arrow_drop_down, color: textColor),
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Signature Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: borderColor.withValues(alpha: 0.5)),
                      color: Colors
                          .white, // Ensure signature pad is visible against white
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            'Image not\navailable.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade300),
                          ),
                        ),
                        Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  AppGap.sm,
                  InkWell(
                    onTap: () => _signatureController.clear(),
                    child: Text(
                      'Clear signature',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Sign Button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: AppButton(
                label: 'SIGN', // Fixed text matching screenshot
                type: EldButtonType.agree,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ),
            AppGap.xl,
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup({
    required String title,
    required Widget child,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(color: textColor),
          ),
          AppGap.xs,
          child,
        ],
      ),
    );
  }

  Widget _buildFlatTextField(
      TextEditingController controller, String hint, Color textColor,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: context.textTheme.bodyMedium?.copyWith(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.textTheme.bodyMedium?.copyWith(color: AppColors.border),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      ),
    );
  }
}
