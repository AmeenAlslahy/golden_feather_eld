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

class HardwareAlertsNotifier extends AsyncNotifier<List<HardwareAlert>> {
  Timer? _timer;

  @override
  Future<List<HardwareAlert>> build() async {
    // تحديث التنبيهات كل 30 ثانية
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchAlerts();
    });
    
    // عند إغلاق الـ Provider نقوم بإلغاء المؤقت
    ref.onDispose(() {
      _timer?.cancel();
    });

    return _fetchFromBackend();
  }

  Future<void> fetchAlerts() async {
    state = const AsyncLoading();
    try {
      final alerts = await _fetchFromBackend();
      state = AsyncData(alerts);
    } catch (e, st) {
      state = AsyncError(e, st);
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

final hardwareAlertsProvider = AsyncNotifierProvider<HardwareAlertsNotifier, List<HardwareAlert>>(() {
  return HardwareAlertsNotifier();
});
