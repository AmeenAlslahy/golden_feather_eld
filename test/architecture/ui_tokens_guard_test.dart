import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('UI Architecture Tokens & Components Guard', () {
    late Map<String, int> approvedBaseline;
    late List<Map<String, dynamic>> rawBaselineList;

    setUpAll(() {
      final baselineFile = File('ui_violations_baseline.json');
      expect(
        baselineFile.existsSync(),
        isTrue,
        reason: 'ui_violations_baseline.json must exist at repo root',
      );

      final content = baselineFile.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      rawBaselineList = (data['violations'] as List).cast<Map<String, dynamic>>();

      approvedBaseline = {};
      for (final item in rawBaselineList) {
        final key = '${item['file']}|${item['rule']}';
        approvedBaseline[key] = item['count'] as int;
      }
    });

    test('features presentation code matches approved UI architecture baseline', () {
      final featureDir = Directory('lib/features');
      final featureFiles = featureDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            final normalized = f.path.replaceAll(r'\', '/');
            return normalized.contains('/presentation/') &&
                !normalized.contains('painter') &&
                !normalized.contains('chart');
          })
          .toList();

      final detectedCounts = <String, int>{};
      final newViolations = <String>[];

      final hexColorRegex = RegExp(r'Color\(0x[0-9a-fA-F]{6,8}\)');
      final materialColorRegex = RegExp(
        r'\bColors\.(red|green|blue|orange|amber|yellow|grey|white|black|purple|teal|indigo|cyan|lime|brown|pink)\b',
      );
      final appColorsRegex = RegExp(r'\bAppColors\.');
      final fontSizeRegex = RegExp(r'fontSize:\s*\d+(\.\d+)?');
      final rawWidgetRegex = RegExp(
        r'\b(AlertDialog|TextButton|OutlinedButton|AppBar)\(',
      );

      for (final file in featureFiles) {
        final relPath = p
            .relative(file.path, from: Directory.current.path)
            .replaceAll(r'\', '/');
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();

          // Skip comments
          if (trimmed.startsWith('//') ||
              trimmed.startsWith('*') ||
              trimmed.startsWith('/*')) {
            continue;
          }

          void recordViolation(String rule) {
            final key = '$relPath|$rule';
            detectedCounts[key] = (detectedCounts[key] ?? 0) + 1;
            final approved = approvedBaseline[key] ?? 0;
            if (detectedCounts[key]! > approved) {
              newViolations.add(
                '$relPath:${i + 1} [$rule] "$trimmed" (Count: ${detectedCounts[key]}, Approved: $approved)',
              );
            }
          }

          if (hexColorRegex.hasMatch(line)) {
            recordViolation('hardcoded_hex_color');
          }
          if (materialColorRegex.hasMatch(line)) {
            recordViolation('direct_material_semantic_color');
          }
          if (appColorsRegex.hasMatch(line)) {
            recordViolation('direct_app_colors_semantic');
          }
          if (fontSizeRegex.hasMatch(line)) {
            recordViolation('inline_numeric_font_size');
          }
          if (rawWidgetRegex.hasMatch(line)) {
            recordViolation('raw_material_button_or_dialog');
          }
        }
      }

      // 1. Verify no new unapproved violations
      expect(
        newViolations,
        isEmpty,
        reason:
            'Unapproved UI architecture violations detected:\n${newViolations.join('\n')}\n'
            'Feature screens must consume Golden Feather Design System 2.0 shared tokens '
            'and components instead of inline definitions or raw material widgets.',
      );

      // 2. Identify stale entries that have been cleaned up and can be removed from baseline
      final staleEntries = <String>[];
      for (final entry in approvedBaseline.entries) {
        final actual = detectedCounts[entry.key] ?? 0;
        if (actual < entry.value) {
          staleEntries.add(
            '${entry.key} (Approved: ${entry.value}, Actual: $actual)',
          );
        }
      }

      expect(
        staleEntries,
        isEmpty,
        reason:
            'Stale baseline entries detected (violations were cleaned up):\n'
            '${staleEntries.join('\n')}\n'
            'Please update ui_violations_baseline.json to reflect the improvements.',
      );
    });
  });
}
