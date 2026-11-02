import 'dart:convert';

import '../../../../core/error/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/unidentified_events_backend.dart';
import '../../../http/eld_endpoints.dart';

/// Driver claim/reject and reading of unidentified driving
/// (SRS §7.13, §8.8, §11).
class EldUnidentifiedEventsBackend implements UnidentifiedEventsBackend {
  final ApiClient _apiClient;

  const EldUnidentifiedEventsBackend(this._apiClient);

  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  /// Rejects a failed unified envelope before its body can be mistaken for
  /// success. Field errors are permanent validation failures; any other
  /// failed envelope is a server-side failure.
  Result<RawJson> _checked(ApiResponse<RawJson> response, String path) {
    if (response.isSuccess) {
      return ok(response.data ?? <String, dynamic>{});
    }

    final message = response.message?.trim();
    final context = <String, dynamic>{
      'endpoint': path,
      if (message != null && message.isNotEmpty) 'message': message,
      if (response.errors.isNotEmpty)
        'errors': response.errors.map((error) => error.toString()).toList(),
      if (response.requestId != null) 'requestId': response.requestId,
    };

    return err(
      response.errors.isNotEmpty
          ? ValidationError(
              code: 'unidentified.request.rejected',
              l10nKey: 'validation.badRequest',
              fieldErrors: {
                for (final error in response.errors) error.field: error.message,
              },
              context: context,
            )
          : ServerError(
              code: 'unidentified.request.rejected',
              statusCode: response.statusCode,
              context: context,
            ),
    );
  }

  Future<Result<RawJson>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final res = await _apiClient.get<RawJson>(
      path,
      queryParameters: queryParameters,
      parser: _asMap,
    );
    return res.flatMap((response) => _checked(response, path));
  }

  Future<Result<void>> _postVoid(String path, Map<String, dynamic> data) async {
    final res = await _apiClient.post<RawJson>(
      path,
      data: data,
      parser: _asMap,
    );
    return res.flatMap(
      (response) => _checked(response, path).mapValue<void>((_) {}),
    );
  }

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'ASC',
    List<UnidentifiedEventFilter> filters = const [],
  }) {
    final allFilters = <UnidentifiedEventFilter>[
      UnidentifiedEventFilter(key: 'status', value: tab.wire),
      ...filters,
    ];
    return _getJson(
      EldEndpoints.unidentifiedEvents,
      queryParameters: {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'filters': jsonEncode(
          allFilters.map((filter) => filter.toJson()).toList(),
        ),
      },
    );
  }

  @override
  Future<Result<RawJson>> getById({required DutyStatusId id}) {
    return _getJson(EldEndpoints.unidentifiedEvent(id.value));
  }

  @override
  Future<Result<RawJson>> summary() {
    return _getJson(EldEndpoints.unidentifiedSummary);
  }

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    DriverId? driverId,
    required String annotation,
  }) {
    return _postVoid(EldEndpoints.claimUnidentified(id.value), {
      if (driverId != null) 'driverId': driverId.value,
      'annotation': annotation.trim(),
    });
  }

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    DriverId? driverId,
    required String rejectionReason,
  }) {
    return _postVoid(EldEndpoints.rejectUnidentified(id.value), {
      if (driverId != null) 'driverId': driverId.value,
      'rejectionReason': rejectionReason.trim(),
    });
  }
}
