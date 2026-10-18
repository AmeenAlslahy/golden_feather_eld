import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P1 — فحوص ثابتة لملفات منصة أندرويد التي لا تغطيها اختبارات Dart:
/// نسخ احتياطي بيانات التطبيق، وتوقيع release.
void main() {
  group('P1 — release security configuration', () {
    test('AndroidManifest disables app-data backup', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(
        manifest,
        contains('android:allowBackup="false"'),
        reason: 'بدونه يمكن استرجاع صناديق Hive (توكن الجلسة) إلى جهاز آخر',
      );
    });

    test('release signing reads git-ignored key.properties, debug only fallback',
        () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('key.properties'));
      expect(gradle, contains('signingConfigs'));
      expect(gradle, contains('keystorePropertiesFile.exists()'));
      expect(
        gradle,
        contains('signingConfigs.getByName("debug")'),
        reason: 'التراجع للتوقيع التجريبي مسموح محلياً فقط',
      );
      expect(
        gradle.indexOf('keystorePropertiesFile.exists()'),
        lessThan(gradle.indexOf('signingConfigs.getByName("debug")')),
        reason: 'الشرط يجب أن يسبق التراجع ليبقى مسار الإصدار هو الافتراضي',
      );
    });

    test('key.properties is git-ignored and an example template exists', () {
      final androidGitignore = File('android/.gitignore').readAsStringSync();
      expect(androidGitignore, contains('key.properties'));
      expect(File('android/key.properties.example').existsSync(), isTrue);
    });
  });
}
