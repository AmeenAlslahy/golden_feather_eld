import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/rules_form_provider.dart';
import '../providers/rules_screen_provider.dart';
import '../widgets/rules/rules_notice_banner.dart';
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
      appBar: AppBar(
        title: Text(loc.rules, style: context.styles.appBarTitle),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (model.notice.trim().isNotEmpty) ...[
                  RulesNoticeBanner(notice: model.notice),
                  const SizedBox(height: AppSpacing.cardGap),
                ],
                RulesSettingsSection(model: model),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: loc.saveButton,
                  type: EldButtonType.primary,
                  isLoading: form.isSaving,
                  onPressed: form.canSave
                      ? () => ref.read(rulesFormProvider.notifier).saveRules()
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info,
                      color: context.textSecondary,
                      size: AppSpacing.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        loc.contactFleetManager,
                        textAlign: TextAlign.center,
                        style: context.styles.caption.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
