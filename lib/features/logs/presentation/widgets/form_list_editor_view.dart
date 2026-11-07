import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/golden_app_bar.dart';

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

  /// خطأ التحقق المرتبط بالحقل — يظهر أسفله مباشرة، لا كتنبيه منفصل.
  final String? errorText;

  /// تلميح الحقل الخاص بالميزة (مثل رقم المستند) بدل التلميح العام.
  final String? hintText;

  /// إبلاغ الصفحة بتغيّر النص لمسح الخطأ القديم عند بدء التصحيح.
  final ValueChanged<String>? onChanged;

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
    this.errorText,
    this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GoldenAppBar(titleText: title),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                // على الشاشات الضيقة أو مع تكبير النص، يوضع الزر تحت الحقل
                // بعرض كامل بدل حصاره في عمود ضيق يقطع «إضافة».
                final stack = constraints.maxWidth < 360 || scale > 1.3;

                Widget field() => AppTextField(
                  controller: controller,
                  hint: hintText ?? context.loc.typeHere,
                  errorText: errorText,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.text,
                  inputFormatters: inputFormatters,
                  onSubmitted: (_) => onAdd(),
                );

                Widget addButton({required bool fullWidth}) => AppButton(
                  label: context.loc.addButton,
                  icon: Icons.add,
                  type: EldButtonType.primary,
                  isFullWidth: fullWidth,
                  onPressed: onAdd,
                );

                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(),
                      const SizedBox(height: AppSpacing.sm),
                      addButton(fullWidth: true),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: field()),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(flex: 1, child: addButton(fullWidth: false)),
                  ],
                );
              },
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
