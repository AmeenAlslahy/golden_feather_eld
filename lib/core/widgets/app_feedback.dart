import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One place for driver feedback colours: success is green, failure is the
/// error colour, neutral information uses the theme SnackBar (black on gold
/// identity). Screens call these instead of building `SnackBar` by hand.
class AppFeedback {
  AppFeedback._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.successGreen);

  static void error(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, null);

  static void _show(BuildContext context, String message, Color? color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
