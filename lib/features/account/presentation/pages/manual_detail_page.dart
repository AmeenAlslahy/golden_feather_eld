import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';

/// صفحة تفاصيل الدليل/التعليمات
class ManualDetailPage extends StatelessWidget {
  final String title;
  final List<ManualSection> content;

  const ManualDetailPage(
      {super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: context.styles.appBarTitle,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: content.length,
        itemBuilder: (context, index) {
          final section = content[index];
          return _buildSection(context, section);
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, ManualSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: EldCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    section.title!,
                    style: context.styles.sectionTitle.copyWith(
                      color: AppColors.goldFor(Theme.of(context).brightness),
                    ),
                  ),
                ),
              ...section.steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.isNumbered)
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryGold.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${section.steps.indexOf(step) + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryGold,
                                      fontWeight: AppTypography.bold)),
                            ),
                          ),
                        Expanded(
                            child: Text(step, style: context.styles.body)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class ManualSection {
  final String? title;
  final List<String> steps;
  final bool isNumbered;

  const ManualSection(
      {this.title, required this.steps, this.isNumbered = true});
}
