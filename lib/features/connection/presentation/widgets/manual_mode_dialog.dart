import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/app_text_field.dart';

class ManualModeDialog extends ConsumerStatefulWidget {
  const ManualModeDialog({super.key});

  @override
  ConsumerState<ManualModeDialog> createState() => _ManualModeDialogState();
}

class _ManualModeDialogState extends ConsumerState<ManualModeDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backend = ref.read(hardwareBackendProvider);
      final result = await backend.setManualMode(enable: true, reason: reason);
      
      if (mounted) {
        result.fold(
          (error) => setState(() {
            _errorMessage = error.l10nKey;
            _isLoading = false;
          }),
          (_) => Navigator.of(context).pop(true), // إرجاع true عند النجاح
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    final titleText = context.loc.switchToManualMode;
    final descText = context.loc.accordingToFmcsa39534;
    final hintText = context.loc.reasonForManualMode;
    final cancelText = context.loc.cancelButton;
    final confirmText = context.loc.confirmTitle;
    final emptyErrorText = context.loc.pleaseProvideAReason;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      titlePadding: const EdgeInsets.all(AppSpacing.lg),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      actionsPadding: const EdgeInsets.all(AppSpacing.lg),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningYellow.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber, color: AppColors.warningYellow, size: 28),
          ),
          AppGap.hMd,
          Expanded(
            child: Text(
              titleText,
              style: const TextStyle(
                fontSize: AppTypography.titleSize,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              descText,
              style: const TextStyle(
                fontSize: AppTypography.bodySize,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppGap.md,
          AppTextField(
            controller: _reasonController,
            hint: hintText,
            maxLines: 3,
            isUnderlined: false,
          ),
          if (_errorMessage != null) ...[
            AppGap.sm,
            Row(
              children: [
                const Icon(Icons.error, color: AppColors.dangerRed, size: 16),
                AppGap.hXs,
                Expanded(
                  child: Text(
                    _errorMessage == 'Please provide a reason' ? emptyErrorText : _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.dangerRed,
                      fontSize: AppTypography.captionSize,
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
          child: Text(cancelText, style: const TextStyle(color: AppColors.textSecondary, fontWeight: AppTypography.semiBold)),
        ),
        ElevatedButton(
          onPressed: _isLoading 
            ? null 
            : () {
                if (_reasonController.text.trim().isEmpty) {
                  setState(() => _errorMessage = emptyErrorText);
                  return;
                }
                _submit();
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerRed,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
          ),
          child: _isLoading 
            ? const SizedBox(width: AppSpacing.loaderSize, height: AppSpacing.loaderSize, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
            : Text(confirmText, style: const TextStyle(fontWeight: AppTypography.bold)),
        ),
      ],
    );
  }
}