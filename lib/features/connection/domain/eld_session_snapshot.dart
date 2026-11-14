import 'dart:convert';

/// أصل الجلسة كما يعرفه الجهاز.
enum EldSessionOrigin {
  /// جلسة أكدها السيرفر (`POST /eld/sessions/connect` أو `GET /eld/sessions/{id}`).
  server,

  /// جلسة بدأت محلياً أثناء انقطاع الشبكة، بانتظار تأكيد السيرفر.
  localPending,

  /// "متابعة بدون اتصال" بدأت محلياً (manualMode) ولم تُؤكد بعد.
  localManual,
}

enum EldSessionSyncState { synced, pending }

/// لقطة جلسة السائق.
///
/// سبب وجودها: `GET /eld/sessions/{driverId}` هو مصدر الحقيقة، لكن رده قد
/// يخلو من `vehicle` (كما في العقد الحيّ)، ولا يمكن الاعتماد عليه لاستعادة
/// السياق بعد إعادة تشغيل التطبيق. لذلك نحفظ لقطة كاملة عند الاتصال، ثم
/// نُصحّحها من السيرفر عند العودة.
class EldSessionSnapshot {
  final int driverId;
  final int? sessionId;

  /// معرّف محلي ثابت (UUID) للجلسات التي بدأت بلا سيرفر.
  final String? localId;

  final String? vehicleUniqueId;
  final String? vehicleName;
  final int? carrierId;

  /// `ACTIVE` / `CLOSED` / `ABORTED` كما يعيدها السيرفر.
  final String? status;

  /// `CONNECTED` / `DISCONNECTED` / ... كما يعيدها السيرفر.
  final String? connectionStatus;

  final bool manualMode;
  final DateTime startedAt;
  final DateTime? lastSyncedAt;

  final EldSessionOrigin origin;
  final EldSessionSyncState syncState;

  final double? odometerStart;
  final double? engineHoursStart;

  /// MAC جهاز البلوتوث المرتبط محلياً (لا يُرسل للسيرفر كـ deviceId).
  final String? bleMac;

  final String? serverMessage;

  const EldSessionSnapshot({
    required this.driverId,
    this.sessionId,
    this.localId,
    this.vehicleUniqueId,
    this.vehicleName,
    this.carrierId,
    this.status,
    this.connectionStatus,
    this.manualMode = false,
    required this.startedAt,
    this.lastSyncedAt,
    this.origin = EldSessionOrigin.server,
    this.syncState = EldSessionSyncState.synced,
    this.odometerStart,
    this.engineHoursStart,
    this.bleMac,
    this.serverMessage,
  });

  bool get isActive => (status ?? '').toUpperCase() == 'ACTIVE';

  bool get isConnected =>
      (connectionStatus ?? '').toUpperCase() == 'CONNECTED';

  bool get isServerConfirmed =>
      origin == EldSessionOrigin.server &&
      syncState == EldSessionSyncState.synced;

  /// هل تؤكد هذه البيانات أن الجلسة نشطة فعلاً على السيرفر؟
  ///
  /// غياب `status` و`connectionStatus` معاً = خادم أقدم لا يعيد الحكم؛
  /// نعتبره مؤكداً للتوافق. وجود أي منهما يجعل الحكم صريحاً:
  /// * `status` يجب أن يكون `ACTIVE`.
  /// * في الوضع اليدوي (`manualMode`) لا يُشترط `CONNECTED` لأن السائق
  ///   يعمل بلا جهاز متصل.
  /// * خلاف ذلك `CONNECTED` مطلوب (أو غياب `connectionStatus`).
  bool get confirmedByServer {
    final hasVerdict = status != null || connectionStatus != null;
    return !hasVerdict ||
        (isActive && (manualMode || connectionStatus == null || isConnected));
  }

  EldSessionSnapshot copyWith({
    int? sessionId,
    String? localId,
    String? vehicleUniqueId,
    String? vehicleName,
    int? carrierId,
    String? status,
    String? connectionStatus,
    bool? manualMode,
    DateTime? startedAt,
    DateTime? lastSyncedAt,
    EldSessionOrigin? origin,
    EldSessionSyncState? syncState,
    double? odometerStart,
    double? engineHoursStart,
    String? bleMac,
    String? serverMessage,
  }) {
    return EldSessionSnapshot(
      driverId: driverId,
      sessionId: sessionId ?? this.sessionId,
      localId: localId ?? this.localId,
      vehicleUniqueId: vehicleUniqueId ?? this.vehicleUniqueId,
      vehicleName: vehicleName ?? this.vehicleName,
      carrierId: carrierId ?? this.carrierId,
      status: status ?? this.status,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      manualMode: manualMode ?? this.manualMode,
      startedAt: startedAt ?? this.startedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      origin: origin ?? this.origin,
      syncState: syncState ?? this.syncState,
      odometerStart: odometerStart ?? this.odometerStart,
      engineHoursStart: engineHoursStart ?? this.engineHoursStart,
      bleMac: bleMac ?? this.bleMac,
      serverMessage: serverMessage ?? this.serverMessage,
    );
  }

  /// يبني اللقطة من جسم `data` في رد `/eld/sessions/**`.
  ///
  /// قواعد العقد:
  /// * `sessionId` و`id` يحملان الوصف نفسه؛ نُفضّل `sessionId` ثم `id`.
  /// * `vehicle` قد يكون غائباً في `GET`؛ نُبقي القيمة المحفوظة عندها.
  /// * `endedAt` قد يكون ممتلئاً مع `ACTIVE` في أمثلة الخادم؛ الحاكم هو `status`.
  factory EldSessionSnapshot.fromServerData(
    Map<String, dynamic> data, {
    required int driverId,
    String? fallbackVehicleUniqueId,
    String? fallbackVehicleName,
    int? fallbackCarrierId,
    DateTime? fallbackStartedAt,
    bool manualMode = false,
    String? bleMac,
    String? serverMessage,
  }) {
    final vehicle = data['vehicle'];
    final vehicleMap = vehicle is Map
        ? Map<String, dynamic>.from(vehicle)
        : const <String, dynamic>{};
    final carrier = data['carrier'];
    final carrierMap = carrier is Map
        ? Map<String, dynamic>.from(carrier)
        : const <String, dynamic>{};
    final odometer = data['odometer'];
    final odometerMap = odometer is Map
        ? Map<String, dynamic>.from(odometer)
        : const <String, dynamic>{};
    final engineHours = data['engineHours'];
    final engineHoursMap = engineHours is Map
        ? Map<String, dynamic>.from(engineHours)
        : const <String, dynamic>{};

    final driver = data['driver'];
    final responseDriverId = driver is Map ? _asInt(driver['id']) : null;

    return EldSessionSnapshot(
      driverId: responseDriverId ?? driverId,
      sessionId: _asInt(data['sessionId']) ?? _asInt(data['id']),
      vehicleUniqueId:
          _asText(vehicleMap['uniqueId']) ?? fallbackVehicleUniqueId,
      vehicleName:
          _asText(vehicleMap['name']) ??
          _asText(vehicleMap['identifier']) ??
          fallbackVehicleName,
      carrierId: _asInt(carrierMap['id']) ?? fallbackCarrierId,
      status: _asText(data['status'])?.toUpperCase(),
      connectionStatus: _asText(data['connectionStatus'])?.toUpperCase(),
      manualMode: manualMode,
      startedAt:
          _asDate(data['startedAt']) ??
          _asDate(data['sessionStartedAt']) ??
          fallbackStartedAt ??
          DateTime.now().toUtc(),
      lastSyncedAt: DateTime.now().toUtc(),
      origin: EldSessionOrigin.server,
      syncState: EldSessionSyncState.synced,
      odometerStart: _asDouble(odometerMap['start']),
      engineHoursStart: _asDouble(engineHoursMap['start']),
      bleMac: bleMac,
      serverMessage: serverMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      if (sessionId != null) 'sessionId': sessionId,
      if (localId != null) 'localId': localId,
      if (vehicleUniqueId != null) 'vehicleUniqueId': vehicleUniqueId,
      if (vehicleName != null) 'vehicleName': vehicleName,
      if (carrierId != null) 'carrierId': carrierId,
      if (status != null) 'status': status,
      if (connectionStatus != null) 'connectionStatus': connectionStatus,
      'manualMode': manualMode,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (lastSyncedAt != null)
        'lastSyncedAt': lastSyncedAt!.toUtc().toIso8601String(),
      'origin': origin.name,
      'syncState': syncState.name,
      if (odometerStart != null) 'odometerStart': odometerStart,
      if (engineHoursStart != null) 'engineHoursStart': engineHoursStart,
      if (bleMac != null) 'bleMac': bleMac,
      if (serverMessage != null) 'serverMessage': serverMessage,
    };
  }

  factory EldSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return EldSessionSnapshot(
      driverId: _asInt(json['driverId']) ?? 0,
      sessionId: _asInt(json['sessionId']),
      localId: _asText(json['localId']),
      vehicleUniqueId: _asText(json['vehicleUniqueId']),
      vehicleName: _asText(json['vehicleName']),
      carrierId: _asInt(json['carrierId']),
      status: _asText(json['status']),
      connectionStatus: _asText(json['connectionStatus']),
      manualMode: json['manualMode'] == true,
      startedAt: _asDate(json['startedAt']) ?? DateTime.now().toUtc(),
      lastSyncedAt: _asDate(json['lastSyncedAt']),
      origin: _originFromName(_asText(json['origin'])),
      syncState: _syncStateFromName(_asText(json['syncState'])),
      odometerStart: _asDouble(json['odometerStart']),
      engineHoursStart: _asDouble(json['engineHoursStart']),
      bleMac: _asText(json['bleMac']),
      serverMessage: _asText(json['serverMessage']),
    );
  }

  static String encode(EldSessionSnapshot snapshot) =>
      jsonEncode(snapshot.toJson());

  static EldSessionSnapshot? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return EldSessionSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static EldSessionOrigin _originFromName(String? name) {
    switch (name) {
      case 'localPending':
        return EldSessionOrigin.localPending;
      case 'localManual':
        return EldSessionOrigin.localManual;
      default:
        return EldSessionOrigin.server;
    }
  }

  static EldSessionSyncState _syncStateFromName(String? name) {
    return name == 'pending'
        ? EldSessionSyncState.pending
        : EldSessionSyncState.synced;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _asText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static DateTime? _asDate(Object? value) {
    final text = _asText(value);
    if (text == null) return null;
    return DateTime.tryParse(text)?.toUtc();
  }
}
