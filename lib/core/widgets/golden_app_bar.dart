import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_styles.dart';
import '../theme/golden_colors.dart';

/// أنماط شريط التطبيق الموحد [GoldenAppBar]
enum GoldenAppBarVariant {
  /// النمط الذهبي البارز — يستخدم تدرج الهوية الذهبي مع نصوص وأيقونات داكنة واضحة
  brand,

  /// النمط المحايد القياسي — يستخدم سطح الثيم النشط للصفحات ذات البيانات الكثيفة
  standard,
}

/// شريط تطبيق موحد ومركزي وفق نظام Golden Feather Design System 2.0.
///
/// يدعم نمطين بصريين:
/// - [GoldenAppBarVariant.brand]: تدرج ذهبي رسمي (#A68422 -> #D4AF37 -> #E8CC73)
///   مع ضمان تباين عالٍ بنصوص داكنة وأيقونات شريط نظام داكنة.
/// - [GoldenAppBarVariant.standard]: سطح متناسق مع خلفية الثيم النشط.
///
/// يلتزم بالسلوكيات المشتركة:
/// - دعم العناوين الطويلة دون اقتطاع صامت (Tooltip + MaxLines: 2 + Accessible Semantics)
/// - دعم التنقل الاتجاهي الكامل (RTL للعربية و LTR للإنجليزية والإسبانية)
/// - استجابة دقيقة لسطوع شريط الحالة [SystemUiOverlayStyle]
class GoldenAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// العنوان كعنصر مخصص
  final Widget? title;

  /// العنوان كنص مباشر — يدعم تلقائياً التلميح وسهولة الوصول للعناوين الطويلة
  final String? titleText;

  /// النمط البصري لشريط التطبيق
  final GoldenAppBarVariant variant;

  /// العنصر البادئ المخصص (أيقونة العودة، القائمة، الإغلاق...)
  final Widget? leading;

  /// إظهار زر العودة تلقائياً عند إمكانية الرجوع
  final bool automaticallyImplyLeading;

  /// قائمة الإجراءات في الطرف الآخر
  final List<Widget>? actions;

  /// التوسيط البصري للعنوان
  final bool centerTitle;

  /// ارتفاع شريط الأدوات (الافتراضي 56.0)
  final double? toolbarHeight;

  /// عنصر سفلي مثل التبويبات [TabBar]
  final PreferredSizeWidget? bottom;

  /// الظل أو الارتفاع (الافتراضي 0)
  final double elevation;

  /// نمط مخصص لأيقونات النظام (إن أردت تجاوزه)
  final SystemUiOverlayStyle? systemOverlayStyle;

  const GoldenAppBar({
    super.key,
    this.title,
    this.titleText,
    this.variant = GoldenAppBarVariant.standard,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
    this.toolbarHeight,
    this.bottom,
    this.elevation = 0,
    this.systemOverlayStyle,
  }) : assert(
         title != null || titleText != null,
         'Either title or titleText must be provided',
       );

  /// مُنشئ سريع لشريط التطبيق بنمط الهوية الذهبي
  const GoldenAppBar.brand({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
    this.toolbarHeight,
    this.bottom,
    this.elevation = 0,
    this.systemOverlayStyle,
  }) : variant = GoldenAppBarVariant.brand,
       assert(
         title != null || titleText != null,
         'Either title or titleText must be provided',
       );

  /// مُنشئ سريع لشريط التطبيق بالنمط المحايد المتناسق مع السطح
  const GoldenAppBar.standard({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
    this.toolbarHeight,
    this.bottom,
    this.elevation = 0,
    this.systemOverlayStyle,
  }) : variant = GoldenAppBarVariant.standard,
       assert(
         title != null || titleText != null,
         'Either title or titleText must be provided',
       );

  @override
  Size get preferredSize {
    final height = toolbarHeight ?? kToolbarHeight;
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (isDark ? GoldenColors.dark : GoldenColors.light);

    final isBrand = variant == GoldenAppBarVariant.brand;

    // ألوان المقدمة والنصوص:
    // في النمط الذهبي: دائماً لون داكن فاحم (#0D0D0D) لتحقيق تباين ممتاز على الذهبي الفاتح
    // في النمط المحايد: مستمد من لون السطح في الثيم النشط
    final Color foregroundColor = isBrand
        ? AppColors.brandBlack
        : theme.colorScheme.onSurface;

    // نمط شريط النظام:
    // على التدرج الذهبي: يجب أن تكون أيقونات شريط الحالة داكنة دائماً
    // على السطح المحايد: تتغير تلقائياً حسب الفاتح والداكن
    final effectiveOverlayStyle =
        systemOverlayStyle ??
        (isBrand
            ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
            : SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ));

    // خلفية الشريط: تدرج ذهبي للهوية أو لون السطح للنمط المحايد
    final Widget? backgroundWidget = isBrand
        ? Container(
            decoration: BoxDecoration(
              gradient: goldenColors.brandGradient,
            ),
          )
        : null;

    final Color backgroundColor = isBrand
        ? Colors.transparent
        : theme.colorScheme.surface;

    // بناء عنصر العنوان مع معالجة العناوين الطويلة
    final titleTextStyle = (theme.extension<AppStyles>()?.appBarTitle ??
            theme.textTheme.titleMedium ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        .copyWith(
          color: foregroundColor,
          letterSpacing: -0.2,
        );

    final Widget effectiveTitle = _buildTitle(
      context: context,
      style: titleTextStyle,
      foregroundColor: foregroundColor,
    );

    // بناء الزر البادئ مع احترام الاتجاه
    final Widget? effectiveLeading = _buildLeading(
      context: context,
      foregroundColor: foregroundColor,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effectiveOverlayStyle,
      child: AppBar(
        title: effectiveTitle,
        centerTitle: centerTitle,
        leading: effectiveLeading,
        automaticallyImplyLeading: false,
        actions: actions != null ? _wrapActions(actions!, foregroundColor) : null,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        toolbarHeight: toolbarHeight ?? kToolbarHeight,
        bottom: bottom,
        flexibleSpace: backgroundWidget,
        iconTheme: IconThemeData(
          color: foregroundColor,
          size: AppSizing.iconMedium,
        ),
        actionsIconTheme: IconThemeData(
          color: foregroundColor,
          size: AppSizing.iconMedium,
        ),
      ),
    );
  }

  Widget _buildTitle({
    required BuildContext context,
    required TextStyle style,
    required Color foregroundColor,
  }) {
    if (title != null) {
      return DefaultTextStyle(
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        child: title!,
      );
    }

    final text = titleText ?? '';
    return Tooltip(
      message: text,
      child: Semantics(
        header: true,
        label: text,
        child: Text(
          text,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
  }

  Widget? _buildLeading({
    required BuildContext context,
    required Color foregroundColor,
  }) {
    if (leading != null) return leading;

    if (!automaticallyImplyLeading) return null;

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;

    if (canPop) {
      final isFullscreenDialog =
          parentRoute is PageRoute && parentRoute.fullscreenDialog;
      if (isFullscreenDialog) {
        return CloseButton(
          color: foregroundColor,
          onPressed: () => Navigator.maybePop(context),
        );
      }
      return BackButton(
        color: foregroundColor,
        onPressed: () => Navigator.maybePop(context),
      );
    }

    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold?.hasDrawer ?? false) {
      return IconButton(
        icon: Icon(Icons.menu, color: foregroundColor, size: AppSizing.iconMedium),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: () => scaffold?.openDrawer(),
      );
    }

    return null;
  }

  List<Widget> _wrapActions(List<Widget> rawActions, Color foregroundColor) {
    if (rawActions.isEmpty) return rawActions;

    return [
      for (final action in rawActions)
        IconTheme(
          data: IconThemeData(
            color: foregroundColor,
            size: AppSizing.iconMedium,
          ),
          child: action,
        ),
      const SizedBox(width: AppSpacing.xs),
    ];
  }
}
