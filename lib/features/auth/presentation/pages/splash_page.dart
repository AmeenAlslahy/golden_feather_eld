import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_gap.dart';
// import '../../../../core/theme/app_colors.dart';
import '../providers/auth_state_provider.dart';

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

    if (!locationGranted || !bluetoothGranted) {
      // أول مرة أو صلاحيات مفقودة
      // ignore: use_build_context_synchronously
      context.goNamed('permissions');
    } else {
      // الصلاحيات موجودة، تحقق من تسجيل الدخول
      await ref.read(authStateProvider.notifier).checkAuthStatus();
      final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
      if (isLoggedIn) {
        // ignore: use_build_context_synchronously
        context.goNamed('connection');
      } else {
        // ignore: use_build_context_synchronously
        context.goNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Image.asset(
                'assets/images/ic_launcher.png',
                width: 120,
                height: 120,
              ),
            ),
            AppGap.md,
            Text(
              context.loc.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            AppGap.lg,
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}