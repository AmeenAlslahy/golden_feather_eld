import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../extensions/context_extensions.dart';

class EldDatePaginator extends StatelessWidget {
  const EldDatePaginator({
    super.key,
    required this.dateLabel,
    required this.canGoOlder,
    required this.canGoNewer,
    required this.onSelectOlder,
    required this.onSelectNewer,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  final String dateLabel;
  final bool canGoOlder;
  final bool canGoNewer;
  final VoidCallback onSelectOlder;
  final VoidCallback onSelectNewer;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? context.previewBand;
    final effectiveTextColor = textColor ?? AppColors.white;
    final effectiveIconColor = iconColor ?? AppColors.white;
    final disabledIconColor = effectiveIconColor.withValues(alpha: 0.38);

    final isOlderEnabled = !isLoading && canGoOlder;
    final isNewerEnabled = !isLoading && canGoNewer;

    return Container(
      color: effectiveBgColor,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).previousPageTooltip,
            icon: Icon(
              Icons.chevron_left,
              color: isOlderEnabled ? effectiveIconColor : disabledIconColor,
            ),
            onPressed: isOlderEnabled ? onSelectOlder : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    dateLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.styles.appBarTitle.copyWith(
                      color: effectiveTextColor,
                    ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: AppSpacing.iconSmallBadge,
                    height: AppSpacing.iconSmallBadge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).nextPageTooltip,
            icon: Icon(
              Icons.chevron_right,
              color: isNewerEnabled ? effectiveIconColor : disabledIconColor,
            ),
            onPressed: isNewerEnabled ? onSelectNewer : null,
          ),
        ],
      ),
    );
  }
}

