import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/widgets/eld_footer_notice.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/account_provider.dart';
import '../providers/account_ui_state.dart';
import '../widgets/account/account_details_section.dart';

/// شاشة معلومات الحساب — معمارية نظيفة تفصل التصميم عن المنطق وإدارة الحالة.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountProvider.notifier).fetchMyAccount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(accountUiStateProvider);
    final notifier = ref.read(accountProvider.notifier);
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.account, style: context.styles.appBarTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          uiState.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: AppSpacing.iconMedium,
                      height: AppSpacing.iconMedium,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => notifier.fetchMyAccount(),
                ),
        ],
      ),
      drawer: const EldDrawer(),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchMyAccount(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (uiState.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    context.translateErrorKey(uiState.error!),
                    style: context.styles.error,
                    textAlign: TextAlign.center,
                  ),
                ),
              AccountDetailsSection(
                data: uiState,
                onLanguageChanged: (val) {
                  if (val != null) notifier.changeLanguage(val);
                },
                onOdometerChanged: (val) {
                  if (val != null) notifier.changeOdometer(val);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              EldFooterNotice(
                message: uiState.notice.isNotEmpty
                    ? uiState.notice
                    : loc.pleaseContactYourFleetManagerTo,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
