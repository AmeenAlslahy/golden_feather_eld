import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
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
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
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

    final report = DvirReport(
      id: widget.existingReport?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: InspectionType.preTrip,
      date: widget.existingReport?.date ?? DateTime.now(),
      driverName: dashboard.driverName,
      vehicleId: dashboard.vehicleId,
      trailerId: dashboard.trailerId,
      odometer: double.tryParse(_odometerController.text),
      items: const [], // Detailed items not used in this flat layout, but we pass defects strings
      notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      signature: signatureData != null
          ? 'signature_${DateTime.now().millisecondsSinceEpoch}'
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

    if (widget.existingReport != null) {
      ref.read(dvirProvider.notifier).updateReport(report);
    } else {
      await ref.read(dvirProvider.notifier).createReport(report);
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.reportSavedSuccess),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context);
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
                  style: TextStyle(color: textColor, fontSize: 14)),
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
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text(dashboard.vehicleDisplayName,
                            style: TextStyle(color: textColor, fontSize: 14)),
                        const SizedBox(height: AppSpacing.md),
                        Text(context.loc.trailers,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 4),
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
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        _buildFlatTextField(_vehicleDefectsController,
                            context.loc.defectsTitle, textColor),
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.loc.defectsTitle,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
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
                          child: Text(status, style: TextStyle(color: textColor, fontSize: 14)),
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
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () => _signatureController.clear(),
                    child: const Text(
                      'Clear signature',
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
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
            const SizedBox(height: 32.0),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
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
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}
