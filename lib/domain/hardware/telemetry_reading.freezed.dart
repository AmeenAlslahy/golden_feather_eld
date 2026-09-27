// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'telemetry_reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TelemetryReading {

 DriverId get driverId;/// Vehicle speed in **meters per second** (canonical).
///
/// Mappers convert to the backend's wire unit.
 double get speedMps;/// Engine RPM (raw value from ECM).
 double? get rpm;/// Cumulative odometer reading in **miles**.
///
/// `null` when the vehicle does not report it.
 double? get odometerMiles;/// Cumulative engine hours since vehicle manufacture.
///
/// `null` when the vehicle does not report it.
 double? get engineHours;/// Whether the engine is currently running.
///
/// `null` when unknown.
 bool? get engineOn;
/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TelemetryReadingCopyWith<TelemetryReading> get copyWith => _$TelemetryReadingCopyWithImpl<TelemetryReading>(this as TelemetryReading, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TelemetryReading&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.speedMps, speedMps) || other.speedMps == speedMps)&&(identical(other.rpm, rpm) || other.rpm == rpm)&&(identical(other.odometerMiles, odometerMiles) || other.odometerMiles == odometerMiles)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.engineOn, engineOn) || other.engineOn == engineOn));
}


@override
int get hashCode => Object.hash(runtimeType,driverId,speedMps,rpm,odometerMiles,engineHours,engineOn);

@override
String toString() {
  return 'TelemetryReading(driverId: $driverId, speedMps: $speedMps, rpm: $rpm, odometerMiles: $odometerMiles, engineHours: $engineHours, engineOn: $engineOn)';
}


}

/// @nodoc
abstract mixin class $TelemetryReadingCopyWith<$Res>  {
  factory $TelemetryReadingCopyWith(TelemetryReading value, $Res Function(TelemetryReading) _then) = _$TelemetryReadingCopyWithImpl;
@useResult
$Res call({
 DriverId driverId, double speedMps, double? rpm, double? odometerMiles, double? engineHours, bool? engineOn
});


$DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class _$TelemetryReadingCopyWithImpl<$Res>
    implements $TelemetryReadingCopyWith<$Res> {
  _$TelemetryReadingCopyWithImpl(this._self, this._then);

  final TelemetryReading _self;
  final $Res Function(TelemetryReading) _then;

/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? speedMps = null,Object? rpm = freezed,Object? odometerMiles = freezed,Object? engineHours = freezed,Object? engineOn = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,speedMps: null == speedMps ? _self.speedMps : speedMps // ignore: cast_nullable_to_non_nullable
as double,rpm: freezed == rpm ? _self.rpm : rpm // ignore: cast_nullable_to_non_nullable
as double?,odometerMiles: freezed == odometerMiles ? _self.odometerMiles : odometerMiles // ignore: cast_nullable_to_non_nullable
as double?,engineHours: freezed == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double?,engineOn: freezed == engineOn ? _self.engineOn : engineOn // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}


/// @nodoc


class _TelemetryReading implements TelemetryReading {
  const _TelemetryReading({required this.driverId, required this.speedMps, this.rpm, this.odometerMiles, this.engineHours, this.engineOn});
  

@override final  DriverId driverId;
/// Vehicle speed in **meters per second** (canonical).
///
/// Mappers convert to the backend's wire unit.
@override final  double speedMps;
/// Engine RPM (raw value from ECM).
@override final  double? rpm;
/// Cumulative odometer reading in **miles**.
///
/// `null` when the vehicle does not report it.
@override final  double? odometerMiles;
/// Cumulative engine hours since vehicle manufacture.
///
/// `null` when the vehicle does not report it.
@override final  double? engineHours;
/// Whether the engine is currently running.
///
/// `null` when unknown.
@override final  bool? engineOn;

/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TelemetryReadingCopyWith<_TelemetryReading> get copyWith => __$TelemetryReadingCopyWithImpl<_TelemetryReading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TelemetryReading&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.speedMps, speedMps) || other.speedMps == speedMps)&&(identical(other.rpm, rpm) || other.rpm == rpm)&&(identical(other.odometerMiles, odometerMiles) || other.odometerMiles == odometerMiles)&&(identical(other.engineHours, engineHours) || other.engineHours == engineHours)&&(identical(other.engineOn, engineOn) || other.engineOn == engineOn));
}


@override
int get hashCode => Object.hash(runtimeType,driverId,speedMps,rpm,odometerMiles,engineHours,engineOn);

@override
String toString() {
  return 'TelemetryReading(driverId: $driverId, speedMps: $speedMps, rpm: $rpm, odometerMiles: $odometerMiles, engineHours: $engineHours, engineOn: $engineOn)';
}


}

/// @nodoc
abstract mixin class _$TelemetryReadingCopyWith<$Res> implements $TelemetryReadingCopyWith<$Res> {
  factory _$TelemetryReadingCopyWith(_TelemetryReading value, $Res Function(_TelemetryReading) _then) = __$TelemetryReadingCopyWithImpl;
@override @useResult
$Res call({
 DriverId driverId, double speedMps, double? rpm, double? odometerMiles, double? engineHours, bool? engineOn
});


@override $DriverIdCopyWith<$Res> get driverId;

}
/// @nodoc
class __$TelemetryReadingCopyWithImpl<$Res>
    implements _$TelemetryReadingCopyWith<$Res> {
  __$TelemetryReadingCopyWithImpl(this._self, this._then);

  final _TelemetryReading _self;
  final $Res Function(_TelemetryReading) _then;

/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? speedMps = null,Object? rpm = freezed,Object? odometerMiles = freezed,Object? engineHours = freezed,Object? engineOn = freezed,}) {
  return _then(_TelemetryReading(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,speedMps: null == speedMps ? _self.speedMps : speedMps // ignore: cast_nullable_to_non_nullable
as double,rpm: freezed == rpm ? _self.rpm : rpm // ignore: cast_nullable_to_non_nullable
as double?,odometerMiles: freezed == odometerMiles ? _self.odometerMiles : odometerMiles // ignore: cast_nullable_to_non_nullable
as double?,engineHours: freezed == engineHours ? _self.engineHours : engineHours // ignore: cast_nullable_to_non_nullable
as double?,engineOn: freezed == engineOn ? _self.engineOn : engineOn // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of TelemetryReading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverIdCopyWith<$Res> get driverId {
  
  return $DriverIdCopyWith<$Res>(_self.driverId, (value) {
    return _then(_self.copyWith(driverId: value));
  });
}
}

// dart format on
