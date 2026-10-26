import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/eld_dropdown_row.dart';
import '../../../../../core/widgets/eld_info_row.dart';
import '../../providers/account_ui_state.dart';

/// قسم تفاصيل الحساب — مكون عرض نقي ومفصول عن أي منطق أو إدارة حالة.
class AccountDetailsSection extends StatelessWidget {
  final AccountUiState data;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onOdometerChanged;

  const AccountDetailsSection({
    super.key,
    required this.data,
    required this.onLanguageChanged,
    required this.onOdometerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EldInfoRow(label: loc.email1, value: data.email, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(label: loc.driverName, value: data.driverName, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(label: loc.phone, value: data.phone, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(label: loc.license, value: data.license, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(label: loc.carrier, value: data.carrier, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.mainOfficeAddress,
          value: data.mainOfficeAddress,
          dense: true,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.homeTerminalAddress,
          value: data.homeTerminalAddress,
          dense: true,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(label: loc.timeZone, value: data.timeZone, dense: true),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldDropdownRow(
          label: loc.languageLabel,
          value: data.currentLanguage,
          items: data.availableLanguages,
          dense: true,
          enabled: !data.isLoading,
          onChanged: onLanguageChanged,
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldDropdownRow(
          label: loc.odometer,
          value: data.currentOdometer,
          items: data.availableOdometerUnits,
          dense: true,
          enabled: !data.isLoading,
          onChanged: onOdometerChanged,
        ),
      ],
    );
  }
}
