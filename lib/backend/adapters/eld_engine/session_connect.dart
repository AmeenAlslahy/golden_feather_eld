/// مسار `POST /eld/sessions/connect` المشترك بين تنفيذ الأجهزة وتنفيذ جلسة
/// السائق.
///
/// التنفيذان يرسلان **نفس** الجسم (لا Query Parameters) ويسقطان إلى مسار
/// `/eld/sessions/start` عند 404 فقط. كان هذا مكرراً حرفياً في
/// `EldHardwareBackend` و`EldDriverSessionBackend`؛ هذا الملف مصدر واحد له.
///
/// **تحليل الاستجابة يبقى مختلفاً بشكل مقصود**، ولا يُوحَّد:
///
/// * [parsePermissiveBody] — مسار الأجهزة: يقبل أي `Map` ويحوّله إلى
///   `Map<String, dynamic>`، وإلا `{}`.
/// * [parseTypedMapBody] — مسار جلسة السائق: يقبل `Map<String, dynamic>` فقط،
///   وإلا `{}` (سلوك قديم متراخٍ محفوظ كما هو).
///
/// كما أن مسار الأجهزة وحده يتحقق من `success`/`status` ومن كفاية الحمولة؛
/// وتُوفَّر أدوات هذا التحقق هنا ([failureMarkerOf]، [confirmedPayload]) كي
/// تبقى قواعد القراءة في مكان واحد دون فرضها على مسار جلسة السائق.
library;

import '../../../core/error/app_error.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/result/result.dart';
import '../../../domain/shared/value_objects.dart';
import '../../contracts/raw_json.dart';
import '../../http/eld_endpoints.dart';

/// قارئ جسم استجابة `/connect`. لكل مسار قارئه المحفوظ.
typedef ConnectBodyParser = RawJson Function(dynamic body);

abstract final class EldSessionConnect {
  /// جسم الطلب الوحيد الذي يقبله العقد الحيّ.
  ///
  /// `manualMode` = هل نُسجّل يدوياً الآن (جلسة بلا اتصال جهاز)، و
  /// `manualModeEnabled` = هل خيار التسجيل اليدوي متاح لهذه الجلسة.
  static Map<String, dynamic> payload({
    String? uniqueId,
    bool disconnected = false,
    DriverId? driverId,
    DriverId? coDriverId,
  }) {
    return <String, dynamic>{
      if (driverId != null) 'driverId': driverId.value,
      if (coDriverId != null) 'coDriverId': coDriverId.value,
      if (uniqueId != null) 'deviceId': uniqueId,
      'manualMode': disconnected,
      'manualModeEnabled': true,
    };
  }

  /// يرسل [payload] إلى `/eld/sessions/connect`، ويعيد المحاولة على
  /// `/eld/sessions/start` عند 404 فقط — كما كان في التنفيذين.
  ///
  /// أي فشل آخر (شبكة، 401، 500، رفض صريح) لا يُعيد المحاولة.
  static Future<Result<ApiResponse<RawJson>>> post({
    required ApiClient apiClient,
    required Map<String, dynamic> payload,
    required ConnectBodyParser parser,
  }) async {
    var res = await apiClient.post<RawJson>(
      EldEndpoints.connectSession,
      data: payload,
      parser: parser,
    );

    if (res.isFailure && res.errorOrNull is NotFoundError) {
      res = await apiClient.post<RawJson>(
        EldEndpoints.startSession,
        data: payload,
        parser: parser,
      );
    }

    return res;
  }

  /// أي `Map` → `Map<String, dynamic>`، وغير ذلك → `{}`.
  static RawJson parsePermissiveBody(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  /// `Map<String, dynamic>` فقط، وغير ذلك → `{}`.
  ///
  /// لا تُوحّد مع [parsePermissiveBody]: مسار جلسة السائق لا يقبل
  /// `Map<dynamic, dynamic>`، وتغيير ذلك تغيير سلوك لا يشمله هذا التوحيد.
  static RawJson parseTypedMapBody(dynamic body) {
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  /// الغلاف يُفكّ في [ApiResponse]؛ هذا يحوّل `data` الغائب إلى `{}` فقط.
  ///
  /// هو السلوك المتراخي القديم لمسار جلسة السائق، وليس تحققاً من صحة
  /// الاستجابة. مسار الأجهزة يستخدم [confirmedPayload] بدلاً منه.
  static RawJson dataOrEmpty(ApiResponse<RawJson> response) {
    return response.data ?? <String, dynamic>{};
  }

  /// `requestId` من جسم الاستجابة، وإلا من الغلاف الذي فكّه [ApiResponse].
  static String? requestIdOf(ApiResponse<RawJson> response) {
    return _requestIdFromRaw(response.rawBody) ?? response.requestId;
  }

  /// علامة رفض صريحة (`success: false` أو `status: false`) — حتى في جسم
  /// `{"success": false}` المجرد الذي لا يعتبره [ApiResponse] غلافاً.
  static String? failureMarkerOf(Object? rawBody) {
    if (rawBody is! Map) return null;
    if (_isFalse(rawBody['success'])) return 'success_false';
    if (_isFalse(rawBody['status'])) return 'status_false';
    return null;
  }

  /// الحمولة التي تكفي لتأكيد الجلسة في مسار الأجهزة، أو `null` إن كانت
  /// ناقصة أو غير صالحة.
  ///
  /// الأجسام الشبيهة بالغلاف يجب أن تحمل `data` كائناً غير فارغ؛ والأجسام
  /// المباشرة يجب أن تكون هي نفسها كائناً غير فارغ. لا يُشترط أي حقل بعينه
  /// لأن مخطط OpenAPI لا يعلن أي حقل إلزامياً.
  static RawJson? confirmedPayload(ApiResponse<RawJson> response) {
    final body = _asStringMap(response.rawBody);
    if (body != null) {
      final isEnvelope =
          body.containsKey('success') ||
          body.containsKey('data') ||
          (body.containsKey('code') && body.containsKey('status'));
      if (isEnvelope) {
        final data = _asStringMap(body['data']);
        if (data == null || data.isEmpty) return null;
        return data;
      }
    }

    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return data;
  }

  static bool _isFalse(Object? value) {
    if (value == false) return true;
    return value is String && value.trim().toLowerCase() == 'false';
  }

  static RawJson? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _requestIdFromRaw(Object? rawBody) {
    if (rawBody is! Map) return null;
    final value = rawBody['requestId'];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
