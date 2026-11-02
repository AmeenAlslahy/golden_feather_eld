import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/utils/startup_profiler.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_mode_provider.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/forgot_password_form.dart';
import '../widgets/login_form.dart';

/// صفحة المصادقة الموحدة — Golden Feather Design System 2.0
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  @override
  void initState() {
    super.initState();
    StartupProfiler.markOnce('first-interactive-page:login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authMode = ref.watch(authModeProvider);
    final isError = authState.status == AuthStatus.error;
    final isLoading = authState.status == AuthStatus.loading;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // شعار التطبيق
                  const Center(
                    child: AppLogo(
                      customSize: 120,
                      cacheWidth: 360,
                      cacheHeight: 360,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.loc.appName,
                    textAlign: TextAlign.center,
                    style: context.styles.display,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.loc.appSlogan,
                    textAlign: TextAlign.center,
                    style: context.styles.secondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Authentication Error Banner
                  if (isError && !isLoading && authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.compact,
                      ),
                      decoration: BoxDecoration(
                        color: context.goldenColors.errorBackground,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: context.goldenColors.errorText.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.goldenColors.errorText,
                            size: AppSpacing.iconMedium,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              context.translateErrorKey(authState.errorMessage!),
                              style: context.styles.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Authentication Content with Smooth Transition
                  AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : AppAnimations.normal,
                    switchInCurve: AppAnimations.enterCurve,
                    switchOutCurve: AppAnimations.exitCurve,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(authMode),
                      child: _buildFormForMode(authMode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormForMode(AuthMode authMode) {
    switch (authMode) {
      case AuthMode.login:
        return const LoginForm();
      case AuthMode.forgotPassword:
        return const ForgotPasswordForm();
    }
  }
}
