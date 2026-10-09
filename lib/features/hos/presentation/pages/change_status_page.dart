import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../duty_change_message.dart';
import '../providers/change_status_provider.dart';
import '../widgets/status_option_tiles.dart';

/// شاشة تغيير حالة خدمة السائق — مطابقة بنسبة 100% للتطبيق الأصلي
class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key});

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  late final TextEditingController _customLocationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(changeStatusProvider);
    _customLocationController =
        TextEditingController(text: state.customLocation);
    _notesController = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final result = await ref.read(changeStatusProvider.notifier).submit();
    if (!mounted) return;

    switch (result) {
      case DutyChangeSuccess():
        AppFeedback.success(context, dutyChangeAcceptedMessage(context));
        Navigator.pop(context);
      case DutyChangeAlreadyInProgress():
        break;
      case DutyChangeAnnotationRequired():
        AppFeedback.error(context, annotationRequiredMessage(context));
      case DutyChangeVehicleMoving():
        AppFeedback.error(
          context,
          context.loc.errorCannotChangeStatusWhileMoving,
        );
      case DutyChangeEngineRefusal(:final reason):
        AppFeedback.error(context, dutyChangeMessage(context, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changeStatusProvider);
    final notifier = ref.read(changeStatusProvider.notifier);

    final availableOptions = [
      DutyStatusOption.offDuty,
      DutyStatusOption.sleeperBerth,
      DutyStatusOption.driving,
      DutyStatusOption.onDuty,
      if (state.isPersonalConveyanceAllowed) DutyStatusOption.personalConveyance,
      if (state.isYardMoveAllowed) DutyStatusOption.yardMoves,
    ];

    final isEn = context.loc.localeName == 'en';
    final customLocationHint = isEn
        ? 'Custom location'
        : (context.loc.localeName == 'ar'
            ? 'موقع مخصص'
            : 'Ubicación personalizada');
    final notesHint = isEn ? 'Notes' : context.loc.notes;
    final updateLabel =
        isEn ? 'UPDATE' : context.loc.updateButton.toUpperCase();

    const primaryBlue = Color(0xFF0B60B0);
    const dividerColor = Color(0xFFEEEEEE);
    const hintTextColor = Color(0xFF9E9E9E);
    const buttonGreen = Color(0xFFA5D6A7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Change Status' : context.loc.changeStatus,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== قائمة الخيارات ==========
            for (var i = 0; i < availableOptions.length; i++) ...[
              Builder(
                builder: (context) {
                  final option = availableOptions[i];
                  final isSelected = state.selectedOption == option;
                  final disabled = state.isVehicleMoving &&
                      option != DutyStatusOption.driving &&
                      !isSelected;

                  return StatusOptionTile(
                    label: option.displayName(context),
                    isSelected: isSelected,
                    isLast: false,
                    enabled: !disabled,
                    onTap: disabled
                        ? null
                        : () => notifier.selectOption(option),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // ========== سطر الموقع الحالي ==========
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                state.location.isNotEmpty
                    ? state.location
                    : '8257mi SE from Isla Mujeres, Quintana Roo',
                style: const TextStyle(
                  fontSize: 15,
                  color: hintTextColor,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: dividerColor),

            // ========== حقل الموقع اليدوي (Custom location) ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _customLocationController,
                onChanged: notifier.updateCustomLocation,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: customLocationHint,
                  hintStyle:
                      const TextStyle(fontSize: 15, color: hintTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: dividerColor),

            // ========== حقل الملاحظات (Notes) ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _notesController,
                onChanged: notifier.updateNotes,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: notesHint,
                  hintStyle:
                      const TextStyle(fontSize: 15, color: hintTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: dividerColor),

            // ========== زر الحفظ UPDATE ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          updateLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),

            if (state.isVehicleMoving &&
                state.selectedOption != DutyStatusOption.driving)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  context.loc.errorCannotChangeStatusWhileMoving,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
