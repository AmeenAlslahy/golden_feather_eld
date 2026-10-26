import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_typography.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// طبقة تكبير مقطع تعليمات:
/// - تفتح بتكبير 1.3 مع توسط أفقي محكم.
/// - تدعم التكبير والتصغير بأزرار تحكم عائمة (+ / - / ملائمة 100%).
/// - تدعم النقر المزدوج (Double-tap) للتبديل السلس بين ملائمة العرض والتكبير.
/// - تدعم السحب والتكبير باللمس (Pinch-to-zoom) مع حدود ارتدادية تمنع ضياع المحتوى.
/// - الإغلاق: زر الإغلاق الصريح، أو الرجوع، أو لمس الفراغ خارج البطاقة.
class InstructionsZoomOverlay extends StatefulWidget {
  const InstructionsZoomOverlay({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<InstructionsZoomOverlay> createState() =>
      _InstructionsZoomOverlayState();
}

class _InstructionsZoomOverlayState extends State<InstructionsZoomOverlay>
    with SingleTickerProviderStateMixin {
  static const double _initialScale = 1.3;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.5;

  late final TransformationController _transformation =
      TransformationController(
        Matrix4.diagonal3Values(_initialScale, _initialScale, 1),
      );

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  late final CurvedAnimation _curvedAnimation = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOutCubic,
  );

  late final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(
    _initialScale,
  );

  Animation<Matrix4>? _anim;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _transformation.addListener(_handleTransformChanged);
    _animController.addListener(_handleAnimTick);
  }

  void _handleAnimTick() {
    if (_anim != null) {
      _transformation.value = _anim!.value;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.sizeOf(context);
    if (_lastSize != currentSize) {
      _lastSize = currentSize;
      final screenWidth = currentSize.width;
      final contentWidth = screenWidth - AppSpacing.md * 2;
      // توسيط المحتوى أفقياً لكي لا ينقطع الطرف الأيمن أو الأيسر
      final totalScaledWidth =
          (contentWidth + AppSpacing.md * 2) * _initialScale;
      final dx = (screenWidth - totalScaledWidth) / 2;
      _transformation.value =
          Matrix4.translationValues(dx, 0.0, 0.0) *
          Matrix4.diagonal3Values(_initialScale, _initialScale, 1.0);
    }
  }

  void _handleTransformChanged() {
    final scale = _transformation.value.getMaxScaleOnAxis();
    if ((scale - _scaleNotifier.value).abs() > 0.01) {
      _scaleNotifier.value = scale;
    }
  }

  @override
  void dispose() {
    _transformation.removeListener(_handleTransformChanged);
    _transformation.dispose();
    _animController.removeListener(_handleAnimTick);
    _animController.dispose();
    _curvedAnimation.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  void _animateToMatrix(Matrix4 target) {
    _animController.stop();
    _anim = Matrix4Tween(
      begin: _transformation.value,
      end: target,
    ).animate(_curvedAnimation);
    _animController.forward(from: 0.0);
  }

  void _scaleTo(double targetScale) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth - AppSpacing.md * 2;
    final clamped = targetScale.clamp(_minScale, _maxScale);

    final Matrix4 target;
    if (clamped <= 1.02) {
      // ملائمة العرض 100%
      target = Matrix4.identity();
    } else {
      final totalScaledWidth = (contentWidth + AppSpacing.md * 2) * clamped;
      final dx = (screenWidth - totalScaledWidth) / 2;
      target =
          Matrix4.translationValues(dx, 0.0, 0.0) *
          Matrix4.diagonal3Values(clamped, clamped, 1.0);
    }

    _animateToMatrix(target);
  }

  void _zoomIn() {
    _scaleTo(_scaleNotifier.value + 0.35);
  }

  void _zoomOut() {
    _scaleTo(_scaleNotifier.value - 0.35);
  }

  void _resetToFit() {
    _scaleTo(1.0);
  }

  void _toggleFitOrZoom() {
    if (_scaleNotifier.value > 1.15) {
      _scaleTo(1.0);
    } else {
      _scaleTo(1.6);
    }
  }

  void _handleDoubleTap() {
    _toggleFitOrZoom();
  }

  @override
  Widget build(BuildContext context) {
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    final contentWidth = context.screenWidth - AppSpacing.md * 2;
    final theme = Theme.of(context);

    return Stack(
      children: [
        // 1. خلفية معتمة
        Positioned.fill(
          child: ColoredBox(
            color: context.colors.scrim.withValues(alpha: 0.85),
          ),
        ),

        // 2. المحتوى القابل للتكبير والتجول
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: _minScale,
              maxScale: _maxScale,
              constrained: false,
              alignment: Alignment.topCenter,
              boundaryMargin: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 120,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // منع إغلاق الطبقة عند النقر داخل المحتوى
                onDoubleTap: _handleDoubleTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Container(
                      width: contentWidth,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3. شريط التحكم العلوي العائم
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شريط أزرار التكبير والتصغير
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: theme.colorScheme.surface.withValues(alpha: 0.95),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ValueListenableBuilder<double>(
                        valueListenable: _scaleNotifier,
                        builder: (context, currentScale, _) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                tooltip: context.loc.zoomOut,
                                icon: const Icon(Icons.remove),
                                onPressed: currentScale <= _minScale
                                    ? null
                                    : _zoomOut,
                              ),
                              InkWell(
                                onTap: _toggleFitOrZoom,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.small,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '${(currentScale * 100).round()}%',
                                    style: context.styles.caption.copyWith(
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                tooltip: context.loc.zoomIn,
                                icon: const Icon(Icons.add),
                                onPressed: currentScale >= _maxScale
                                    ? null
                                    : _zoomIn,
                              ),
                              Container(
                                height: 16,
                                width: 1,
                                color: theme.dividerColor.withValues(
                                  alpha: 0.3,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                              ),
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                tooltip: context.loc.fitWidth,
                                icon: const Icon(Icons.fit_screen_outlined),
                                onPressed: _resetToFit,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // زر الإغلاق
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: theme.colorScheme.surface.withValues(alpha: 0.95),
                    child: IconButton(
                      key: const Key('instructions_zoom_close'),
                      tooltip: closeTooltip,
                      onPressed: widget.onDismiss,
                      icon: Icon(
                        Icons.close,
                        color: context.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
