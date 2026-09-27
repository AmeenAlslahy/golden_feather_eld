import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps an `autoDispose` provider's last value alive for [duration] after its
/// last listener goes away, so re-opening a page shows data at once instead
/// of a spinner and a fresh request on a slow network. Explicit
/// `ref.invalidate(...)` (retry / pull-to-refresh) still forces a reload.
void cacheFor(Ref ref, Duration duration) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer?.cancel();
    timer = Timer(duration, link.close);
  });
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}
