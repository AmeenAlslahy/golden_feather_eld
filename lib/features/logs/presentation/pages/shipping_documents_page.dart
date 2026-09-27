import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/daily_form_rules.dart';
import '../../../../core/widgets/app_feedback.dart';

class ShippingDocumentsPage extends ConsumerStatefulWidget {
  const ShippingDocumentsPage({super.key});

  @override
  ConsumerState<ShippingDocumentsPage> createState() =>
      _ShippingDocumentsPageState();
}

/// Edits the Form tab's shipping-document list (SRS 5.5–5.13). Backed by
/// `dashboardDataProvider` — the value the daily-form SAVE sends.
class _ShippingDocumentsPageState extends ConsumerState<ShippingDocumentsPage> {
  final _controller = TextEditingController();

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _documents =>
      splitFormList(ref.read(dashboardDataProvider).shippingDocuments);

  void _addDocument() {
    final text = _controller.text.trim();
    final error = shippingDocumentError(text, isArabic: _isArabic);
    if (error != null) {
      AppFeedback.error(context, error);
      return;
    }
    final current = _documents;
    if (current.contains(text)) {
      _controller.clear();
      return;
    }
    ref
        .read(dashboardDataProvider.notifier)
        .updateShippingDocuments([...current, text]);
    _controller.clear();
  }

  void _removeDocument(String doc) {
    ref
        .read(dashboardDataProvider.notifier)
        .updateShippingDocuments(_documents.where((d) => d != doc).toList());
  }

  @override
  Widget build(BuildContext context) {
    final docs =
        splitFormList(ref.watch(dashboardDataProvider).shippingDocuments);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.loc.shippingDocuments,
            style: context.styles.appBarTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ========== منطقة الإضافة ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _controller,
                    hint: _isArabic ? 'اكتب هنا' : 'Type here',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addDocument(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _addDocument,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            size: 18, color: AppColors.surface),
                        const SizedBox(width: 4),
                        Text(context.loc.addButton,
                            style: const TextStyle(color: AppColors.surface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // ========== قائمة الوثائق ==========
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Text(
                      _isArabic ? 'لا توجد مستندات' : 'No documents added',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  )
                : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        leading: const Icon(
                          Icons.description,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        title: Text(
                          doc,
                          style: context.styles.sectionTitle,
                        ),
                        trailing: TextButton(
                          onPressed: () => _removeDocument(doc),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: Text(
                            _isArabic ? 'حذف' : 'DELETE',
                            style: const TextStyle(
                              fontSize: AppTypography.smallSize,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
