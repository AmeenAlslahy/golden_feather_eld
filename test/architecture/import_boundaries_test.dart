import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Current architectural debt. Every entry is a known violation that must be
/// removed by the remediation plan; adding a new entry needs review.
const Set<String> _allowedViolations = {
  // Phase 3.3 / later — presentation bypasses repositories for these flows.
  'PRESENTATION->BACKEND|features/account/presentation/providers/account_provider.dart|backend/contracts/account_backend.dart',
  'PRESENTATION->BACKEND|features/account/presentation/providers/account_provider.dart|backend/providers/backend_providers.dart',
  'PRESENTATION->BACKEND|features/auth/presentation/providers/auth_state_provider.dart|backend/providers/backend_network_providers.dart',
  'PRESENTATION->BACKEND|features/auth/presentation/widgets/forgot_password_form.dart|backend/providers/backend_providers.dart',
  'PRESENTATION->BACKEND|features/connection/presentation/pages/eld_connection_page.dart|backend/providers/backend_providers.dart',
  'PRESENTATION->BACKEND|features/connection/presentation/providers/hardware_alerts_provider.dart|backend/providers/backend_providers.dart',
  'PRESENTATION->BACKEND|features/connection/presentation/providers/hardware_status_provider.dart|backend/providers/backend_providers.dart',
  'PRESENTATION->BACKEND|features/hos/presentation/providers/hos_engine_provider.dart|backend/providers/backend_providers.dart',
};

final RegExp _importPattern = RegExp(r'''import\s+['"]([^'"]+)['"]''');

void main() {
  test('layer boundaries have no unapproved violations', () {
    final unexpected = _scanViolations().difference(_allowedViolations);

    expect(
      unexpected,
      isEmpty,
      reason:
          'New architectural boundary violation(s):\n'
          '${unexpected.join('\n')}',
    );
  });

  test('the allowlist has no stale entries', () {
    final stale = _allowedViolations.difference(_scanViolations());

    expect(
      stale,
      isEmpty,
      reason:
          'These violations were fixed; remove them from the allowlist:\n'
          '${stale.join('\n')}',
    );
  });
}

Set<String> _scanViolations() {
  final root = Directory('lib').absolute;
  final violations = <String>{};

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final relative = p
        .relative(entity.path, from: root.path)
        .replaceAll(r'\', '/');
    final source = entity.readAsStringSync();

    for (final match in _importPattern.allMatches(source)) {
      final uri = match.group(1)!;
      final target = _resolveImport(root.path, entity.path, uri);

      final isDomain =
          relative.startsWith('features/') && relative.contains('/domain/');
      final isPresentation =
          relative.startsWith('features/') &&
          relative.contains('/presentation/');

      if (isDomain &&
          (uri.startsWith('package:flutter/') || uri == 'dart:ui')) {
        violations.add('DOMAIN->FLUTTER|$relative|$uri');
      }
      if (target == null) continue;

      if (isDomain && target.startsWith('l10n/')) {
        violations.add('DOMAIN->L10N|$relative|$target');
      }

      if (relative.startsWith('core/') && target.startsWith('features/')) {
        violations.add('CORE->FEATURE|$relative|$target');
      }
      if (relative.startsWith('core/') &&
          (target == 'routes.dart' || target.startsWith('routes/'))) {
        violations.add('CORE->ROUTES|$relative|$target');
      }
      if (relative.startsWith('features/hos/') &&
          relative.contains('/domain/') &&
          target.startsWith('features/logs/')) {
        violations.add('HOS_DOMAIN->LOGS|$relative|$target');
      }
      if (isPresentation && target.startsWith('backend/')) {
        violations.add('PRESENTATION->BACKEND|$relative|$target');
      }
    }
  }

  return violations;
}

String? _resolveImport(String libRoot, String sourceFile, String uri) {
  if (uri.startsWith('package:golden_feather_eld/')) {
    return uri.substring('package:golden_feather_eld/'.length);
  }
  if (!uri.startsWith('.')) return null;

  final resolved = p.normalize(p.join(p.dirname(sourceFile), uri));
  if (!p.isWithin(libRoot, resolved)) return null;
  return p.relative(resolved, from: libRoot).replaceAll(r'\', '/');
}
