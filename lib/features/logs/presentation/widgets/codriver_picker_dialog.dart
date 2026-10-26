import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../../core/error/user_facing_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../codriver/domain/entities/codriver.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';

// Export CoDriver so we don't break form_tab.dart
export '../../../codriver/domain/entities/codriver.dart';

/// Dialog اختيار السائق المساعد
class CoDriverPickerDialog extends ConsumerStatefulWidget {
  final String? currentCoDriverId;

  const CoDriverPickerDialog({super.key, this.currentCoDriverId});

  @override
  ConsumerState<CoDriverPickerDialog> createState() =>
      _CoDriverPickerDialogState();
}

class _CoDriverPickerDialogState extends ConsumerState<CoDriverPickerDialog> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentCoDriverId ?? 'none';
    // القائمة قد تكون فارغة (أُنشئ المزود مبكراً بلا شبكة أو انتهت
    // جلسته) — أعد الجلب عند الفتح بدل عرض فراغ دائم.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(codriverProvider.notifier);
      if (!notifier.hasAvailableDrivers) {
        notifier.reload();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final codriverState = ref.watch(codriverProvider);
    final codrivers = [CoDriver.none, ...codriverState.availableDrivers];

    return AlertDialog(
      title: Text(context.loc.coDriver),
      content: SizedBox(
        width: double.maxFinite,
        child: codriverState.isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : codriverState.error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    codriverState.error == null
                        ? context.loc.errRequestFailed
                        : anyErrorUserMessage(
                            codriverState.error!,
                            loc: context.loc,
                          ),
                    style: context.styles.error,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        ref.read(codriverProvider.notifier).reload(),
                    child: Text(context.loc.retryButton),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: _selectedId,
                  onChanged: (value) => setState(() => _selectedId = value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: codrivers.map((driver) {
                      final isSelected = driver.id == _selectedId;
                      return RadioListTile<String>(
                        title: Text(
                          driver.name,
                          style: context.styles.body.copyWith(
                            fontWeight: isSelected
                                ? AppTypography.bold
                                : AppTypography.regular,
                          ),
                        ),
                        value: driver.id,
                        activeColor: context.gold,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
        TextButton(
          onPressed: () {
            final selected = codrivers.firstWhere(
              (d) => d.id == _selectedId,
              orElse: () => codrivers.first,
            );
            Navigator.pop(context, selected);
          },
          child: Text(context.loc.okButton),
        ),
      ],
    );
  }
}
