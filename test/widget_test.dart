// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';

// import 'package:golden_feather_eld/main.dart';

void main() {
  testWidgets('Icon themes adapt properly to light and dark modes', (WidgetTester tester) async {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.iconTheme.color, isNotNull);
    expect(dark.iconTheme.color, isNotNull);
    expect(light.iconTheme.color, isNot(equals(dark.iconTheme.color)));

    final lightFg = light.iconButtonTheme.style?.foregroundColor?.resolve({});
    final darkFg = dark.iconButtonTheme.style?.foregroundColor?.resolve({});
    expect(lightFg, isNotNull);
    expect(darkFg, isNotNull);
    expect(lightFg, isNot(equals(darkFg)));
  });
}
