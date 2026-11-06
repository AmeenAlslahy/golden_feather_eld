import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/eld_footer_notice.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import 'package:golden_feather_eld/routes/app_routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/rules_form_provider.dart';
import '../providers/rules_screen_provider.dart';
import '../widgets/rules/rules_settings_section.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesScreenAsync = ref.watch(rulesScreenProvider);
    final form = ref.watch(rulesFormProvider);
    final loc = context.loc;

    ref.listen<SaveRulesOutcome?>(
      rulesFormProvider.select((s) => s.lastOutcome),
      (previous, outcome) {
        if (outcome == null) return;
        switch (outcome) {
          case SaveRulesSuccess():
            AppFeedback.success(context, loc.rulesUpdated);
          case SaveRulesSessionExpired():
            AppFeedback.error(context, loc.sessionExpired);
            context.go(AppRoutes.login);
          case SaveRulesSixteenHourIneligible():
            AppFeedback.error(context, loc.sixteenHourCondition);
          case SaveRulesError(:final error):
            AppFeedback.error(context, anyErrorUserMessage(error, loc: loc));
        }
      },
    );

    return Scaffold(
      appBar: GoldenAppBar(
        titleText: loc.rules,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: rulesScreenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EldRetryView(
          message: anyErrorUserMessage(err, loc: loc),
          onRetry: () {
            if (err is SessionExpiredError) {
              context.go(AppRoutes.login);
            } else {
              ref.invalidate(rulesScreenProvider);
            }
          },
        ),
        data: (model) {
          final noticeText = model.notice.trim().isNotEmpty
              ? model.notice
              : loc.contactFleetManager;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RulesSettingsSection(model: model, dense: true),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: AppButton(
                    label: loc.saveButton,
                    type: EldButtonType.primary,
                    isLoading: form.isSaving,
                    onPressed: form.canSave
                        ? () => ref.read(rulesFormProvider.notifier).saveRules()
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                EldFooterNotice(message: noticeText),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }
}
