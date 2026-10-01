import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../providers/auth_state_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    if (!mounted) return;

    AppLogger.info('SplashPage: Checking onboarding status...');
    if (!ref.read(localStorageProvider).onboardingSeen) {
      if (!mounted) return;
      AppLogger.info('SplashPage: Redirecting to onboarding');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed('onboarding');
      });
      return;
    }

    AppLogger.info('SplashPage: Checking permissions...');
    try {
      final locationGranted = await Permission.location.isGranted.timeout(const Duration(seconds: 2));
      final bluetoothGranted = await Permission.bluetooth.isGranted.timeout(const Duration(seconds: 2));
      if (!mounted) return;

      if (!locationGranted || !bluetoothGranted) {
        AppLogger.info('SplashPage: Redirecting to permissions');
        context.goNamed('permissions');
        return;
      }
    } catch (e) {
      AppLogger.error('SplashPage: Permission check timed out or failed', e);
      // Proceed to login as fallback
      context.goNamed('login');
      return;
    }

    AppLogger.info('SplashPage: Checking auth status...');
    await ref.read(authStateProvider.notifier).checkAuthStatus();
    
    if (!mounted) return;
    final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
    AppLogger.info('SplashPage: Auth status check complete. IsLoggedIn: $isLoggedIn');
    context.goNamed(isLoggedIn ? 'connection' : 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/ic_launcher.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
