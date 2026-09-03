import '../../domain/entities/daily_log.dart';

class LogEventModel extends LogEvent {
  const LogEventModel({
    required super.id,
    required super.status,
    required super.statusArabic,
    required super.startTime,
    required super.duration,
    required super.location,
    super.odometer,
    super.engineHours,
    super.isExpanded,
  });

  factory LogEventModel.fromJson(Map<String, dynamic> json) {
    final statusCode = json['status']?.toString() ?? 'OFF_DUTY';
    final startTimeStr = json['startTime']?.toString() ?? json['time']?.toString();
    final durationSecs = json['duration'] as int? ?? 0;
    
    // Status mappings
    String status = 'OFF';
    String arabic = 'مستراح';
    switch (statusCode.toUpperCase()) {
      case 'DRIVING':
      case 'D':
        status = 'D'; arabic = 'قيادة'; break;
      case 'ON_DUTY':
      case 'ON':
        status = 'ON'; arabic = 'على رأس العمل'; break;
      case 'SLEEPER_BERTH':
      case 'SB':
        status = 'SB'; arabic = 'مقصورة النوم'; break;
      default:
        status = 'OFF'; arabic = 'مستراح';
    }

    return LogEventModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      status: status,
      statusArabic: arabic,
      startTime: startTimeStr != null ? DateTime.parse(startTimeStr).toLocal() : DateTime.now(),
      duration: Duration(seconds: durationSecs),
      location: json['location']?.toString() ?? 'Unknown Location',
      odometer: json['odometer'] != null ? double.tryParse(json['odometer'].toString()) : null,
      engineHours: json['engineHours'] != null ? double.tryParse(json['engineHours'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'location': location,
      'odometer': odometer,
      'engineHours': engineHours,
    };
  }

  factory LogEventModel.fromEntity(LogEvent entity) {
    return LogEventModel(
      id: entity.id,
      status: entity.status,
      statusArabic: entity.statusArabic,
      startTime: entity.startTime,
      duration: entity.duration,
      location: entity.location,
      odometer: entity.odometer,
      engineHours: entity.engineHours,
      isExpanded: entity.isExpanded,
    );
  }
}
