import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// شريط علوي موحّد — هوية واحدة لكل شاشات التطبيق.
///
/// **المشكلة:** 36 تكرار لـ `AppBar(` بإعدادات مختلفة.
/// **الحل:** مكوّن واحد بهوية واحدة + قابل للتخصيص.
///
/// **الوراثة:** يرث من AppBar عبر composition (has-a) لا تكرار.
class EldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const EldAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isLight ? AppColors.textPrimary : AppColors.darkTextPrimary,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: AppSpacing.sm),
            ]
          : null,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

/// شريط علوي مع تبويب — للصفحات التي تحتوي Tabs.
class EldTabAppBar extends EldAppBar {
  final TabBar tabBar;
  const EldTabAppBar({
    super.key,
    required super.title,
    required this.tabBar,
    super.actions,
    super.leading,
  }) : super(bottom: tabBar);
}
