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

const _allowedViolations = {
  'features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart:115 (direct Colors reference) color: Colors.transparent,',
  'features/hos/presentation/widgets/status_option_tiles.dart:43 (direct Colors reference) : Colors.transparent,',
  'features/logs/presentation/pages/suggested_events_page.dart:83 (numeric font size) fontSize: 13,',
  'features/logs/presentation/pages/unidentified_events_page.dart:147 (direct Colors reference) dividerColor: Colors.transparent,',
  'features/logs/presentation/pages/unidentified_events_page.dart:148 (direct AppColors reference) labelColor: AppColors.brandBlack,',
  'features/logs/presentation/pages/unidentified_events_page.dart:149 (direct AppColors reference) unselectedLabelColor: AppColors.brandBlack.withValues(alpha: 0.60),',
  'features/logs/presentation/pages/unidentified_events_page.dart:150 (direct AppColors reference) indicatorColor: AppColors.brandBlack,',
  'features/logs/presentation/widgets/suggested_log_card.dart:79 (numeric font size) fontSize: 15,',
  'features/logs/presentation/widgets/suggested_log_card.dart:100 (numeric font size) fontSize: 11,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:186 (numeric font size) fontSize: 11,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:231 (numeric font size) fontSize: 15,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:280 (numeric font size) fontSize: 13,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:308 (numeric font size) fontSize: 13,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:335 (numeric font size) fontSize: 10,',
  'features/logs/presentation/widgets/unidentified_events_list.dart:504 (numeric font size) fontSize: 10.5,',
  'features/logs/presentation/widgets/unidentified_stats_row.dart:126 (numeric font size) fontSize: 16,',
  'features/logs/presentation/widgets/unidentified_stats_row.dart:135 (direct AppColors reference) ? AppColors.darkTextSecondary',
  'features/logs/presentation/widgets/unidentified_stats_row.dart:137 (numeric font size) fontSize: 11.5,',
};

List<String> _scanViolations() {
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
  return violations;
}

void main() {
  test('feature layer uses design-system tokens', () {
    final violations = _scanViolations();
    final unexpected = violations.toSet().difference(_allowedViolations);

    expect(
      unexpected,
      isEmpty,
      reason:
          'Feature code must use design-system tokens instead of direct '
          'colors, inline text styles, or numeric sizes:\n'
          '${unexpected.join('\n')}',
    );
  });

  test('the allowlist has no stale entries', () {
    final violations = _scanViolations();
    final stale = _allowedViolations.difference(violations.toSet());

    expect(
      stale,
      isEmpty,
      reason:
          'The following allowlist entries are stale and should be removed:\n'
          '${stale.join('\n')}',
    );
  });
}
