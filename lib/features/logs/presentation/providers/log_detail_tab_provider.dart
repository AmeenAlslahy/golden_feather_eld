import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the selected tab index in LogDetailPage
/// 0 = Events, 1 = Form, 2 = Certify
final logDetailTabProvider = StateProvider<int>((ref) => 0);
