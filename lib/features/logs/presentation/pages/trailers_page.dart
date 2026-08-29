import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
// import '../../../../l10n/app_localizations.dart';

/// مزود قائمة المقطورات
final trailersProvider = StateNotifierProvider<TrailersNotifier, List<String>>((ref) {
  return TrailersNotifier();
});

class TrailersNotifier extends StateNotifier<List<String>> {
  TrailersNotifier() : super(['1402']); // افتراضية

  void add(String trailer) {
    if (trailer.isNotEmpty && !state.contains(trailer)) {
      state = [...state, trailer];
    }
  }

  void remove(String trailer) {
    state = state.where((t) => t != trailer).toList();
  }
}

/// شاشة المقطورات
class TrailersPage extends ConsumerStatefulWidget {
  const TrailersPage({super.key});

  @override
  ConsumerState<TrailersPage> createState() => _TrailersPageState();
}

class _TrailersPageState extends ConsumerState<TrailersPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTrailer() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(trailersProvider.notifier).add(text);
      _controller.clear();
    }
  }

  void _removeTrailer(String trailer) {
    ref.read(trailersProvider.notifier).remove(trailer);
  }

  @override
  Widget build(BuildContext context) {
    final trailers = ref.watch(trailersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trailers',
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
                    onSubmitted: (_) => _addTrailer(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _addTrailer,
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
          // ========== قائمة المقطورات ==========
          Expanded(
            child: trailers.isEmpty
                ? Center(
                    child: Text(
                      'No trailers added',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
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
                        leading: const Icon(
                          Icons.local_shipping,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        title: Text(
                          trailer,
                          style: const TextStyle(
                            fontSize: AppTypography.bodySize,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => _removeTrailer(trailer),
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
