import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
                height: 100, child: Center(child: CircularProgressIndicator()))
            : codriverState.error != null
                ? Text(
                    'Error: ${codriverState.error}',
                    style: const TextStyle(color: Colors.red),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: codrivers.map((driver) {
                        final isSelected = driver.id == _selectedId;
                        return RadioListTile<String>(
                          title: Text(
                            driver.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          value: driver.id,
                          groupValue: _selectedId,
                          onChanged: (value) {
                            setState(() => _selectedId = value);
                          },
                          activeColor: AppColors.primaryBlue,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelButton),
        ),
        FilledButton(
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
