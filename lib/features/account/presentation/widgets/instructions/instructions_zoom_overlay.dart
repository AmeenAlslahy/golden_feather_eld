import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// طبقة تكبير مقطع تعليمات:
/// - تفتح من أعلى المحتوى بتكبير فعلي (1.3) قابل للزيادة حتى 3.5 والتجول بالسحب.
/// - لمس المحتوى لا يغلقها؛ الإغلاق: الزر الصريح، أو الرجوع، أو لمس الفراغ.
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

class _InstructionsZoomOverlayState extends State<InstructionsZoomOverlay> {
  static const double _initialScale = 1.3;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.5;

  late final TransformationController _transformation =
      TransformationController(
    Matrix4.diagonal3Values(_initialScale, _initialScale, 1),
  );

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    final contentWidth = context.screenWidth - AppSpacing.md * 2;

    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: AppColors.scrim),
        ),
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: contentWidth,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: IconButton(
            key: const Key('instructions_zoom_close'),
            tooltip: closeTooltip,
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
