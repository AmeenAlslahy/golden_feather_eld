/// Switch Drivers Screen — allows co-drivers to swap roles.
///
/// **FMCSA §395.30:** Team drivers can switch driving/on-duty roles.
/// This creates a new duty status event for both drivers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/eld_app_bar.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';

class SwitchDriversPage extends ConsumerStatefulWidget {
  const SwitchDriversPage({super.key});

  @override
  ConsumerState<SwitchDriversPage> createState() => _SwitchDriversPageState();
}

class _SwitchDriversPageState extends ConsumerState<SwitchDriversPage> {
  bool _isSwitching = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final coDriverState = ref.watch(codriverProvider);
    final currentDriver = authState.user;
    final coDriver = coDriverState.selectedCoDriver;

    return Scaffold(
      appBar: EldAppBar(title: context.loc.switchDrivers ?? 'switchDrivers'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.primaryBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primaryBlue),
                    AppGap.hSm,
                    Expanded(
                      child: Text(
                        'Switch roles with your co-driver. This will create new duty status events for both drivers.',
                        style: AppTextStyles(context).body.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              AppGap.xl,

              // Current driver
              _buildDriverCard(
                context,
                title: 'Current Driver',
                name: currentDriver?.fullName ?? 'Unknown',
                role: 'Primary Driver',
                icon: Icons.person,
                color: AppColors.primaryBlue,
              ),

              AppGap.md,

              // Swap icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert_circle,
                    size: AppSpacing.iconSize * 2,
                    color: AppColors.warningYellow,
                  ),
                ),
              ),

              AppGap.md,

              // Co-driver
              if (coDriver != null)
                _buildDriverCard(
                  context,
                  title: 'Co-Driver',
                  name: coDriver.name,
                  role: 'Secondary Driver',
                  icon: Icons.person_outline,
                  color: AppColors.successGreen,
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.warningYellow),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: AppSpacing.iconSize * 2, color: AppColors.warningYellow),
                      AppGap.sm,
                      Text(
                        'No co-driver assigned',
                        style: AppTextStyles(context).pageTitle,
                      ),
                      AppGap.xs,
                      Text(
                        'Please assign a co-driver first from the Daily Form.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles(context).body,
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.dangerRed),
                        AppGap.hSm,
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles(context)
                                .body
                                .copyWith(color: AppColors.dangerRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Switch button
              ElevatedButton(
                onPressed: coDriver != null && !_isSwitching
                    ? () => _performSwitch(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningYellow,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  elevation: 0,
                ),
                child: _isSwitching
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                      )
                    : Text(
                        context.loc.switchDrivers ?? 'Switch Drivers',
                        style: AppTextStyles(context)
                            .buttonText
                            .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context, {
    required String title,
    required String name,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          AppGap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles(context).body.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: AppSpacing.xs * 3,
                      ),
                ),
                AppGap.xs,
                Text(
                  name,
                  style: AppTextStyles(context).pageTitle,
                ),
                Text(
                  role,
                  style: AppTextStyles(context).body.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSwitch(BuildContext context) async {
    setState(() {
      _isSwitching = true;
      _error = null;
    });

    try {
      final success = await ref.read(codriverProvider.notifier).switchDrivers();
      if (!mounted) return;
      if (success) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
            title: Text(context.loc.successMessage),
            content: const Text('Driver roles have been successfully switched. New duty status events have been created for both drivers.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: Text(context.loc.okButton),
              ),
            ],
          ),
        );
      } else {
        final err = ref.read(codriverProvider).error;
        setState(() {
          _error = err ?? context.loc.unexpectedError;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }
}
