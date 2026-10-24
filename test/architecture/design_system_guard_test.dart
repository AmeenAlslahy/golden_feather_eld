import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final Map<String, RegExp> _forbiddenPatterns = {
  'direct AppColors reference': RegExp(r'AppColors\.'),
  'direct Colors reference': RegExp(r'\bColors\.'),
  'inline TextStyle': RegExp(r'\bTextStyle\('),
  'numeric font size': RegExp(r'fontSize:\s*\d'),
  'numeric border radius': RegExp(r'BorderRadius\.circular\(\s*\d'),
  'direct AppColors import': RegExp(
    r'''import\s+['"][^'"]*app_colors\.dart['"]''',
  ),
};

void main() {
  test('feature layer uses design-system tokens', () {
    final violations = <String>[];
    final root = Directory('lib/features').absolute;

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final relative = p
          .relative(entity.path, from: Directory('lib').absolute.path)
          .replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();

      for (var index = 0; index < lines.length; index++) {
        for (final entry in _forbiddenPatterns.entries) {
          if (entry.value.hasMatch(lines[index])) {
            violations.add(
              '$relative:${index + 1} (${entry.key}) '
              '${lines[index].trim()}',
            );
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature code must use design-system tokens instead of direct '
          'colors, inline text styles, or numeric sizes:\n'
          '${violations.join('\n')}',
    );
  });
}
