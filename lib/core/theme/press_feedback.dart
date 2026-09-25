import 'package:flutter/material.dart';

/// Visible press/ink for ELD stadium buttons and list rows.
abstract final class PressFeedback {
  static const InteractiveInkFeatureFactory splashFactory =
      InkRipple.splashFactory;

  static WidgetStateProperty<Color?> overlay({bool onDark = false}) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return onDark
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return onDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06);
      }
      return null;
    });
  }

  static Color pressed(Color base, {bool onDark = false}) {
    return Color.alphaBlend(
      (onDark ? Colors.white : Colors.black).withValues(alpha: 0.20),
      base,
    );
  }

  static const Color ink = Color(0x29000000);
  static const Color inkOnDark = Color(0x47FFFFFF);
}
