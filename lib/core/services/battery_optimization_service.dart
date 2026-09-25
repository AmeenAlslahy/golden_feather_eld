import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../extensions/context_extensions.dart';
import '../utils/logger.dart';

/// خدمة فحص تحسين البطارية
class BatteryOptimizationService {
  /// التحقق مما إذا كان تحسين البطارية مفعلاً
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      // Permission is 'granted' when battery optimizations are IGNORED.
      // So if it's not granted, battery optimization is still ENABLED.
      final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
      return !isIgnored;
    } catch (e) {
      AppLogger.error('Failed to check battery optimization', e);
      return false;
    }
  }

  /// طلب تعطيل تحسين البطارية
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      AppLogger.info('🔋 Battery optimization disable requested');
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      AppLogger.error('Failed to request battery optimization', e);
    }
  }
}

/// مزود خدمة البطارية
final batteryOptimizationServiceProvider =
    Provider<BatteryOptimizationService>((ref) {
  return BatteryOptimizationService();
});

/// حوار تحسين البطارية
class BatteryOptimizationDialog extends ConsumerWidget {
  const BatteryOptimizationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      icon: Icon(Icons.battery_alert,
          color: context.eld.warningFg, size: 48),
      title: const Text('تحسين البطارية'),
      content: const Text(
        'لضمان تتبع موثوق للمركبة، يرجى تعطيل تحسين البطارية لهذا التطبيق.\n\n'
        'سيؤدي هذا إلى منع نظام التشغيل من إيقاف خدمة التتبع في الخلفية.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('تخطي'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
            ref
                .read(batteryOptimizationServiceProvider)
                .requestDisableBatteryOptimization();
          },
          child: const Text('فتح الإعدادات'),
        ),
      ],
    );
  }
}

/// دالة مساعدة لإظهار الحوار عند بدء التتبع
Future<bool> showBatteryOptimizationDialogIfNeeded(
    BuildContext context, WidgetRef ref) async {
  final service = ref.read(batteryOptimizationServiceProvider);
  final isEnabled = await service.isBatteryOptimizationEnabled();

  if (!isEnabled) return true; // لا حاجة للحوار

  if (!context.mounted) return true;

  await showDialog<bool>(
    context: context,
    builder: (_) => const BatteryOptimizationDialog(),
  );

  return true; // نسمح بالتتبع حتى لو تخطى المستخدم
}
