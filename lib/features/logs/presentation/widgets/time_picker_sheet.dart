import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// منتقي الوقت (Picker Wheel)
class TimePickerSheet extends StatefulWidget {
  final Function(String) onDone;
  final DateTime initialTime;

  const TimePickerSheet({super.key, required this.onDone, required this.initialTime});

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  int _selectedHour = 12;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  String _selectedPeriod = 'AM';

  late final FixedExtentScrollController _hourWheel;
  late final FixedExtentScrollController _minuteWheel;
  late final FixedExtentScrollController _secondWheel;

  @override
  void initState() {
    super.initState();
    final now = widget.initialTime;
    _selectedHour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    _selectedMinute = now.minute;
    _selectedSecond = now.second;
    _selectedPeriod = now.hour < 12 ? 'AM' : 'PM';
    _hourWheel = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteWheel = FixedExtentScrollController(initialItem: _selectedMinute);
    _secondWheel = FixedExtentScrollController(initialItem: _selectedSecond);
  }

  @override
  void dispose() {
    _hourWheel.dispose();
    _minuteWheel.dispose();
    _secondWheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 300,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.loc.cancelButton,
                  style: context.styles.error,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Always use English AM/PM so parseEditFormTime can parse it properly.
                  final time = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:${_selectedSecond.toString().padLeft(2, '0')} $_selectedPeriod';
                  widget.onDone(time);
                },
                child: Text(context.loc.saveButton, style: context.styles.gold),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: Row(
              children: [
                _buildWheel(
                  12,
                  _hourWheel,
                  _selectedHour,
                  (v) => setState(() => _selectedHour = v),
                  offset: 1,
                ),
                _buildWheel(
                  60,
                  _minuteWheel,
                  _selectedMinute,
                  (v) => setState(() => _selectedMinute = v),
                ),
                _buildWheel(
                  60,
                  _secondWheel,
                  _selectedSecond,
                  (v) => setState(() => _selectedSecond = v),
                ),
                _buildPeriodWheel(context.loc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(
    int max,
    FixedExtentScrollController controller,
    int selected,
    Function(int) onChanged, {
    int offset = 0,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: (index) => onChanged(index + offset),
        controller: controller,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final val = index + offset;
            return Center(
              child: Text(
                val.toString().padLeft(2, '0'),
                style: context.styles.body.copyWith(
                  fontSize: AppTypography.headerSize,
                  fontWeight: val == selected
                      ? AppTypography.bold
                      : AppTypography.regular,
                  color: val == selected
                      ? context.styles.gold.color
                      : context.styles.subtitle.color,
                ),
              ),
            );
          },
          childCount: max,
        ),
      ),
    );
  }

  Widget _buildPeriodWheel(AppLocalizations loc) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.5,
        onSelectedItemChanged: (index) {
          setState(() => _selectedPeriod = index == 0 ? 'AM' : 'PM');
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) => Center(
            child: Text(
              // Display translated AM/PM for the user
              index == 0 ? loc.am : loc.pm,
              style: context.styles.body.copyWith(
                fontWeight: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? AppTypography.bold
                    : AppTypography.regular,
                color: _selectedPeriod == (index == 0 ? 'AM' : 'PM')
                    ? context.styles.gold.color
                    : context.styles.subtitle.color,
              ),
            ),
          ),
          childCount: 2,
        ),
      ),
    );
  }
}
