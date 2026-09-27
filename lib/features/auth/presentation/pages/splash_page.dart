import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // التحقق من الصلاحيات
    final locationGranted = await Permission.location.isGranted;
    final bluetoothGranted = await Permission.bluetooth.isGranted;
    if (!mounted) return;

    if (!locationGranted || !bluetoothGranted) {
      // أول مرة أو صلاحيات مفقودة
      context.goNamed('permissions');
      return;
    }

    // الصلاحيات موجودة، تحقق من تسجيل الدخول
    await ref.read(authStateProvider.notifier).checkAuthStatus();
    if (!mounted) return;
    final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
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
