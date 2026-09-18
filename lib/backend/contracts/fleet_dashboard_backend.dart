import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class FleetDashboardBackend {
  /// GET /eld/dashboard/summary
  Future<Result<RawJson>> getSummary({int? groupId});

  /// GET /eld/dashboard/stream (SSE)
  ///
  /// Emits raw events. Parsing deferred to Phase 4.
  // TODO(P2): replace with typed DashboardEvent
  Stream<RawJson> streamEvents();
}
