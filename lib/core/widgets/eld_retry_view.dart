import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// Empty/error placeholder: short message + circular retry.
class EldRetryView extends StatelessWidget {
  const EldRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.isError = true,
  });

  final String message;
  final VoidCallback onRetry;

  /// Failures read in the error colour; empty states (`isError: false`)
  /// stay in the neutral body colour.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: isError ? context.styles.error : context.styles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            IconButton(
              tooltip: context.loc.retryButton,
              iconSize: 40,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
