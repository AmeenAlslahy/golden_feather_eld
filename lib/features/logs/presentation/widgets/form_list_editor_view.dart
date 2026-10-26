import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// ودجت عام وموحد لإدارة قوائم النماذج اليومية (مثل المقطورات ووثائق الشحن).
class FormListEditorView extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final IconData itemIcon;
  final List<String> items;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const FormListEditorView({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.itemIcon,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(title)),
      body: Column(
        children: [
          // ========== منطقة الإدخال ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: controller,
                    hint: context.loc.typeHere,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
                    inputFormatters: inputFormatters,
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  flex: 1,
                  child: AppButton(
                    label: context.loc.addButton,
                    icon: Icons.add,
                    type: EldButtonType.primary,
                    isFullWidth: false,
                    onPressed: onAdd,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.border),
          // ========== قائمة العناصر ==========
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(emptyMessage, style: context.styles.subtitle),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: context.border),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        leading: Icon(
                          itemIcon,
                          color: context.textSecondary,
                          size: AppSpacing.iconLarge,
                        ),
                        title: Text(item, style: context.styles.sectionTitle),
                        trailing: TextButton.icon(
                          onPressed: () => onRemove(item),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: AppSpacing.iconSmall,
                          ),
                          label: Text(context.loc.deleteButton),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colorScheme.error,
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
