import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// بطاقة بيانات ELD - خلفية بيضاء مع ظل خفيف
class EldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const EldCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      elevation: 0.5,
      shadowColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );
  }
}
