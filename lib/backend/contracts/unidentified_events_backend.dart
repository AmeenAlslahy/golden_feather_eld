import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

/// One entry in the documented `filters` JSON array
/// (`{key, operator, value}`).
class UnidentifiedEventFilter {
  final String key;
  final String operator;
  final Object? value;

  const UnidentifiedEventFilter({
    required this.key,
    required this.value,
    this.operator = 'EQ',
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'operator': operator,
    'value': value,
  };
}

abstract interface class UnidentifiedEventsBackend {
  /// Last server message returned by claim/reject.
  String? get lastServerMessage;

  /// GET /eld/unidentified
  ///
  /// The active tab is always sent as the documented `status` filter
  /// (`UNCLAIMED` / `REJECTED`) inside `filters`; `page`, `size`, `sortBy`,
  /// `sortDirection` and `filters` are the only query parameters.
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'ASC',
    List<UnidentifiedEventFilter> filters = const [],
  });

  /// GET /eld/unidentified/{id}
  Future<Result<RawJson>> getById({required DutyStatusId id});

  /// GET /eld/unidentified/summary
  Future<Result<RawJson>> summary();

  /// POST /eld/unidentified/{id}/claim
  Future<Result<void>> claim({
    required DutyStatusId id,
    DriverId? driverId,
    required String annotation,
  });

  /// POST /eld/unidentified/{id}/reject
  Future<Result<void>> reject({
    required DutyStatusId id,
    DriverId? driverId,
    required String rejectionReason,
  });
}
