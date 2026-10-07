import 'package:flutter/material.dart';
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
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveIconColor = iconColor ?? Colors.white;

    return Container(
      color: effectiveBgColor,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: effectiveIconColor),
            onPressed: (!isLoading && canGoOlder) ? onSelectOlder : null,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateLabel,
                style: context.styles.appBarTitle.copyWith(color: effectiveTextColor),
              ),
              if (isLoading) ...[
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: effectiveIconColor),
            onPressed: (!isLoading && canGoNewer) ? onSelectNewer : null,
          ),
        ],
      ),
    );
  }
}
