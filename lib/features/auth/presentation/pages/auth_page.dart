import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localization_helper.dart';
import '../providers/auth_state_provider.dart';
import '../providers/auth_mode_provider.dart';
import '../widgets/login_form.dart';
import '../widgets/forgot_password_form.dart';

/// صفحة المصادقة الموحدة
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authMode = ref.watch(authModeProvider);
    final isError = authState.status == AuthStatus.error;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // شعار التطبيق
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/ic_launcher.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // اسم التطبيق
                  Text(
                    context.loc.appName,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // شعار التطبيق (الوصف)
                  Text(
                    context.loc.appSlogan,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // رسالة الخطأ (إن وجدت) في الأعلى لرؤية أفضل
                  if (isError && !isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (authState.errorMessage != null)
                            Expanded(
                              child: Text(
                                context
                                    .translateErrorKey(authState.errorMessage!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      height: 1.3,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // مؤشر التحميل أثناء معالجة الطلب
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // التبديل بين النماذج مع انتقال سلس
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
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
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Server Configuration',
                onPressed: () => context.push(AppRoutes.serverConfig),
              ),
            ),
          ],
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
