import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'خيارات المطور' : 'Developer Options'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(isArabic ? 'سجلات التتبع (Tracking Logs)' : 'Tracking Logs'),
            subtitle: Text(isArabic ? 'عرض السجلات الخام للـ GPS' : 'View raw GPS logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tracking-logs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(isArabic ? 'محاكاة الأخطاء' : 'Mock Errors'),
            subtitle: Text(isArabic ? 'أدوات لاختبار واجهة المستخدم' : 'Tools to test UI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'غير متوفرة في نسخة الإنتاج' : 'Not available in production build')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(
              isArabic ? 'مسح التخزين المؤقت' : 'Clear Cache',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(isArabic ? 'مسح بيانات التطبيق المحلية' : 'Clear local app data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'تم تنظيف التخزين المؤقت' : 'Cache cleared')),
              );
            },
          ),
        ],
      ),
    );
  }
}
