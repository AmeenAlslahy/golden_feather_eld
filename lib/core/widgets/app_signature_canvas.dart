import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// A reusable, theme-aware signature pad used across the driver app.
///
/// Draws on a white background with a primary-coloured pen, shows a
/// localised placeholder when empty, and provides a "Clear" link below
/// the pad. All values adapt to the active [ThemeData] automatically.
///
/// Usage:
/// ```dart
/// AppSignatureCanvas(
///   controller: _signatureController,
/// )
/// ```
class AppSignatureCanvas extends StatelessWidget {
  /// The [SignatureController] that stores and controls the drawn strokes.
  final SignatureController controller;

  /// Optional override for the placeholder text shown when the pad is empty.
  /// Defaults to [AppLocalizations.drawYourSignatureHere].
  final String? placeholder;

  /// Height of the drawing area in logical pixels. Defaults to 200.
  final double height;

  /// Whether to show the "Clear" link below the pad. Defaults to true.
  final bool showClear;

  /// Optional padding around the entire widget.
  final EdgeInsets padding;

  const AppSignatureCanvas({
    super.key,
    required this.controller,
    this.placeholder,
    this.height = 200,
    this.showClear = true,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = context.loc;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Drawing area ───────────────────────────────────────────
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                children: [
                  // Placeholder — hidden once the driver starts drawing.
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      if (controller.isNotEmpty) return const SizedBox.shrink();
                      return Center(
                        child: Text(
                          placeholder ?? loc.drawYourSignatureHere,
                          textAlign: TextAlign.center,
                          style: context.styles.subtitle.copyWith(fontSize: 16),
                        ),
                      );
                    },
                  ),
                  // Signature pad — always on top so it captures all touches.
                  Signature(
                    controller: controller,
                    height: height,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),

          // ─── Clear button ────────────────────────────────────────────
          if (showClear) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: InkWell(
                onTap: () => controller.clear(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  child: Text(
                    loc.clearSignature,
                    style: context.styles.subtitle.copyWith(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
