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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: showingRecap ? 1 : 0,
        onTap: (index) {
          if (index == 0) {
            onAvailable();
          } else {
            onRecap();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppColors.navBarInactive,
        unselectedItemColor: AppColors.navBarInactive,
        selectedIconTheme: IconThemeData(
          color: showingRecap ? AppColors.navBarInactive : AppColors.textPrimaryFor(Theme.of(context).brightness),
        ),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: AppTypography.captionSize,
        unselectedFontSize: AppTypography.captionSize,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time),
            activeIcon: const Icon(Icons.access_time),
            label: context.loc.available,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate_outlined),
            label: context.loc.recap,
          ),
        ],
      ),
    );
  }
}
