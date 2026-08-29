import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import 'app_button.dart';

/// عرض خطأ موحد
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? arabicMessage;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.arabicMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayMessage = isArabic ? (arabicMessage ?? message) : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: context.loc.retryButton,
                type: EldButtonType.continueDisconnected,
                isFullWidth: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


