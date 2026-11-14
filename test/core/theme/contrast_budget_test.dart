import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_colors.dart';
import 'package:golden_feather_eld/core/theme/golden_colors.dart';

/// ميزانية التباين لرموز الحقول التفاعلية والنص الخافت.
///
/// WCAG 1.4.11: حدود المكوّنات وحالاتها ≥ 3:1.
/// WCAG 1.4.3: النص العادي ≥ 4.5:1.
///
/// تُحسب القيم مقابل الخلفيات الفعلية المركبة، لا مقابل لون واحد فقط.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Light — field borders ≥ 3:1', () {
    const border = AppColors.lightInputBorder;
    final cellOverPage = _cell(AppColors.lightBackground, dark: false);
    final cellOverWhite = _cell(AppColors.lightSurface, dark: false);
    final backgrounds = <String, Color>{
      'field fill (white)': AppColors.lightSurface,
      'page background': AppColors.lightBackground,
      'secondary surface': AppColors.lightSurfaceSecondary,
      'gold container': AppColors.goldBg,
      'selected container': AppColors.lightPrimaryContainer,
      'DvirCell over page': cellOverPage,
      'DvirCell over white': cellOverWhite,
      'DvirDropdown over page cell': _dropdown(cellOverPage, dark: false),
      'DvirDropdown over white cell': _dropdown(cellOverWhite, dark: false),
    };

    backgrounds.forEach((name, background) {
      test('input border vs $name', () {
        _expectContrast(border, background, minimum: 3.0, label: name);
      });
    });
  });

  group('Dark — field borders ≥ 3:1', () {
    const border = AppColors.darkInputBorder;
    final cellOverPage = _cell(AppColors.darkBackground, dark: true);
    final cellOverSurface = _cell(AppColors.darkSurface, dark: true);
    final backgrounds = <String, Color>{
      'field fill (surface)': AppColors.darkSurface,
      'page background': AppColors.darkBackground,
      'secondary surface': AppColors.darkSurfaceSecondary,
      'elevated surface': AppColors.darkSurfaceElevated,
      'DvirCell over page': cellOverPage,
      'DvirCell over surface': cellOverSurface,
      'DvirDropdown over page cell': _dropdown(cellOverPage, dark: true),
      'DvirDropdown over surface cell': _dropdown(cellOverSurface, dark: true),
    };

    backgrounds.forEach((name, background) {
      test('input border vs $name', () {
        _expectContrast(border, background, minimum: 3.0, label: name);
      });
    });
  });

  group('Light — muted text ≥ 4.5:1', () {
    const muted = AppColors.lightTextMuted;
    final cellOverPage = _cell(AppColors.lightBackground, dark: false);
    final backgrounds = <String, Color>{
      'white': AppColors.lightSurface,
      'page background': AppColors.lightBackground,
      'secondary surface': AppColors.lightSurfaceSecondary,
      'gold container': AppColors.goldBg,
      'selected container': AppColors.lightPrimaryContainer,
      'DvirCell over page': cellOverPage,
      'DvirDropdown over page cell': _dropdown(cellOverPage, dark: false),
    };

    backgrounds.forEach((name, background) {
      test('lightTextMuted vs $name', () {
        _expectContrast(muted, background, minimum: 4.5, label: name);
      });
    });
  });

  group('Dark — muted text ≥ 4.5:1', () {
    const muted = AppColors.darkTextMuted;
    final backgrounds = <String, Color>{
      'surface': AppColors.darkSurface,
      'page background': AppColors.darkBackground,
      'secondary surface': AppColors.darkSurfaceSecondary,
      'elevated surface': AppColors.darkSurfaceElevated,
      'gold container': AppColors.darkGoldBg,
      'selected container': AppColors.darkPrimaryContainer,
    };

    backgrounds.forEach((name, background) {
      test('darkTextMuted vs $name', () {
        _expectContrast(muted, background, minimum: 4.5, label: name);
      });
    });
  });

  group('Focus states ≥ 3:1', () {
    test('light focus ring vs all field surfaces', () {
      const focus = AppColors.brandGoldDark;
      final cellOverPage = _cell(AppColors.lightBackground, dark: false);
      final backgrounds = <String, Color>{
        'white': AppColors.lightSurface,
        'page background': AppColors.lightBackground,
        'secondary surface': AppColors.lightSurfaceSecondary,
        'selected container': AppColors.lightPrimaryContainer,
        'DvirCell over page': cellOverPage,
        'DvirDropdown over page cell': _dropdown(cellOverPage, dark: false),
      };
      backgrounds.forEach((name, background) {
        _expectContrast(focus, background, minimum: 3.0, label: name);
      });
    });

    test('dark focus ring vs all field surfaces', () {
      const focus = AppColors.brandGoldLight;
      final backgrounds = <String, Color>{
        'surface': AppColors.darkSurface,
        'page background': AppColors.darkBackground,
        'secondary surface': AppColors.darkSurfaceSecondary,
        'elevated surface': AppColors.darkSurfaceElevated,
        'selected container': AppColors.darkPrimaryContainer,
      };
      backgrounds.forEach((name, background) {
        _expectContrast(focus, background, minimum: 3.0, label: name);
      });
    });
  });

  group('Error states ≥ 4.5:1 (text) and ≥ 3:1 (border)', () {
    test('light error color vs error surfaces', () {
      const error = AppColors.dangerText;
      final cell = _cell(AppColors.lightBackground, dark: false);
      final backgrounds = <String, Color>{
        'white': AppColors.lightSurface,
        'page background': AppColors.lightBackground,
        'secondary surface': AppColors.lightSurfaceSecondary,
        'danger container': AppColors.dangerBg,
        'error dropdown over cell': _dropdown(cell, dark: false, error: true),
      };
      backgrounds.forEach((name, background) {
        _expectContrast(error, background, minimum: 4.5, label: name);
      });
    });

    test('dark error color vs error surfaces', () {
      const error = AppColors.dangerOnDark;
      final cell = _cell(AppColors.darkSurface, dark: true);
      final backgrounds = <String, Color>{
        'surface': AppColors.darkSurface,
        'secondary surface': AppColors.darkSurfaceSecondary,
        'elevated surface': AppColors.darkSurfaceElevated,
        'danger container': AppColors.darkDangerBg,
        'error dropdown over cell': _dropdown(cell, dark: true, error: true),
      };
      backgrounds.forEach((name, background) {
        _expectContrast(error, background, minimum: 4.5, label: name);
      });
    });
  });

  group('Semantic text tokens ≥ 4.5:1', () {
    final surfaces = <String, Color>{
      'white': AppColors.lightSurface,
      'page background': AppColors.lightBackground,
      'secondary surface': AppColors.lightSurfaceSecondary,
      'selected container': AppColors.lightPrimaryContainer,
    };
    final tokens = <String, (Color, Color)>{
      'success': (AppColors.successText, AppColors.successBg),
      'error': (AppColors.dangerText, AppColors.dangerBg),
      'warning': (AppColors.warningText, AppColors.warningBg),
      'info': (AppColors.infoText, AppColors.infoBg),
    };

    tokens.forEach((name, pair) {
      final (foreground, container) = pair;
      test('$name text on its container', () {
        _expectContrast(foreground, container, minimum: 4.5, label: name);
      });
      surfaces.forEach((surfaceName, surface) {
        test('$name text on $surfaceName', () {
          _expectContrast(
            foreground,
            surface,
            minimum: 4.5,
            label: '$name/$surfaceName',
          );
        });
      });
    });
  });

  group('Solid feedback fills ≥ 4.5:1', () {
    const fills = <String, (Color, Color)>{
      'success toast': (AppColors.onSuccessFill, AppColors.successFill),
      'error toast': (AppColors.onDangerFill, AppColors.dangerFill),
      'warning toast': (AppColors.onWarningFill, AppColors.warningFill),
      'info toast': (AppColors.onInfoFill, AppColors.infoFill),
    };

    fills.forEach((name, pair) {
      final (foreground, background) = pair;
      test(name, () {
        _expectContrast(foreground, background, minimum: 4.5, label: name);
      });
    });

    test('error border token vs light surfaces', () {
      final backgrounds = <String, Color>{
        'white': AppColors.lightSurface,
        'page background': AppColors.lightBackground,
        'secondary surface': AppColors.lightSurfaceSecondary,
      };
      backgrounds.forEach((name, background) {
        _expectContrast(
          AppColors.dangerRed,
          background,
          minimum: 3.0,
          label: 'error border/$name',
        );
      });
    });
  });

  group('Dark semantic containers ≥ 4.5:1', () {
    const pairs = <String, (Color, Color)>{
      'success': (AppColors.successOnDark, AppColors.darkSuccessBg),
      'error': (AppColors.dangerOnDark, AppColors.darkDangerBg),
      'warning': (AppColors.warningOnDark, AppColors.darkWarningBg),
      'info': (AppColors.infoOnDark, AppColors.darkInfoBg),
    };

    pairs.forEach((name, pair) {
      final (foreground, background) = pair;
      test('$name on dark container', () {
        _expectContrast(foreground, background, minimum: 4.5, label: name);
      });
    });
  });

  group('Token separation', () {
    test('decorative border tokens remain unchanged', () {
      expect(GoldenColors.light.border, AppColors.lightBorder);
      expect(GoldenColors.dark.border, AppColors.darkBorder);
    });

    test('input border is distinct from decorative border in both modes', () {
      expect(GoldenColors.light.inputBorder, AppColors.lightInputBorder);
      expect(GoldenColors.dark.inputBorder, AppColors.darkInputBorder);
      expect(GoldenColors.light.inputBorder, isNot(GoldenColors.light.border));
      expect(GoldenColors.dark.inputBorder, isNot(GoldenColors.dark.border));
    });
  });
}

Color _cell(Color under, {required bool dark}) {
  final tint = dark
      ? AppColors.darkSurfaceSecondary
      : AppColors.lightSurfaceSecondary;
  return Color.alphaBlend(tint.withValues(alpha: 0.35), under);
}

Color _dropdown(Color under, {required bool dark, bool error = false}) {
  final tint = dark
      ? (error ? AppColors.darkDangerBg : AppColors.darkSurfaceSecondary)
      : (error ? AppColors.dangerBg : AppColors.lightSurfaceSecondary);
  return Color.alphaBlend(tint.withValues(alpha: error ? 0.3 : 0.35), under);
}

void _expectContrast(
  Color foreground,
  Color background, {
  required double minimum,
  required String label,
}) {
  final ratio = _contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason:
        '$label: ${ratio.toStringAsFixed(2)}:1 is below '
        '${minimum.toStringAsFixed(1)}:1',
  );
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}
