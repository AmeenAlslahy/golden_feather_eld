import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

/// Navigation for the two HOS dashboard views.
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
      height: AppSpacing.navBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
    final background = isActive ? context.gold : context.colors.surface;
    final foreground = isActive ? context.onGold : context.textSecondary;

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: isActive,
          label: label,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: AppSpacing.iconMedium),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: context.styles.subtitle.copyWith(
                  color: foreground,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
