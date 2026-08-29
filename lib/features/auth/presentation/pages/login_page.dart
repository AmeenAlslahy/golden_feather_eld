import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/login_form.dart';

/// صفحة تسجيل الدخول
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // شعار التطبيق
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/ic_launcher.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 24),

              // اسم التطبيق
              Text(
                context.loc.appName,
                style: context.textTheme.headlineLarge?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // شعار التطبيق
              Text(
                context.loc.appSlogan,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // نموذج تسجيل الدخول
              const LoginForm(),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  context.pushNamed('register');
                },
                child: const Text('إنشاء حساب جديد'),
              ),
              const SizedBox(height: 16),

              // رسائل الخطأ
              if (authState.status == AuthStatus.error)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.dangerRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.arabicErrorMessage ?? authState.errorMessage ?? '',
                          style: const TextStyle(color: AppColors.dangerRed),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



