import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';

class HardwareAlert {
  final String id;
  final String type;
  final String message;
  final DateTime? timestamp;

  HardwareAlert({
    required this.id,
    required this.type,
    required this.message,
    this.timestamp,
  });

  factory HardwareAlert.fromJson(Map<String, dynamic> json) {
    final rawTime = json['timestamp']?.toString();
    return HardwareAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: rawTime == null || rawTime.isEmpty
          ? null
          : DateTime.tryParse(rawTime),
    );
  }
}

class HardwareAlertsNotifier extends AutoDisposeAsyncNotifier<List<HardwareAlert>> {
  Timer? _timer;

  @override
  Future<List<HardwareAlert>> build() async {
    // تحديث التنبيهات كل 30 ثانية
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchAlerts();
    });

    // المزوّد autoDispose: عند اختفاء آخر مستمع يُلغى المؤقت ويقف
    // الاستقصاء الدوري بدل أن يستمر طوال عمر التطبيق.
    ref.onDispose(() {
      _timer?.cancel();
    });

    return _fetchFromBackend();
  }

  /// تحديث دوري صامت: لا تمر عبر AsyncLoading حتى لا يومض العرض كل
  /// 30 ثانية، وعند الفشل تبقى البيانات الصالحة السابقة معروضة.
  Future<void> fetchAlerts() async {
    try {
      final alerts = await _fetchFromBackend();
      state = AsyncData(alerts);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<List<HardwareAlert>> _fetchFromBackend() async {
    final backend = ref.read(hardwareBackendProvider);
    final result = await backend.getAlerts();
    
    return result.fold(
      (failure) => throw Exception(failure.l10nKey),
      (json) {
        final alertsList = _alertList(json);
        if (alertsList == null) {
          throw Exception('Hardware alerts response was not a list');
        }
        if (alertsList.isEmpty) return [];

        return alertsList.map((e) {
          // If the API returns a string directly
          if (e is String) {
            return HardwareAlert(
              id: '',
              type: '',
              message: e,
            );
          }
          if (e is Map<String, dynamic>) {
            return HardwareAlert.fromJson(e);
          }
          return HardwareAlert(
            id: '',
            type: '',
            message: e.toString(),
          );
        }).where((alert) => alert.message.trim().isNotEmpty).toList();
      },
    );
  }
}

List<dynamic>? _alertList(Map<String, dynamic> json) {
  if (json['alerts'] is List) return json['alerts'] as List;
  final data = json['data'];
  if (data is List) return data;
  if (data is Map && data['alerts'] is List) return data['alerts'] as List;
  if (!json.containsKey('alerts') && !json.containsKey('data')) return [];
  return null;
}

final hardwareAlertsProvider =
    AsyncNotifierProvider.autoDispose<HardwareAlertsNotifier, List<HardwareAlert>>(() {
  return HardwareAlertsNotifier();
});
