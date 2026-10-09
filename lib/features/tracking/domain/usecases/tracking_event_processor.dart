import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';
import '../../../../core/utils/logger.dart';

import '../entities/tracking_event.dart';
import '../entities/connection_status.dart';
import '../repositories/tracking_data_source_port.dart';
// For EldEvent
import '../../../../core/domain/entities/location_point.dart';

/// المحرك المركزي الذي يستقبل أحداث التتبع (TrackingEvent) من المصدر
/// ويقوم بتوزيعها على محركات التطبيق (HOS, Diagnostics, Distance)
/// عبر محول (Mapper) داخلي بحيث لا تعرف هذه المحركات أي شيء عن Traccar.
class TrackingEventProcessor {
  final TrackingDataSourcePort? _trackingDataSource;
  final StreamController<EldEvent> _eldEventsController =
      StreamController<EldEvent>.broadcast();
  final StreamController<LocationPoint> _locationEventsController =
      StreamController<LocationPoint>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  StreamSubscription? _subscription;
  StreamSubscription? _connectionSubscription;
  Timer? _mockTimer;

  TrackingEventProcessor({
    TrackingDataSourcePort? trackingDataSource,
  }) : _trackingDataSource = trackingDataSource;

  Stream<EldEvent> get eldEventsStream => _eldEventsController.stream;
  Stream<LocationPoint> get locationStream => _locationEventsController.stream;
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  void startProcessing() {
    if (_trackingDataSource != null) {
      _subscription = _trackingDataSource.events.listen(_processTrackingEvent);
      _connectionSubscription =
          _trackingDataSource.connectionStatusStream.listen((status) {
        _connectionStatusController.add(status);
      });
    } else {
      _startMockProcessing();
    }
  }

  // --- Mock Support للمحافظة على التوافق مع وضع التطوير القديم ---
  void _startMockProcessing() {
    // محاكاة الاتصال الناجح في وضع Mock
    _connectionStatusController.add(ConnectionStatus.connected);

    double mockSpeed = 0.0;
    double mockLat = 24.7136;
    double mockLon = 46.6753;

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      mockSpeed = (mockSpeed < 60.0) ? mockSpeed + 5.0 : 60.0;
      mockLat += 0.0001;
      mockLon += 0.0001;

      final now = DateTime.now();

      _eldEventsController.add(EldEvent(
        timestamp: now,
        speedMph: mockSpeed,
        speedDurationSeconds: 5,
        odometerMiles: null,
        engineHours: null,
        fromEcm: true, // مهم جداً: جعل محرك HOS يعتقد أن هذه الأحداث حقيقية لاختبار التحويل للقيادة
      ));

      _locationEventsController.add(LocationPoint(
        latitude: mockLat,
        longitude: mockLon,
        timestamp: now,
      ));
    });
  }

  void _processTrackingEvent(TrackingEvent event) {
    AppLogger.info(
        '📍 [TrackingEventProcessor] Received event: Lat=${event.latitude}, Lon=${event.longitude}, Speed=${event.speed}');
    // 1. تحويل الحدث إلى EldEvent لمحرك HOS و Diagnostics
    final eldEvent = _mapToEldEvent(event);
    _eldEventsController.add(eldEvent);

    // 2. تحويل الحدث إلى LocationPoint لمحرك المسافة والموقع
    final locationPoint = _mapToLocationPoint(event);
    _locationEventsController.add(locationPoint);
  }

  EldEvent _mapToEldEvent(TrackingEvent event) {
    // 3. الحفاظ على إشارة fromEcm التي قد تأتي من البلوتوث (OBD)
    // أو إذا كان الحدث مسجلاً صراحة بأنه قادم من obd
    final isFromEcm = event.source == TrackingEventSource.obd || 
                      event.metadata['fromEcm'] == true;

    return EldEvent(
      timestamp: event.timestampUtc,
      speedMph: event.speed * 2.23694,
      speedDurationSeconds: 0,
      odometerMiles: event.odometer,
      engineHours: event.engineHours,
      fromEcm: isFromEcm, // الحفاظ على إشارة ECM!
    );
  }

  LocationPoint _mapToLocationPoint(TrackingEvent event) {
    return LocationPoint(
      latitude: event.latitude,
      longitude: event.longitude,
      timestamp: event.timestampUtc,
    );
  }

  void dispose() {
    _mockTimer?.cancel();
    _subscription?.cancel();
    _connectionSubscription?.cancel();
    _eldEventsController.close();
    _locationEventsController.close();
    _connectionStatusController.close();
  }
}
