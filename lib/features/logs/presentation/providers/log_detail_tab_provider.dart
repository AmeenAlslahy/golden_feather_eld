import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tabs for LogDetailPage:
/// 0 = Events, 1 = Form, 2 = Certify
enum LogDetailTab { events, form, certify }

/// Provider to manage the selected tab index in LogDetailPage
final logDetailTabProvider = StateProvider<int>(
  (ref) => LogDetailTab.events.index,
);
