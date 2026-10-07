import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One place for driver feedback colours: success is green, failure is the
/// error colour, neutral information uses the theme SnackBar (black on gold
/// identity). Screens call these instead of building `SnackBar` by hand.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeEntry;

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.successGreen, Icons.check_circle_outline);

  static void error(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.error, Icons.error_outline);

  static void info(BuildContext context, String message) =>
      _show(context, message, null, Icons.info_outline);

  static void warn(BuildContext context, String message) =>
      _show(context, message, AppColors.warningYellow, Icons.warning_amber_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color? color,
    IconData icon,
  ) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // إلغاء أي إشعار سابق معلق لمنع تراكب واختناق الرسائل فوق بعضها
    if (_activeEntry != null && _activeEntry!.mounted) {
      _activeEntry!.remove();
      _activeEntry = null;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  if (entry.mounted) {
                    entry.remove();
                    if (_activeEntry == entry) _activeEntry = null;
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    if (entry.mounted) {
                      entry.remove();
                      if (_activeEntry == entry) _activeEntry = null;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: color ?? const Color(0xFF323232),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
        if (_activeEntry == entry) _activeEntry = null;
      }
    });
  }
}
