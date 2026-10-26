import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// تذييل ملاحظة معلوماتية موحدة — يظهر أسفل شاشات الإعدادات كالحساب والقواعد.
class EldFooterNotice extends StatelessWidget {
  final String message;
  final IconData icon;

  const EldFooterNotice({
    super.key,
    required this.message,
    this.icon = Icons.info,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: context.textSecondary, size: AppSpacing.iconSmall),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.styles.caption.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
