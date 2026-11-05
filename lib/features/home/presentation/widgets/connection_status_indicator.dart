import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities/connection_status.dart' as entity;
import '../../../../core/widgets/connection_status_indicator.dart' as core;
import '../../../../routes.dart';

/// مغلّف لمؤشر حالة الاتصال في الشاشة الرئيسية مع ربطه بالتنقل الافتراضي.
class ConnectionStatusIndicator extends StatelessWidget {
  final bool showWarningTriangle;
  final VoidCallback? onTap;
  final entity.ConnectionStatus? statusOverride;

  const ConnectionStatusIndicator({
    super.key,
    this.showWarningTriangle = true,
    this.onTap,
    this.statusOverride,
  });

  @override
  Widget build(BuildContext context) {
    return core.ConnectionStatusIndicator(
      showWarningTriangle: showWarningTriangle,
      onTap: onTap ?? () => context.push(AppRoutes.connection),
      statusOverride: statusOverride,
    );
  }
}
