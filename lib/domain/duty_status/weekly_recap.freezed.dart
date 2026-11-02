// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_recap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeeklyRecap {

 CycleRule get cycleRule; Duration get cycleUsed; Duration get cycleRemaining; Duration get availableTomorrow; List<RecapDay> get days;/// Structured time values distinguishing present/missing/invalid
/// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
 RecapTimeValue? get cycleUsedTime; RecapTimeValue? get cycleRemainingTime; RecapTimeValue? get availableTomorrowTime;
/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyRecapCopyWith<WeeklyRecap> get copyWith => _$WeeklyRecapCopyWithImpl<WeeklyRecap>(this as WeeklyRecap, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyRecap&&(identical(other.cycleRule, cycleRule) || other.cycleRule == cycleRule)&&(identical(other.cycleUsed, cycleUsed) || other.cycleUsed == cycleUsed)&&(identical(other.cycleRemaining, cycleRemaining) || other.cycleRemaining == cycleRemaining)&&(identical(other.availableTomorrow, availableTomorrow) || other.availableTomorrow == availableTomorrow)&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.cycleUsedTime, cycleUsedTime) || other.cycleUsedTime == cycleUsedTime)&&(identical(other.cycleRemainingTime, cycleRemainingTime) || other.cycleRemainingTime == cycleRemainingTime)&&(identical(other.availableTomorrowTime, availableTomorrowTime) || other.availableTomorrowTime == availableTomorrowTime));
}


@override
int get hashCode => Object.hash(runtimeType,cycleRule,cycleUsed,cycleRemaining,availableTomorrow,const DeepCollectionEquality().hash(days),cycleUsedTime,cycleRemainingTime,availableTomorrowTime);

@override
String toString() {
  return 'WeeklyRecap(cycleRule: $cycleRule, cycleUsed: $cycleUsed, cycleRemaining: $cycleRemaining, availableTomorrow: $availableTomorrow, days: $days, cycleUsedTime: $cycleUsedTime, cycleRemainingTime: $cycleRemainingTime, availableTomorrowTime: $availableTomorrowTime)';
}


}

/// @nodoc
abstract mixin class $WeeklyRecapCopyWith<$Res>  {
  factory $WeeklyRecapCopyWith(WeeklyRecap value, $Res Function(WeeklyRecap) _then) = _$WeeklyRecapCopyWithImpl;
@useResult
$Res call({
 CycleRule cycleRule, Duration cycleUsed, Duration cycleRemaining, Duration availableTomorrow, List<RecapDay> days, RecapTimeValue? cycleUsedTime, RecapTimeValue? cycleRemainingTime, RecapTimeValue? availableTomorrowTime
});


$RecapTimeValueCopyWith<$Res>? get cycleUsedTime;$RecapTimeValueCopyWith<$Res>? get cycleRemainingTime;$RecapTimeValueCopyWith<$Res>? get availableTomorrowTime;

}
/// @nodoc
class _$WeeklyRecapCopyWithImpl<$Res>
    implements $WeeklyRecapCopyWith<$Res> {
  _$WeeklyRecapCopyWithImpl(this._self, this._then);

  final WeeklyRecap _self;
  final $Res Function(WeeklyRecap) _then;

/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cycleRule = null,Object? cycleUsed = null,Object? cycleRemaining = null,Object? availableTomorrow = null,Object? days = null,Object? cycleUsedTime = freezed,Object? cycleRemainingTime = freezed,Object? availableTomorrowTime = freezed,}) {
  return _then(_self.copyWith(
cycleRule: null == cycleRule ? _self.cycleRule : cycleRule // ignore: cast_nullable_to_non_nullable
as CycleRule,cycleUsed: null == cycleUsed ? _self.cycleUsed : cycleUsed // ignore: cast_nullable_to_non_nullable
as Duration,cycleRemaining: null == cycleRemaining ? _self.cycleRemaining : cycleRemaining // ignore: cast_nullable_to_non_nullable
as Duration,availableTomorrow: null == availableTomorrow ? _self.availableTomorrow : availableTomorrow // ignore: cast_nullable_to_non_nullable
as Duration,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<RecapDay>,cycleUsedTime: freezed == cycleUsedTime ? _self.cycleUsedTime : cycleUsedTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,cycleRemainingTime: freezed == cycleRemainingTime ? _self.cycleRemainingTime : cycleRemainingTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,availableTomorrowTime: freezed == availableTomorrowTime ? _self.availableTomorrowTime : availableTomorrowTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,
  ));
}
/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get cycleUsedTime {
    if (_self.cycleUsedTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.cycleUsedTime!, (value) {
    return _then(_self.copyWith(cycleUsedTime: value));
  });
}/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get cycleRemainingTime {
    if (_self.cycleRemainingTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.cycleRemainingTime!, (value) {
    return _then(_self.copyWith(cycleRemainingTime: value));
  });
}/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get availableTomorrowTime {
    if (_self.availableTomorrowTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.availableTomorrowTime!, (value) {
    return _then(_self.copyWith(availableTomorrowTime: value));
  });
}
}


/// @nodoc


class _WeeklyRecap extends WeeklyRecap {
  const _WeeklyRecap({required this.cycleRule, required this.cycleUsed, required this.cycleRemaining, required this.availableTomorrow, required final  List<RecapDay> days, this.cycleUsedTime, this.cycleRemainingTime, this.availableTomorrowTime}): _days = days,super._();
  

@override final  CycleRule cycleRule;
@override final  Duration cycleUsed;
@override final  Duration cycleRemaining;
@override final  Duration availableTomorrow;
 final  List<RecapDay> _days;
@override List<RecapDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

/// Structured time values distinguishing present/missing/invalid
/// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
@override final  RecapTimeValue? cycleUsedTime;
@override final  RecapTimeValue? cycleRemainingTime;
@override final  RecapTimeValue? availableTomorrowTime;

/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyRecapCopyWith<_WeeklyRecap> get copyWith => __$WeeklyRecapCopyWithImpl<_WeeklyRecap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyRecap&&(identical(other.cycleRule, cycleRule) || other.cycleRule == cycleRule)&&(identical(other.cycleUsed, cycleUsed) || other.cycleUsed == cycleUsed)&&(identical(other.cycleRemaining, cycleRemaining) || other.cycleRemaining == cycleRemaining)&&(identical(other.availableTomorrow, availableTomorrow) || other.availableTomorrow == availableTomorrow)&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.cycleUsedTime, cycleUsedTime) || other.cycleUsedTime == cycleUsedTime)&&(identical(other.cycleRemainingTime, cycleRemainingTime) || other.cycleRemainingTime == cycleRemainingTime)&&(identical(other.availableTomorrowTime, availableTomorrowTime) || other.availableTomorrowTime == availableTomorrowTime));
}


@override
int get hashCode => Object.hash(runtimeType,cycleRule,cycleUsed,cycleRemaining,availableTomorrow,const DeepCollectionEquality().hash(_days),cycleUsedTime,cycleRemainingTime,availableTomorrowTime);

@override
String toString() {
  return 'WeeklyRecap(cycleRule: $cycleRule, cycleUsed: $cycleUsed, cycleRemaining: $cycleRemaining, availableTomorrow: $availableTomorrow, days: $days, cycleUsedTime: $cycleUsedTime, cycleRemainingTime: $cycleRemainingTime, availableTomorrowTime: $availableTomorrowTime)';
}


}

/// @nodoc
abstract mixin class _$WeeklyRecapCopyWith<$Res> implements $WeeklyRecapCopyWith<$Res> {
  factory _$WeeklyRecapCopyWith(_WeeklyRecap value, $Res Function(_WeeklyRecap) _then) = __$WeeklyRecapCopyWithImpl;
@override @useResult
$Res call({
 CycleRule cycleRule, Duration cycleUsed, Duration cycleRemaining, Duration availableTomorrow, List<RecapDay> days, RecapTimeValue? cycleUsedTime, RecapTimeValue? cycleRemainingTime, RecapTimeValue? availableTomorrowTime
});


@override $RecapTimeValueCopyWith<$Res>? get cycleUsedTime;@override $RecapTimeValueCopyWith<$Res>? get cycleRemainingTime;@override $RecapTimeValueCopyWith<$Res>? get availableTomorrowTime;

}
/// @nodoc
class __$WeeklyRecapCopyWithImpl<$Res>
    implements _$WeeklyRecapCopyWith<$Res> {
  __$WeeklyRecapCopyWithImpl(this._self, this._then);

  final _WeeklyRecap _self;
  final $Res Function(_WeeklyRecap) _then;

/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cycleRule = null,Object? cycleUsed = null,Object? cycleRemaining = null,Object? availableTomorrow = null,Object? days = null,Object? cycleUsedTime = freezed,Object? cycleRemainingTime = freezed,Object? availableTomorrowTime = freezed,}) {
  return _then(_WeeklyRecap(
cycleRule: null == cycleRule ? _self.cycleRule : cycleRule // ignore: cast_nullable_to_non_nullable
as CycleRule,cycleUsed: null == cycleUsed ? _self.cycleUsed : cycleUsed // ignore: cast_nullable_to_non_nullable
as Duration,cycleRemaining: null == cycleRemaining ? _self.cycleRemaining : cycleRemaining // ignore: cast_nullable_to_non_nullable
as Duration,availableTomorrow: null == availableTomorrow ? _self.availableTomorrow : availableTomorrow // ignore: cast_nullable_to_non_nullable
as Duration,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<RecapDay>,cycleUsedTime: freezed == cycleUsedTime ? _self.cycleUsedTime : cycleUsedTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,cycleRemainingTime: freezed == cycleRemainingTime ? _self.cycleRemainingTime : cycleRemainingTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,availableTomorrowTime: freezed == availableTomorrowTime ? _self.availableTomorrowTime : availableTomorrowTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,
  ));
}

/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get cycleUsedTime {
    if (_self.cycleUsedTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.cycleUsedTime!, (value) {
    return _then(_self.copyWith(cycleUsedTime: value));
  });
}/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get cycleRemainingTime {
    if (_self.cycleRemainingTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.cycleRemainingTime!, (value) {
    return _then(_self.copyWith(cycleRemainingTime: value));
  });
}/// Create a copy of WeeklyRecap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get availableTomorrowTime {
    if (_self.availableTomorrowTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.availableTomorrowTime!, (value) {
    return _then(_self.copyWith(availableTomorrowTime: value));
  });
}
}

/// @nodoc
mixin _$RecapDay {

 DateTime get date; String get dayOfWeek; Duration get driving; Duration get onDuty; Duration get totalWork;/// Structured time values distinguishing present/missing/invalid
/// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
 RecapTimeValue? get drivingTime; RecapTimeValue? get onDutyTime; RecapTimeValue? get totalWorkTime;
/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecapDayCopyWith<RecapDay> get copyWith => _$RecapDayCopyWithImpl<RecapDay>(this as RecapDay, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecapDay&&(identical(other.date, date) || other.date == date)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.driving, driving) || other.driving == driving)&&(identical(other.onDuty, onDuty) || other.onDuty == onDuty)&&(identical(other.totalWork, totalWork) || other.totalWork == totalWork)&&(identical(other.drivingTime, drivingTime) || other.drivingTime == drivingTime)&&(identical(other.onDutyTime, onDutyTime) || other.onDutyTime == onDutyTime)&&(identical(other.totalWorkTime, totalWorkTime) || other.totalWorkTime == totalWorkTime));
}


@override
int get hashCode => Object.hash(runtimeType,date,dayOfWeek,driving,onDuty,totalWork,drivingTime,onDutyTime,totalWorkTime);

@override
String toString() {
  return 'RecapDay(date: $date, dayOfWeek: $dayOfWeek, driving: $driving, onDuty: $onDuty, totalWork: $totalWork, drivingTime: $drivingTime, onDutyTime: $onDutyTime, totalWorkTime: $totalWorkTime)';
}


}

/// @nodoc
abstract mixin class $RecapDayCopyWith<$Res>  {
  factory $RecapDayCopyWith(RecapDay value, $Res Function(RecapDay) _then) = _$RecapDayCopyWithImpl;
@useResult
$Res call({
 DateTime date, String dayOfWeek, Duration driving, Duration onDuty, Duration totalWork, RecapTimeValue? drivingTime, RecapTimeValue? onDutyTime, RecapTimeValue? totalWorkTime
});


$RecapTimeValueCopyWith<$Res>? get drivingTime;$RecapTimeValueCopyWith<$Res>? get onDutyTime;$RecapTimeValueCopyWith<$Res>? get totalWorkTime;

}
/// @nodoc
class _$RecapDayCopyWithImpl<$Res>
    implements $RecapDayCopyWith<$Res> {
  _$RecapDayCopyWithImpl(this._self, this._then);

  final RecapDay _self;
  final $Res Function(RecapDay) _then;

/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? dayOfWeek = null,Object? driving = null,Object? onDuty = null,Object? totalWork = null,Object? drivingTime = freezed,Object? onDutyTime = freezed,Object? totalWorkTime = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String,driving: null == driving ? _self.driving : driving // ignore: cast_nullable_to_non_nullable
as Duration,onDuty: null == onDuty ? _self.onDuty : onDuty // ignore: cast_nullable_to_non_nullable
as Duration,totalWork: null == totalWork ? _self.totalWork : totalWork // ignore: cast_nullable_to_non_nullable
as Duration,drivingTime: freezed == drivingTime ? _self.drivingTime : drivingTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,onDutyTime: freezed == onDutyTime ? _self.onDutyTime : onDutyTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,totalWorkTime: freezed == totalWorkTime ? _self.totalWorkTime : totalWorkTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,
  ));
}
/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get drivingTime {
    if (_self.drivingTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.drivingTime!, (value) {
    return _then(_self.copyWith(drivingTime: value));
  });
}/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get onDutyTime {
    if (_self.onDutyTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.onDutyTime!, (value) {
    return _then(_self.copyWith(onDutyTime: value));
  });
}/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get totalWorkTime {
    if (_self.totalWorkTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.totalWorkTime!, (value) {
    return _then(_self.copyWith(totalWorkTime: value));
  });
}
}


/// @nodoc


class _RecapDay extends RecapDay {
  const _RecapDay({required this.date, required this.dayOfWeek, this.driving = Duration.zero, this.onDuty = Duration.zero, this.totalWork = Duration.zero, this.drivingTime, this.onDutyTime, this.totalWorkTime}): super._();
  

@override final  DateTime date;
@override final  String dayOfWeek;
@override@JsonKey() final  Duration driving;
@override@JsonKey() final  Duration onDuty;
@override@JsonKey() final  Duration totalWork;
/// Structured time values distinguishing present/missing/invalid
/// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
@override final  RecapTimeValue? drivingTime;
@override final  RecapTimeValue? onDutyTime;
@override final  RecapTimeValue? totalWorkTime;

/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecapDayCopyWith<_RecapDay> get copyWith => __$RecapDayCopyWithImpl<_RecapDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecapDay&&(identical(other.date, date) || other.date == date)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.driving, driving) || other.driving == driving)&&(identical(other.onDuty, onDuty) || other.onDuty == onDuty)&&(identical(other.totalWork, totalWork) || other.totalWork == totalWork)&&(identical(other.drivingTime, drivingTime) || other.drivingTime == drivingTime)&&(identical(other.onDutyTime, onDutyTime) || other.onDutyTime == onDutyTime)&&(identical(other.totalWorkTime, totalWorkTime) || other.totalWorkTime == totalWorkTime));
}


@override
int get hashCode => Object.hash(runtimeType,date,dayOfWeek,driving,onDuty,totalWork,drivingTime,onDutyTime,totalWorkTime);

@override
String toString() {
  return 'RecapDay(date: $date, dayOfWeek: $dayOfWeek, driving: $driving, onDuty: $onDuty, totalWork: $totalWork, drivingTime: $drivingTime, onDutyTime: $onDutyTime, totalWorkTime: $totalWorkTime)';
}


}

/// @nodoc
abstract mixin class _$RecapDayCopyWith<$Res> implements $RecapDayCopyWith<$Res> {
  factory _$RecapDayCopyWith(_RecapDay value, $Res Function(_RecapDay) _then) = __$RecapDayCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String dayOfWeek, Duration driving, Duration onDuty, Duration totalWork, RecapTimeValue? drivingTime, RecapTimeValue? onDutyTime, RecapTimeValue? totalWorkTime
});


@override $RecapTimeValueCopyWith<$Res>? get drivingTime;@override $RecapTimeValueCopyWith<$Res>? get onDutyTime;@override $RecapTimeValueCopyWith<$Res>? get totalWorkTime;

}
/// @nodoc
class __$RecapDayCopyWithImpl<$Res>
    implements _$RecapDayCopyWith<$Res> {
  __$RecapDayCopyWithImpl(this._self, this._then);

  final _RecapDay _self;
  final $Res Function(_RecapDay) _then;

/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? dayOfWeek = null,Object? driving = null,Object? onDuty = null,Object? totalWork = null,Object? drivingTime = freezed,Object? onDutyTime = freezed,Object? totalWorkTime = freezed,}) {
  return _then(_RecapDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String,driving: null == driving ? _self.driving : driving // ignore: cast_nullable_to_non_nullable
as Duration,onDuty: null == onDuty ? _self.onDuty : onDuty // ignore: cast_nullable_to_non_nullable
as Duration,totalWork: null == totalWork ? _self.totalWork : totalWork // ignore: cast_nullable_to_non_nullable
as Duration,drivingTime: freezed == drivingTime ? _self.drivingTime : drivingTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,onDutyTime: freezed == onDutyTime ? _self.onDutyTime : onDutyTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,totalWorkTime: freezed == totalWorkTime ? _self.totalWorkTime : totalWorkTime // ignore: cast_nullable_to_non_nullable
as RecapTimeValue?,
  ));
}

/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get drivingTime {
    if (_self.drivingTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.drivingTime!, (value) {
    return _then(_self.copyWith(drivingTime: value));
  });
}/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get onDutyTime {
    if (_self.onDutyTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.onDutyTime!, (value) {
    return _then(_self.copyWith(onDutyTime: value));
  });
}/// Create a copy of RecapDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<$Res>? get totalWorkTime {
    if (_self.totalWorkTime == null) {
    return null;
  }

  return $RecapTimeValueCopyWith<$Res>(_self.totalWorkTime!, (value) {
    return _then(_self.copyWith(totalWorkTime: value));
  });
}
}

/// @nodoc
mixin _$RecapTimeValue {

/// The parsed duration. Null if missing or invalid.
 Duration? get duration;/// Raw server-formatted representation (e.g. "11h 00m" or "05:00").
 String? get formatted;/// State distinguishing genuine value from missing or invalid.
 RecapTimeState get state;
/// Create a copy of RecapTimeValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecapTimeValueCopyWith<RecapTimeValue> get copyWith => _$RecapTimeValueCopyWithImpl<RecapTimeValue>(this as RecapTimeValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecapTimeValue&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.formatted, formatted) || other.formatted == formatted)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,duration,formatted,state);

@override
String toString() {
  return 'RecapTimeValue(duration: $duration, formatted: $formatted, state: $state)';
}


}

/// @nodoc
abstract mixin class $RecapTimeValueCopyWith<$Res>  {
  factory $RecapTimeValueCopyWith(RecapTimeValue value, $Res Function(RecapTimeValue) _then) = _$RecapTimeValueCopyWithImpl;
@useResult
$Res call({
 Duration? duration, String? formatted, RecapTimeState state
});




}
/// @nodoc
class _$RecapTimeValueCopyWithImpl<$Res>
    implements $RecapTimeValueCopyWith<$Res> {
  _$RecapTimeValueCopyWithImpl(this._self, this._then);

  final RecapTimeValue _self;
  final $Res Function(RecapTimeValue) _then;

/// Create a copy of RecapTimeValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = freezed,Object? formatted = freezed,Object? state = null,}) {
  return _then(_self.copyWith(
duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,formatted: freezed == formatted ? _self.formatted : formatted // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RecapTimeState,
  ));
}

}


/// @nodoc


class _RecapTimeValue extends RecapTimeValue {
  const _RecapTimeValue({this.duration, this.formatted, this.state = RecapTimeState.present}): super._();
  

/// The parsed duration. Null if missing or invalid.
@override final  Duration? duration;
/// Raw server-formatted representation (e.g. "11h 00m" or "05:00").
@override final  String? formatted;
/// State distinguishing genuine value from missing or invalid.
@override@JsonKey() final  RecapTimeState state;

/// Create a copy of RecapTimeValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecapTimeValueCopyWith<_RecapTimeValue> get copyWith => __$RecapTimeValueCopyWithImpl<_RecapTimeValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecapTimeValue&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.formatted, formatted) || other.formatted == formatted)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,duration,formatted,state);

@override
String toString() {
  return 'RecapTimeValue(duration: $duration, formatted: $formatted, state: $state)';
}


}

/// @nodoc
abstract mixin class _$RecapTimeValueCopyWith<$Res> implements $RecapTimeValueCopyWith<$Res> {
  factory _$RecapTimeValueCopyWith(_RecapTimeValue value, $Res Function(_RecapTimeValue) _then) = __$RecapTimeValueCopyWithImpl;
@override @useResult
$Res call({
 Duration? duration, String? formatted, RecapTimeState state
});




}
/// @nodoc
class __$RecapTimeValueCopyWithImpl<$Res>
    implements _$RecapTimeValueCopyWith<$Res> {
  __$RecapTimeValueCopyWithImpl(this._self, this._then);

  final _RecapTimeValue _self;
  final $Res Function(_RecapTimeValue) _then;

/// Create a copy of RecapTimeValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = freezed,Object? formatted = freezed,Object? state = null,}) {
  return _then(_RecapTimeValue(
duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,formatted: freezed == formatted ? _self.formatted : formatted // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RecapTimeState,
  ));
}


}

// dart format on
