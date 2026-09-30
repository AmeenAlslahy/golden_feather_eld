import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Stream<bool> get onConnectionChange;
  bool get isConnected;
}

/// حالة الشبكة من connectivity_plus فقط.
///
/// ملاحظة تصميم (2026-10-01): جرّبنا مسبار وصول حقيقي
/// (internet_connection_checker) داخل هذه الخدمة — سحبنا نهائياً:
/// 1) المسبار كان يخفض الحالة إلى أوفلاين على شبكات تحجب مضيفات الفحص
///    (بلاغ المالك: التطبيق يقول "لا يوجد إنترنت" وهو متصل).
/// 2) مؤقتات/sockets المسبار تتسرب إلى مناطق FakeAsync في الاختبارات
///    فتكسر اختبارات عشوائياً حسب ترتيب التنفيذ.
/// حالة "واجهة متاحة بلا إنترنت" يعالجها حد مهلة الاتصال المحدود
/// (12 ثانية) + ميزانية إعادة المحاولة — لا مسبار.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  // Optimistic until the first real reading: a cold start must not turn every
  // repository call into NetworkFailure before Connectivity has reported once.
  // The real state is read immediately via checkConnectivity() below.
  bool _currentStatus = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  NetworkInfoImpl() : _connectivity = Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _currentStatus = !result.contains(ConnectivityResult.none);
      if (!_controller.isClosed) _controller.add(_currentStatus);
    });
    _readInitial();
  }

  Future<void> _readInitial() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _currentStatus = !result.contains(ConnectivityResult.none);
      if (!_controller.isClosed) _controller.add(_currentStatus);
    } catch (_) {
      // No platform channel (tests / unsupported host): keep the optimistic value.
    }
  }

  @override
  Stream<bool> get onConnectionChange => _controller.stream;

  @override
  bool get isConnected => _currentStatus;

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
