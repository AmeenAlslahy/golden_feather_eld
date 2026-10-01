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

/// شاشة المقطورات
class TrailersPage extends ConsumerStatefulWidget {
  const TrailersPage({super.key});

  @override
  ConsumerState<TrailersPage> createState() => _TrailersPageState();
}

/// Edits the Form tab's trailer list (SRS 5.5–5.13). The list lives on
/// `dashboardDataProvider` — the same value the daily-form SAVE sends — so
/// there is no second copy and nothing is invented.
class _TrailersPageState extends ConsumerState<TrailersPage> {
  final _controller = TextEditingController();


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _trailers =>
      splitFormList(ref.read(dashboardDataProvider).trailerId);

  void _addTrailer() {
    final text = _controller.text.trim();
    final error = trailerNumberError(text, context.loc);
    if (error != null) {
      AppFeedback.error(context, error);
      return;
    }
    final current = _trailers;
    if (current.contains(text)) {
      _controller.clear();
      return;
    }
    ref
        .read(dashboardDataProvider.notifier)
        .updateTrailers([...current, text]);
    _controller.clear();
  }

  void _removeTrailer(String trailer) {
    ref
        .read(dashboardDataProvider.notifier)
        .updateTrailers(_trailers.where((t) => t != trailer).toList());
  }

  @override
  Widget build(BuildContext context) {
    final trailers = splitFormList(ref.watch(dashboardDataProvider).trailerId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.loc.trailers, style: context.styles.appBarTitle),
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
                    hint: context.loc.typeHere,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTrailer(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _addTrailer,
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
                            style: context.styles.button),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // ========== قائمة المقطورات ==========
          Expanded(
            child: trailers.isEmpty
                ? Center(
                    child: Text(
                      context.loc.noTrailersAdded,
                      style: context.styles.subtitle,
                    ),
                  )
                : ListView.separated(
                    itemCount: trailers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final trailer = trailers[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        leading:  Icon(
                          Icons.local_shipping,
                          color: context.styles.subtitle.color,
                          size: 28,
                        ),
                        title: Text(
                          trailer,
                          style: context.styles.sectionTitle,
                        ),
                        trailing: TextButton(
                          onPressed: () => _removeTrailer(trailer),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: Text(
                            context.loc.deleteButton,
                            style: context.styles.button
                                .copyWith(fontSize: AppTypography.smallSize),
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
