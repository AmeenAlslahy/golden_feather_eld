import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../features/tracking/data/services/tracking_service.dart';
import '../../routes.dart';
import '../utils/logger.dart';
import 'local_storage_service.dart';

/// خدمة الإشعارات - من push_service.dart الأصلي
class PushNotificationService {
  final TrackingService _trackingService;
  final LocalStorageService _storage;

  PushNotificationService({
    required TrackingService trackingService,
    required LocalStorageService storage,
  })  : _trackingService = trackingService,
        _storage = storage;

  /// تهيئة الخدمة
  static Future<void> init({
    required TrackingService trackingService,
    required LocalStorageService storage,
  }) async {
    if (Firebase.apps.isEmpty) {
      AppLogger.warning(
          'Firebase is not initialized. PushNotificationService is disabled.');
      return;
    }

    final service = PushNotificationService(
      trackingService: trackingService,
      storage: storage,
    );

    try {
      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
      FirebaseMessaging.onMessage.listen(service._onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(service._onMessageOpenedApp);
      FirebaseMessaging.instance.onTokenRefresh
          .listen((token) => service._uploadToken(token));

      unawaited(service._uploadInitialToken());
      AppLogger.info('📨 PushNotificationService initialized');
    } catch (e) {
      AppLogger.error('Error during Firebase Messaging setup', e);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    final storage = LocalStorageService();
    await storage.init();

    // معالجة الأمر في الخلفية
    final command = message.data['command'];
    FirebaseCrashlytics.instance.log('push_background: $command');

    if (command == 'positionSingle') {
      // لا يمكن بدء التتبع من الخلفية بدون تهيئة كاملة
      AppLogger.info('📨 Background push ignored: $command');
    }
  }

  Future<void> _onMessage(RemoteMessage message) async {
    final command = message.data['command'];
    final eventId = message.data['eventId'];

    if (command != null) {
      FirebaseCrashlytics.instance.log('push_command: $command');
      AppLogger.info('📨 Push command received: $command');

      try {
        switch (command) {
          case 'positionSingle':
            await _trackingService.requestPosition();
          case 'positionPeriodic':
            await _trackingService.start();
          case 'positionStop':
            await _trackingService.stop();
          case 'factoryReset':
            // TODO(Phase5): reimplement password management.
            AppLogger.info('🏭 Factory reset: password cleared');
        }
      } on PlatformException {
        AppLogger.error('Platform exception in push handler');
      }
    }

    if (eventId != null) {
      AppLogger.info('📨 Push event received: $eventId');
      final notification = message.notification;
      if (notification != null) {
        _showInAppNotification(notification.title ?? 'تنبيه',
            notification.body ?? 'حدث جديد من Traccar');
      }
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final eventId = message.data['eventId'];
    if (eventId != null) {
      AppLogger.info('📨 App opened from push event: $eventId');
      // توجيه المستخدم إلى صفحة الأحداث (مثلاً: الأحداث المقترحة أو غير المحددة)
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        context.push(AppRoutes.unidentifiedEvents);
      }
    }
  }

  void _showInAppNotification(String title, String body) {
    final context = scaffoldMessengerKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadToken(String? token) async {
    if (token == null) return;
    final id = _storage.deviceId;
    final url = _storage.serverUrl;
    if (id.isEmpty || url.isEmpty) return;

    try {
      final request = await HttpClient().postUrl(Uri.parse(url));
      request.headers.contentType =
          ContentType.parse('application/x-www-form-urlencoded');
      request.write(
          'id=${Uri.encodeComponent(id)}&notificationToken=${Uri.encodeComponent(token)}');
      await request.close();
      AppLogger.info('📤 Token uploaded to server');
    } catch (e) {
      AppLogger.error('Failed to upload token', e);
    }
  }

  Future<void> _uploadInitialToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _uploadToken(token);
    } catch (e) {
      AppLogger.error('Failed to get initial token', e);
    }
  }
}
