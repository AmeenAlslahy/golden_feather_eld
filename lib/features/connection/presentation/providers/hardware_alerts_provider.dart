import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';

class HardwareAlert {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  
  HardwareAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory HardwareAlert.fromJson(Map<String, dynamic> json) {
    return HardwareAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? 'No message provided',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
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
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null || !data.containsKey('alerts')) return [];
        
        final alertsList = data['alerts'] as List?;
        if (alertsList == null || alertsList.isEmpty) return [];

        return alertsList.map((e) {
          // If the API returns a string directly
          if (e is String) {
            return HardwareAlert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'system',
              message: e,
              timestamp: DateTime.now(),
            );
          }
          // Fallback to object mapping if API changes back
          if (e is Map<String, dynamic>) {
            return HardwareAlert.fromJson(e);
          }
          return HardwareAlert(
            id: '0',
            type: 'unknown',
            message: e.toString(),
            timestamp: DateTime.now(),
          );
        }).toList();
      },
    );
  }
}

final hardwareAlertsProvider = AsyncNotifierProvider<HardwareAlertsNotifier, List<HardwareAlert>>(() {
  return HardwareAlertsNotifier();
});
