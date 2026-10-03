import 'package:equatable/equatable.dart';

/// كيان المركبة
class Vehicle extends Equatable {
  final String id;
  final String? uniqueId;

  /// معرف جهاز المركبة الرقمي (Traccar deviceId) — مطلوب في جسم إنشاء
  /// DVIR من الخادم؛ لا يُستبدل بـ uniqueId ولا يُخترع.
  final int? deviceId;
  final String name;
  final String year;
  final String? type;
  final String? vin;
  final String? trailerId;
  final bool isAssigned;
  final String? operationalStatus;
  final String? statusReason;
  final bool? inUseByOther;
  final bool? selectedByServer;
  final bool? activeForCurrentDriver;

  const Vehicle({
    required this.id,
    this.uniqueId,
    this.deviceId,
    required this.name,
    required this.year,
    this.type,
    this.vin,
    this.trailerId,
    this.isAssigned = false,
    this.operationalStatus,
    this.statusReason,
    this.inUseByOther,
    this.selectedByServer,
    this.activeForCurrentDriver,
  });

  String get displayName {
    final bits = <String>[
      if (id.isNotEmpty) id,
      if (year.isNotEmpty) year,
      if (name.isNotEmpty) name,
    ];
    return bits.join(' | ');
  }

  String get shortDisplayName => name.isEmpty ? id : '$id - $name';

  @override
  List<Object?> get props => [
    id,
    uniqueId,
    deviceId,
    name,
    year,
    type,
    vin,
    trailerId,
    isAssigned,
    operationalStatus,
    statusReason,
    inUseByOther,
    selectedByServer,
    activeForCurrentDriver,
  ];
}
