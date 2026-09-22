/// Shared value objects across all features.
///
/// **Why value objects?**
/// Prevents the classic bug of passing `deviceId` where `driverId`
/// is expected. Each ID is a distinct type checked at compile time.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_objects.freezed.dart';

@freezed
abstract class UserId with _$UserId {
  const factory UserId(int value) = _UserId;

  factory UserId.fromJson(Map<String, dynamic> json) => UserId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DriverId with _$DriverId {
  const factory DriverId(int value) = _DriverId;

  factory DriverId.fromJson(Map<String, dynamic> json) => DriverId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DeviceId with _$DeviceId {
  const factory DeviceId(int value) = _DeviceId;

  factory DeviceId.fromJson(Map<String, dynamic> json) => DeviceId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class VehicleId with _$VehicleId {
  const factory VehicleId(int value) = _VehicleId;

  factory VehicleId.fromJson(Map<String, dynamic> json) => VehicleId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DailyLogId with _$DailyLogId {
  const factory DailyLogId(int value) = _DailyLogId;

  factory DailyLogId.fromJson(Map<String, dynamic> json) => DailyLogId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DutyStatusId with _$DutyStatusId {
  const factory DutyStatusId(int value) = _DutyStatusId;

  factory DutyStatusId.fromJson(Map<String, dynamic> json) => DutyStatusId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DvirId with _$DvirId {
  const factory DvirId(int value) = _DvirId;

  factory DvirId.fromJson(Map<String, dynamic> json) => DvirId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class InspectionId with _$InspectionId {
  const factory InspectionId(int value) = _InspectionId;

  factory InspectionId.fromJson(Map<String, dynamic> json) => InspectionId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class DocumentId with _$DocumentId {
  const factory DocumentId(int value) = _DocumentId;

  factory DocumentId.fromJson(Map<String, dynamic> json) => DocumentId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class TransferId with _$TransferId {
  const factory TransferId(int value) = _TransferId;

  factory TransferId.fromJson(Map<String, dynamic> json) => TransferId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class RuleId with _$RuleId {
  const factory RuleId(int value) = _RuleId;

  factory RuleId.fromJson(Map<String, dynamic> json) => RuleId(json['value'] as int? ?? json['id'] as int? ?? 0);
}

@freezed
abstract class EditId with _$EditId {
  const factory EditId(String value) = _EditId;

  factory EditId.fromJson(Map<String, dynamic> json) => EditId(json['value'] as String? ?? json['id'] as String? ?? '');
}

// Manual toJson for value objects (flexibility: handle both value and id keys)
extension UserIdJson on UserId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DriverIdJson on DriverId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DeviceIdJson on DeviceId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension VehicleIdJson on VehicleId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DailyLogIdJson on DailyLogId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DutyStatusIdJson on DutyStatusId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DvirIdJson on DvirId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension InspectionIdJson on InspectionId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension DocumentIdJson on DocumentId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension TransferIdJson on TransferId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension RuleIdJson on RuleId {
  Map<String, dynamic> toJson() => {'value': value};
}
extension EditIdJson on EditId {
  Map<String, dynamic> toJson() => {'value': value};
}
