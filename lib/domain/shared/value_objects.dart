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
}

@freezed
abstract class DriverId with _$DriverId {
  const factory DriverId(int value) = _DriverId;
}

@freezed
abstract class DeviceId with _$DeviceId {
  const factory DeviceId(int value) = _DeviceId;
}

@freezed
abstract class VehicleId with _$VehicleId {
  const factory VehicleId(int value) = _VehicleId;
}

@freezed
abstract class DailyLogId with _$DailyLogId {
  const factory DailyLogId(int value) = _DailyLogId;
}

@freezed
abstract class DutyStatusId with _$DutyStatusId {
  const factory DutyStatusId(int value) = _DutyStatusId;
}

@freezed
abstract class DvirId with _$DvirId {
  const factory DvirId(int value) = _DvirId;
}

@freezed
abstract class InspectionId with _$InspectionId {
  const factory InspectionId(int value) = _InspectionId;
}

@freezed
abstract class DocumentId with _$DocumentId {
  const factory DocumentId(int value) = _DocumentId;
}

@freezed
abstract class TransferId with _$TransferId {
  const factory TransferId(int value) = _TransferId;
}

@freezed
abstract class RuleId with _$RuleId {
  const factory RuleId(int value) = _RuleId;
}

@freezed
abstract class EditId with _$EditId {
  const factory EditId(String value) = _EditId;
}
