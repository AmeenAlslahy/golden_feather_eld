import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';

/// مزود قائمة وثائق الشحن
final shippingDocsProvider = StateNotifierProvider<ShippingDocsNotifier, List<String>>((ref) {
  return ShippingDocsNotifier();
});

class ShippingDocsNotifier extends StateNotifier<List<String>> {
  ShippingDocsNotifier() : super(['BOL-2024-001']); // افتراضية

  void add(String doc) {
    if (doc.isNotEmpty && !state.contains(doc)) {
      state = [...state, doc];
    }
  }

  void remove(String doc) {
    state = state.where((d) => d != doc).toList();
  }
}

/// شاشة وثائق الشحن
class ShippingDocumentsPage extends ConsumerStatefulWidget {
  const ShippingDocumentsPage({super.key});

  @override
  ConsumerState<ShippingDocumentsPage> createState() => _ShippingDocumentsPageState();
}

class _ShippingDocumentsPageState extends ConsumerState<ShippingDocumentsPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addDocument() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(shippingDocsProvider.notifier).add(text);
      _controller.clear();
    }
  }

  void _removeDocument(String doc) {
    ref.read(shippingDocsProvider.notifier).remove(doc);
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(shippingDocsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shipping Documents',
          style: TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
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
                    hint: 'Type here',
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
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18, color: AppColors.surface),
                        const SizedBox(width: 4),
                        Text(context.loc.addButton, style: const TextStyle(color: AppColors.surface)),
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
                      'No documents added',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
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
                          style: const TextStyle(
                            fontSize: AppTypography.bodySize,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => _removeDocument(doc),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: const Text(
                            'DELETE',
                            style: TextStyle(
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
