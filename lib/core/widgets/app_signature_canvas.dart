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

  /// Optional error text to display below the canvas.
  final String? errorText;

  const AppSignatureCanvas({
    super.key,
    required this.controller,
    this.placeholder,
    this.height = 200,
    this.showClear = true,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.errorText,
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
                color: errorText != null 
                    ? colorScheme.error 
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: errorText != null ? 2 : 1,
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

          // ─── Footer (Error Message & Clear Button) ────────────────
          if (showClear || errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: errorText != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6.0, left: 8.0, right: 8.0),
                          child: Text(
                            errorText!,
                            style: context.styles.error.copyWith(fontSize: 12),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (showClear)
                  InkWell(
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
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A [FormField] wrapper for [AppSignatureCanvas] to integrate seamlessly with
/// Flutter's [Form] validation.
class AppSignatureFormField extends FormField<bool> {
  AppSignatureFormField({
    super.key,
    required SignatureController controller,
    String? placeholder,
    double height = 200,
    bool showClear = true,
    EdgeInsets padding = const EdgeInsets.all(AppSpacing.xl),
    super.onSaved,
    super.validator,
  }) : super(
          initialValue: controller.isNotEmpty,
          builder: (FormFieldState<bool> field) {
            // Re-evaluate whenever the controller changes so validation clears instantly
            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                // Update internal field state silently so validators run correctly
                // Check if changed to avoid unnecessary cycles, though ListenableBuilder manages this well.
                if (field.value != controller.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    field.didChange(controller.isNotEmpty);
                  });
                }
                
                return AppSignatureCanvas(
                  controller: controller,
                  placeholder: placeholder,
                  height: height,
                  showClear: showClear,
                  padding: padding,
                  errorText: field.errorText,
                );
              },
            );
          },
        );
}
