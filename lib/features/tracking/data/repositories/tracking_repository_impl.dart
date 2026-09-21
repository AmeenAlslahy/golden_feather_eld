import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_local_data_source.dart';
import '../datasources/native_event_channel_client.dart';
import '../models/location_model.dart';
import '../services/tracking_service.dart';

/// تنفيذ مستودع التتبع
class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingService _service;
  final TrackingLocalDataSource _localDataSource;
  final NativeEventChannelClient _nativeClient;
  final LocalStorageService _storage;

  TrackingRepositoryImpl({
    required TrackingService service,
    required TrackingLocalDataSource localDataSource,
    required NativeEventChannelClient nativeClient,
    required LocalStorageService storage,
  })  : _service = service,
        _localDataSource = localDataSource,
        _nativeClient = nativeClient,
        _storage = storage;

  @override
  Stream<LocationEntity> get locationStream {
    return _nativeClient.locationStream.map((event) {
      return LocationModel(
        latitude: event.latitude,
        longitude: event.longitude,
        speed: event.speedMetersPerSecond,
        altitude: event.altitudeMeters,
        bearing: event.bearingDegrees,
        accuracy: event.accuracyMeters,
        timestamp: event.recordedAt,
        provider: event.source.name,
      );
    });
  }

  @override
  Future<Either<Failure, bool>> startTracking() async {
    try {
      // ١. فحص صلاحية الموقع دائماً (الخلفية) - مطلوبة لعمل Traccar
      var locationStatus = await Permission.locationAlways.status;

      if (!locationStatus.isGranted) {
        // في أندرويد 10+ يجب طلب الصلاحية العادية أولاً ثم الخلفية
        var inUseStatus = await Permission.locationWhenInUse.status;
        if (!inUseStatus.isGranted) {
          inUseStatus = await Permission.locationWhenInUse.request();
        }

        if (inUseStatus.isGranted) {
          locationStatus = await Permission.locationAlways.request();
        }
      }

      if (!locationStatus.isGranted) {
        return const Left(PermissionFailure(
          message: 'صلاحية الموقع في الخلفية مطلوبة',
        ));
      }

      // ٢. فحص إذا كان GPS مفعلاً
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled().catchError(
        (error) => throw Exception('Error updating position: $error'),
      );
      if (!isLocationServiceEnabled) {
        return const Left(PermissionFailure(
          message: 'خدمة الموقع غير مفعلة',
        ));
      }

      // ٣. كل شيء جاهز - ابدأ التتبع
      _nativeClient
          .startListening(); // Subscribe first to establish EventSink in Android
      await _service
          .start(); // Start service which triggers immediate location emission
      AppLogger.info(
          'Tracking service started, waiting for location stream...');
      return const Right(true);
    } catch (e) {
      AppLogger.error('Failed to start tracking', e);
      return const Left(TrackingFailure(
        message: 'فشل بدء التتبع',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> stopTracking() async {
    try {
      await _service.stop();
      _nativeClient.stopListening();
      AppLogger.info('Tracking service stopped');
      return const Right(true);
    } catch (e) {
      AppLogger.error('Failed to stop tracking', e);
      return const Left(TrackingFailure(
        message: 'فشل إيقاف التتبع',
      ));
    }
  }

  @override
  Future<bool> isTracking() async {
    return _service.isTracking();
  }

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async {
    try {
      // نطلب من Traccar تحديث الموقع (إن أمكن)
      await _service.requestPosition();

      // نسترجع آخر موقع مسجل لدينا
      final lastLocation = await _localDataSource.getLastLocation();
      if (lastLocation != null) {
        return Right(lastLocation);
      }

      // Fallback to Geolocator
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final fallbackLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
        bearing: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _localDataSource.saveLastLocation(fallbackLocation);
      return Right(fallbackLocation);
    } catch (e) {
      return const Left(TrackingFailure(
        message: 'فشل الحصول على الموقع',
      ));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> requestPosition(
      {String? alarm}) async {
    try {
      await _service.requestPosition(alarm: alarm);

      final lastLocation = await _localDataSource.getLastLocation();
      if (lastLocation != null) {
        return Right(lastLocation);
      }

      // Fallback to Geolocator
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final fallbackLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
        bearing: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _localDataSource.saveLastLocation(fallbackLocation);
      return Right(fallbackLocation);
    } catch (e) {
      return const Left(TrackingFailure(
        message: 'فشل طلب الموقع',
      ));
    }
  }

  @override
  Future<Either<Failure, List<TrackingLogEntity>>> getLogs() async {
    try {
      final logsData = await _service.getLogs();
      final logs = logsData.map((log) {
        return TrackingLogEntity(
          time: log['time'] as int,
          message: log['message'] as String,
        );
      }).toList();
      return Right(logs);
    } catch (e) {
      return const Left(TrackingFailure(
        message: 'فشل جلب السجلات',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> clearLogs() async {
    try {
      await _localDataSource.clearLogs();
      return const Right(true);
    } catch (e) {
      return const Left(TrackingFailure(
        message: 'فشل مسح السجلات',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> updateConfig(
      TrackingConfigEntity config) async {
    try {
      await _service.updateConfig();
      AppLogger.info('Tracking config updated');
      return const Right(true);
    } catch (e) {
      return const Left(TrackingFailure(
        message: 'فشل تحديث الإعدادات',
      ));
    }
  }

  @override
  Future<TrackingConfigEntity> getCurrentConfig() async {
    return TrackingConfigEntity(
      serverUrl: _storage.serverUrl,
      deviceId: _storage.deviceId,
      accuracy: _storage.accuracy,
      distanceMeters: _storage.distance,
      intervalSeconds: _storage.interval,
      angleDegrees: _storage.angle,
      heartbeatSeconds: _storage.heartbeat,
      buffer: _storage.buffer,
      wakeLock: _storage.wakelock,
      stopDetection: _storage.stopDetection,
      preferPlatformProviders: _storage.preferPlatformProviders,
    );
  }
}
