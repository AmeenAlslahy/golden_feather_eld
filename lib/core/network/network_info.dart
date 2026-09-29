import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Stream<bool> get onConnectionChange;
  bool get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  // Optimistic until the first real reading: a cold start must not turn every
  // repository call into NetworkFailure before Connectivity has reported once.
  // The real state is read immediately via checkConnectivity() below.
  bool _currentStatus = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  /// فحص الوصول الفعلي: connectivity_plus يرى "واجهة شبكة" فقط —
  /// واي فاي بلا إنترنت كان يُعدّ متصلاً فتدخل كل الطلبات مهلات كاملة
  /// (إحساس التجمد). الفحص الحقيقي يصحح الحالة خلال ثوانٍ.
  bool _platformAlive = true;
  bool _probing = false;
  Timer? _recoverTimer;

  NetworkInfoImpl() : _connectivity = Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _setStatus(!result.contains(ConnectivityResult.none));
    });
    _readInitial();
  }

  Future<void> _readInitial() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _setStatus(!result.contains(ConnectivityResult.none));
      unawaited(_confirmRealInternet());
    } catch (_) {
      // No platform channel (tests / unsupported host): keep the optimistic
      // value and disable real-reachability probing.
      _platformAlive = false;
    }
  }

  void _setStatus(bool online) {
    if (online == _currentStatus) return;
    _currentStatus = online;
    if (!_controller.isClosed) _controller.add(_currentStatus);
    _syncRecoveryProbe();
  }

  /// عند الوهلة "واجهة متاحة لكن لا إنترنت" نعيد الفحص دورياً حتى يرجع
  /// الوصول — العودة للاتصال تشغّل مزامنة الطابور تلقائياً عبر البث.
  void _syncRecoveryProbe() {
    if (_currentStatus || !_platformAlive) {
      _recoverTimer?.cancel();
      _recoverTimer = null;
      return;
    }
    _recoverTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_confirmRealInternet());
    });
  }

  Future<void> _confirmRealInternet() async {
    if (_probing || !_platformAlive) return;
    _probing = true;
    try {
      final real = await InternetConnectionChecker.instance
          .hasConnection
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
      // المسبار **للترقية فقط**: فشل فحص جهة خارجية (حجب google/cloudflare
      // على شبكات بعينها) لا يجعل الجهاز أوفلاين — كان يقلب الحالة رغم أن
      // خادم ELD نفسه متاح. التخفيض يبقى حكراً على connectivity الفعلي،
      // والشبكة الوهمية تُعالجها مهلة الاتصال المحدودة (12ث) لا المسبار.
      if (real && !_currentStatus) {
        _setStatus(true);
      }
    } catch (_) {
      // فشل الفحص نفسه: نبقي قيمة connectivity كما هي.
    } finally {
      _probing = false;
      _syncRecoveryProbe();
    }
  }

  @override
  Stream<bool> get onConnectionChange => _controller.stream;

  @override
  bool get isConnected => _currentStatus;

  void dispose() {
    _subscription?.cancel();
    _recoverTimer?.cancel();
    _controller.close();
  }
}
