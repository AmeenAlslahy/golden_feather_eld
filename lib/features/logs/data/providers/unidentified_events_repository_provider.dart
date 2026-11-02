import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../domain/repositories/unidentified_events_repository.dart';
import '../repositories/unidentified_events_repository_impl.dart';

/// DI لطبقة البيانات: هي التي تركّب مستودعها من الـ backend.
final unidentifiedEventsRepositoryProvider =
    Provider<UnidentifiedEventsRepository>((ref) {
      return UnidentifiedEventsRepositoryImpl(
        ref.watch(unidentifiedEventsBackendProvider),
      );
    });
