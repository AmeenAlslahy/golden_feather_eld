import 'package:flutter/material.dart';

import '../theme/app_sizing.dart';

/// مقاسات الشعار القياسية بحسب دليل التصميم
enum AppLogoSize {
  /// مقاس صغير (أشرطة العناوين): 40px
  small,

  /// مقاس متوسط (رأس القائمة الجانبية): 88px
  medium,

  /// مقاس كبير (شاشات تسجيل الدخول والترحيب): 104px
  large,
}

/// مكوّن شعار Golden Feather الموحد (Design System 2.0).
///
/// يعرض صورة الشعار الأصلية المحفوظة بدقة عالية مع الحفاظ الكامل على خلفيتها السوداء،
/// ونسبة الأبعاد، واستخدام [BoxFit.contain] مع مقاسات قياسية من [AppSizing].
class AppLogo extends StatelessWidget {
  /// مسار ملف الشعار الأصلي
  static const String assetPath = 'assets/images/ic_launcher.png';

  final AppLogoSize size;
  final double? customSize;
  final String? semanticLabel;
  final int? cacheWidth;
  final int? cacheHeight;

  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.customSize,
    this.semanticLabel = 'Golden Feather ELD Logo',
    this.cacheWidth,
    this.cacheHeight,
  });

  /// مُنشئ سريع للشعار الصغير (40px)
  const AppLogo.small({
    super.key,
    this.semanticLabel = 'Golden Feather ELD Logo',
  })  : size = AppLogoSize.small,
        customSize = null,
        cacheWidth = null,
        cacheHeight = null;

  /// مُنشئ سريع للشعار المتوسط (88px)
  const AppLogo.medium({
    super.key,
    this.semanticLabel = 'Golden Feather ELD Logo',
  })  : size = AppLogoSize.medium,
        customSize = null,
        cacheWidth = null,
        cacheHeight = null;

  /// مُنشئ سريع للشعار الكبير (104px)
  const AppLogo.large({
    super.key,
    this.semanticLabel = 'Golden Feather ELD Logo',
  })  : size = AppLogoSize.large,
        customSize = null,
        cacheWidth = null,
        cacheHeight = null;

  /// حساب البعد الفعلي للشعار
  double get effectiveSize {
    if (customSize != null) return customSize!;
    return switch (size) {
      AppLogoSize.small => AppSizing.logoSmall,
      AppLogoSize.medium => AppSizing.logoMedium,
      AppLogoSize.large => AppSizing.logoLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimension = effectiveSize;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Image.asset(
            assetPath,
            width: dimension,
            height: dimension,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            fit: BoxFit.contain,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
