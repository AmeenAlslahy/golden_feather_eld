import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Available يسار، Recap يمين — مطابق للقطة.
class EldBottomNav extends StatelessWidget {
  final bool showingRecap;
  final VoidCallback onRecap;
  final VoidCallback onAvailable;

  const EldBottomNav({
    super.key,
    required this.showingRecap,
    required this.onRecap,
    required this.onAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _NavSegment(
              icon: Icons.access_time,
              label: context.loc.available,
              isActive: !showingRecap,
              onTap: onAvailable,
            ),
          ),
          Expanded(
            child: _NavSegment(
              icon: Icons.calculate_outlined,
              label: context.loc.recap,
              isActive: showingRecap,
              onTap: onRecap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavSegment({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // بناءً على الهوية البصرية الموجودة:
    // الخلفية النشطة: رمادي داكن (مائل للأسود) أو حسب الـ Theme
    // الخلفية غير النشطة: رمادي فاتح جداً (مثل AppColors.border أو surface)
    final bgColor = isActive
        ? AppColors.textSecondary
        : Theme.of(context).colorScheme.surface;

    final fgColor = isActive
        ? AppColors
              .surface // أبيض
        : AppColors.textSecondary;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: context.styles.body.copyWith(
                color: fgColor,
                fontSize: AppTypography.captionSize,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
