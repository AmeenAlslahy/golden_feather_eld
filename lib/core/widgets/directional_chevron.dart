import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// أيقونة سهم الانتقال الموجهة تلقائياً للغة (Directional Chevron):
/// - في العربية (RTL): يشير السهم لليسار (باتجاه التقدم للأمام).
/// - في الإنجليزية (LTR): يشير السهم لليمين.
class DirectionalChevron extends StatelessWidget {
  final double size;
  final Color? color;

  const DirectionalChevron({
    super.key,
    this.size = AppSpacing.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? Icons.chevron_left : Icons.chevron_right,
      size: size,
      color: color ?? context.styles.subtitle.color,
    );
  }
}
