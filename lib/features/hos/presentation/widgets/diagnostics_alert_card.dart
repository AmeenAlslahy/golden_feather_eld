import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/diagnostics/diagnostics_engine.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/diagnostics_state_provider.dart';
import '../../../../core/extensions/context_extensions.dart';

class DiagnosticsAlertCard extends ConsumerWidget {
  const DiagnosticsAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(diagnosticsStateProvider);

    return stateAsync.when(
      data: (state) {
        if (!state.hasActiveMalfunctions || state.activeMalfunctions.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestAlert = state.activeMalfunctions.last;
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        final theme = Theme.of(context);

        Color getSeverityColor(MalfunctionSeverity severity) {
          switch (severity) {
            case MalfunctionSeverity.critical:
              return theme.dangerColor;
            case MalfunctionSeverity.major:
              return theme.warningColor;
            case MalfunctionSeverity.minor:
              return theme.infoColor;
          }
        }
        
        Color getSeverityBackgroundColor(MalfunctionSeverity severity) {
          switch (severity) {
            case MalfunctionSeverity.critical:
              return theme.errorLightBackground;
            case MalfunctionSeverity.major:
              return theme.warningLightBackground;
            case MalfunctionSeverity.minor:
              return theme.infoLightBackground;
          }
        }

        final color = getSeverityColor(latestAlert.severity);
        final bgColor = getSeverityBackgroundColor(latestAlert.severity);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: color, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.loc.malfunctionAlerts,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestAlert.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          ),
                    ),
                  ],
                ),
              ),
              if (state.activeMalfunctions.length > 1)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+${state.activeMalfunctions.length - 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
