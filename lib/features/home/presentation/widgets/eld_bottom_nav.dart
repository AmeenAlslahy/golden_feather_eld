import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';

/// شريط التنقل السفلي
class EldBottomNav extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EldBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppColors.navBarActive,
        unselectedItemColor: AppColors.navBarInactive,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: AppTypography.captionSize,
        unselectedFontSize: AppTypography.smallSize,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time),
            activeIcon: const Icon(Icons.access_time_filled),
            label: context.loc.available,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate),
            label: context.loc.recap,
          ),
        ],
      ),
    );
  }
}



