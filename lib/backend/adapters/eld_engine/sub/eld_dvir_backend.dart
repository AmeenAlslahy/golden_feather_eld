import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/dvir_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [DvirBackend].
class EldDvirBackend implements DvirBackend {
  final ApiClient _apiClient;
  String? _lastServerMessage;

  EldDvirBackend(this._apiClient);

  @override
  String? get lastServerMessage => _lastServerMessage;

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    String? uniqueId,
    DateTime? date,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final page = limit > 0 ? offset ~/ limit : 0;
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvir,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        if (uniqueId != null) 'uniqueId': uniqueId,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if (status != null) 'status': status,
        'page': page,
        'size': limit,
        'limit': limit,
        'offset': offset,
      },
      parser: (data) => data is List
          ? {'data': data}
          : (data is Map<String, dynamic> ? data : {}),
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  Future<Result<void>> _accepted(Result<dynamic> res) {
    return Future.value(
      res.fold(
        err,
        (response) => response.isSuccess
            ? ok(null)
            : err(
                ServerError(
                  code: 'eld.request_failed',
                  context: {'message': response.message},
                ),
              ),
      ),
    );
  }

  @override
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvir,
      data: report,
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    _lastServerMessage = res.valueOrNull?.message;
    return _accepted(res);
  }

  @override
  Future<Result<RawJson>> getById(DvirId dvirId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirDetails(dvirId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> review({
    required DvirId dvirId,
    required RawJson review,
    int? expectedOwnerDriverId,
  }) async {
    final payload = Map<String, dynamic>.from(review);
    payload.putIfAbsent('previousDvirId', () => dvirId.value);
    payload.putIfAbsent(
      'driverSatisfiedSafe',
      () => review['driverAgreed'] ?? true,
    );

    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dvirPreviousReview,
      data: payload,
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );

    return res.fold((error) async {
      if (error is ServerError &&
          (error.code == 'http_404' || error.code.contains('404'))) {
        final fallbackRes = await _apiClient.post<RawJson>(
          EldEndpoints.dvirNextDriverReview(dvirId.value),
          data: payload,
          parser: (data) =>
              data is Map<String, dynamic> ? data : <String, dynamic>{},
          expectedOwnerDriverId: expectedOwnerDriverId,
        );
        return _accepted(fallbackRes);
      }
      return err(error);
    }, (success) => _accepted(res));
  }

  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  @override
  Future<Result<RawJson>> getDefectsCatalog() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirCatalog,
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getPreviousDvir(
    String uniqueId, {
    int? deviceId,
  }) async {
    // العقد الحي (§396.13): فلترة معيارية `filters` والخادم يقرأ deviceId
    // **رقمية من داخل الفلاتر** — البارامترات المسطحة تُتجاهل ويعيد 400
    // "Device ID (deviceId) is required in filters". عند غياب الرقمي
    // نُبقي الشكل المسطح القديم بدل اختراع قيمة (خوادم العقد السابق).
    final hasNumericDeviceId = deviceId != null && deviceId > 0;
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirPreviousReport,
      queryParameters: hasNumericDeviceId
          ? {
              'filters':
                  '[{"key":"deviceId","operator":"EQ","value":$deviceId}]',
              'sortBy': 'id',
              'sortDirection': 'DESC',
              'page': 0,
              'size': 1,
            }
          : {'uniqueId': uniqueId, 'deviceId': uniqueId},
      // _asMap يلفّ القائمة في {'items': [...]} فيفقد التطبيع العناصر —
      // هذا النداء يحتاج محللاً يمرر الحمولة إلى التطبيع مباشرة.
      parser: _parsePreviousPayload,
    );
    return res.fold((error) async {
      if (error is ServerError &&
          (error.code == 'http_404' || error.code.contains('404'))) {
        final fallback = await _apiClient.get<RawJson>(
          EldEndpoints.dvirPrevious(uniqueId),
          parser: _asMap,
        );
        return fallback.mapValue((r) => _normalizePreviousBody(r.data));
      }
      return err(error);
    }, (success) => ok(_normalizePreviousBody(success.data)));
  }

  /// محلل رد `/eld/dvir/previous`: القائمة/الكائن تُمرر إلى
  /// [_normalizePreviousBody] مباشرة بدل غلاف `items`.
  RawJson _parsePreviousPayload(dynamic data) => _normalizePreviousBody(data);

  /// تطبيع رد `/eld/dvir/previous`: العقد الحي يعيد صفحة
  /// `{success, data: [...], pagination}` — و`ApiResponse` يفكّ المغلف فيصل
  /// [body] قائمة العناصر مباشرة — بينما طبقة المستودع تفهم كائن DVIR
  /// مباشرة أو رايات `hasPreviousDvir` القديمة. قائمة فارغة = لا فحص سابق.
  RawJson _normalizePreviousBody(dynamic body) {
    if (body is List) {
      return body.isEmpty
          ? <String, dynamic>{'hasPreviousDvir': false}
          : Map<String, dynamic>.from(body.first as Map);
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data.isEmpty
            ? <String, dynamic>{'hasPreviousDvir': false}
            : Map<String, dynamic>.from(data.first as Map);
      }
      return body;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Result<RawJson>> getDefectDetails(int defectId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirDefectDetails(defectId),
      parser: _asMap,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getVehicleDefects(
    String uniqueId, {
    int? deviceId,
  }) async {
    // المسار الحيّ هو `GET /eld/dvir/defects?uniqueId=...&deviceId=...`؛
    // مسار `/defects/device/{uniqueId}` يعيد 404. نستخدم الرقمي عند
    // توفره، وإلا نُبقي uniqueId كما كان (يعمل حياً لهذا المسار).
    final resolvedDeviceId = (deviceId != null && deviceId > 0)
        ? deviceId
        : uniqueId;
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dvirDefects,
      queryParameters: {'uniqueId': uniqueId, 'deviceId': resolvedDeviceId},
      parser: _asMap,
    );
    return res.fold((error) async {
      final isNotFound =
          error is NotFoundError ||
          error.code == 'resource.notFound' ||
          error.code == 'http_404' ||
          error.code.contains('404');
      if (isNotFound) {
        final fallback = await _apiClient.get<RawJson>(
          EldEndpoints.dvirVehicleDefects(uniqueId),
          parser: _asMap,
        );
        return fallback.fold((fbError) {
          final fbNotFound =
              fbError is NotFoundError ||
              fbError.code == 'resource.notFound' ||
              fbError.code == 'http_404' ||
              fbError.code.contains('404');
          if (fbNotFound) {
            // إذا لم توجد عيوب للمركبة في الخادم (404)، تُعاد قائمة فارغة طبيعية
            return ok(<String, dynamic>{'data': <dynamic>[]});
          }
          return err(fbError);
        }, (success) => ok(success.data ?? <String, dynamic>{}));
      }
      return err(error);
    }, (success) => ok(success.data ?? <String, dynamic>{}));
  }
}
