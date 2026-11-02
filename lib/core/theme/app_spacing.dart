import 'app_sizing.dart';

/// المسافات حسب دليل التصميم
class AppSpacing {
  AppSpacing._();

  // =========================================================================
  // نظام المسافات الأساسي (Base Grid) — Golden Feather 2.0
  // =========================================================================

  static const double space0 = 0.0;
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;

  // =========================================================================
  // المسافات الدلالية (Semantic Spacings)
  // =========================================================================

  static const double screenHorizontal = 16.0;
  static const double screenVertical = 16.0;
  static const double fieldGap = 16.0;
  static const double labelToField = 8.0;
  static const double titleToContent = 12.0;
  static const double buttonGroupGap = 12.0;
  static const double feedbackPadding = 16.0;
  static const double emptyStateMaxWidth = 360.0;

  // =========================================================================
  // ثوابت التوافق السابقة (Legacy Spacings)
  // =========================================================================

  /// المسافات الأساسية
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double compact = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  /// مسافات محددة
  static const double screenPadding = 16.0; // padding يمين ويسار
  static const double cardPadding = 16.0;
  static const double cardGap = 12.0;
  static const double legacyCardGap = 16.0;
  static const double sectionGap = 24.0;
  static const double rowVertical = 12.0;
  static const double rowVerticalCompact = 8.0;
  static const double rowHorizontal = 16.0;

  /// الارتفاع القديم لحقول الإدخال — محال للاستخدام المركزي عبر [AppSizing.inputHeight].
  @Deprecated('Use AppSizing.inputHeight (52.0) instead.')
  static const double inputHeight = AppSizing.inputHeight;
  static const double buttonHeight = 52.0;
  static const double secondaryButtonHeight = 48.0;
  static const double minTouchTarget = 48.0;
  static const double dialogPadding = 24.0;
  static const double navBarHeight = 60.0;
  static const double dividerHeight = 1.0; // سمك الفاصل
  static const double iconBullet = 6.0;
  static const double iconDot = 8.0;
  static const double iconSmallBadge = 14.0;
  static const double iconSize = 24.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 28.0;
  static const double iconXLarge = 32.0;
  static const double iconHero = 48.0;
  static const double iconFeature = 64.0;
  static const double iconHeroLarge = 72.0;
}
