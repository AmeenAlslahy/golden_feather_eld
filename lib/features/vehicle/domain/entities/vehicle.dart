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

  Vehicle copyWith({
    String? id,
    String? uniqueId,
    int? deviceId,
    String? name,
    String? year,
    String? type,
    String? vin,
    String? trailerId,
    bool? isAssigned,
    String? operationalStatus,
    String? statusReason,
    bool? inUseByOther,
    bool? selectedByServer,
    bool? activeForCurrentDriver,
  }) {
    return Vehicle(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      year: year ?? this.year,
      type: type ?? this.type,
      vin: vin ?? this.vin,
      trailerId: trailerId ?? this.trailerId,
      isAssigned: isAssigned ?? this.isAssigned,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      statusReason: statusReason ?? this.statusReason,
      inUseByOther: inUseByOther ?? this.inUseByOther,
      selectedByServer: selectedByServer ?? this.selectedByServer,
      activeForCurrentDriver:
          activeForCurrentDriver ?? this.activeForCurrentDriver,
    );
  }

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
