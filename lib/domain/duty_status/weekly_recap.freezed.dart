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
  CycleRule get cycleRule;
  Duration get cycleUsed;
  Duration get cycleRemaining;
  Duration get availableTomorrow;
  List<RecapDay> get days;

  /// Create a copy of WeeklyRecap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeeklyRecapCopyWith<WeeklyRecap> get copyWith =>
      _$WeeklyRecapCopyWithImpl<WeeklyRecap>(this as WeeklyRecap, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeeklyRecap &&
            (identical(other.cycleRule, cycleRule) ||
                other.cycleRule == cycleRule) &&
            (identical(other.cycleUsed, cycleUsed) ||
                other.cycleUsed == cycleUsed) &&
            (identical(other.cycleRemaining, cycleRemaining) ||
                other.cycleRemaining == cycleRemaining) &&
            (identical(other.availableTomorrow, availableTomorrow) ||
                other.availableTomorrow == availableTomorrow) &&
            const DeepCollectionEquality().equals(other.days, days));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      cycleRule,
      cycleUsed,
      cycleRemaining,
      availableTomorrow,
      const DeepCollectionEquality().hash(days));

  @override
  String toString() {
    return 'WeeklyRecap(cycleRule: $cycleRule, cycleUsed: $cycleUsed, cycleRemaining: $cycleRemaining, availableTomorrow: $availableTomorrow, days: $days)';
  }
}

/// @nodoc
abstract mixin class $WeeklyRecapCopyWith<$Res> {
  factory $WeeklyRecapCopyWith(
          WeeklyRecap value, $Res Function(WeeklyRecap) _then) =
      _$WeeklyRecapCopyWithImpl;
  @useResult
  $Res call(
      {CycleRule cycleRule,
      Duration cycleUsed,
      Duration cycleRemaining,
      Duration availableTomorrow,
      List<RecapDay> days});
}

/// @nodoc
class _$WeeklyRecapCopyWithImpl<$Res> implements $WeeklyRecapCopyWith<$Res> {
  _$WeeklyRecapCopyWithImpl(this._self, this._then);

  final WeeklyRecap _self;
  final $Res Function(WeeklyRecap) _then;

  /// Create a copy of WeeklyRecap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cycleRule = null,
    Object? cycleUsed = null,
    Object? cycleRemaining = null,
    Object? availableTomorrow = null,
    Object? days = null,
  }) {
    return _then(_self.copyWith(
      cycleRule: null == cycleRule
          ? _self.cycleRule
          : cycleRule // ignore: cast_nullable_to_non_nullable
              as CycleRule,
      cycleUsed: null == cycleUsed
          ? _self.cycleUsed
          : cycleUsed // ignore: cast_nullable_to_non_nullable
              as Duration,
      cycleRemaining: null == cycleRemaining
          ? _self.cycleRemaining
          : cycleRemaining // ignore: cast_nullable_to_non_nullable
              as Duration,
      availableTomorrow: null == availableTomorrow
          ? _self.availableTomorrow
          : availableTomorrow // ignore: cast_nullable_to_non_nullable
              as Duration,
      days: null == days
          ? _self.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RecapDay>,
    ));
  }
}

/// @nodoc

class _WeeklyRecap implements WeeklyRecap {
  const _WeeklyRecap(
      {required this.cycleRule,
      required this.cycleUsed,
      required this.cycleRemaining,
      required this.availableTomorrow,
      required final List<RecapDay> days})
      : _days = days;

  @override
  final CycleRule cycleRule;
  @override
  final Duration cycleUsed;
  @override
  final Duration cycleRemaining;
  @override
  final Duration availableTomorrow;
  final List<RecapDay> _days;
  @override
  List<RecapDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  /// Create a copy of WeeklyRecap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WeeklyRecapCopyWith<_WeeklyRecap> get copyWith =>
      __$WeeklyRecapCopyWithImpl<_WeeklyRecap>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WeeklyRecap &&
            (identical(other.cycleRule, cycleRule) ||
                other.cycleRule == cycleRule) &&
            (identical(other.cycleUsed, cycleUsed) ||
                other.cycleUsed == cycleUsed) &&
            (identical(other.cycleRemaining, cycleRemaining) ||
                other.cycleRemaining == cycleRemaining) &&
            (identical(other.availableTomorrow, availableTomorrow) ||
                other.availableTomorrow == availableTomorrow) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      cycleRule,
      cycleUsed,
      cycleRemaining,
      availableTomorrow,
      const DeepCollectionEquality().hash(_days));

  @override
  String toString() {
    return 'WeeklyRecap(cycleRule: $cycleRule, cycleUsed: $cycleUsed, cycleRemaining: $cycleRemaining, availableTomorrow: $availableTomorrow, days: $days)';
  }
}

/// @nodoc
abstract mixin class _$WeeklyRecapCopyWith<$Res>
    implements $WeeklyRecapCopyWith<$Res> {
  factory _$WeeklyRecapCopyWith(
          _WeeklyRecap value, $Res Function(_WeeklyRecap) _then) =
      __$WeeklyRecapCopyWithImpl;
  @override
  @useResult
  $Res call(
      {CycleRule cycleRule,
      Duration cycleUsed,
      Duration cycleRemaining,
      Duration availableTomorrow,
      List<RecapDay> days});
}

/// @nodoc
class __$WeeklyRecapCopyWithImpl<$Res> implements _$WeeklyRecapCopyWith<$Res> {
  __$WeeklyRecapCopyWithImpl(this._self, this._then);

  final _WeeklyRecap _self;
  final $Res Function(_WeeklyRecap) _then;

  /// Create a copy of WeeklyRecap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cycleRule = null,
    Object? cycleUsed = null,
    Object? cycleRemaining = null,
    Object? availableTomorrow = null,
    Object? days = null,
  }) {
    return _then(_WeeklyRecap(
      cycleRule: null == cycleRule
          ? _self.cycleRule
          : cycleRule // ignore: cast_nullable_to_non_nullable
              as CycleRule,
      cycleUsed: null == cycleUsed
          ? _self.cycleUsed
          : cycleUsed // ignore: cast_nullable_to_non_nullable
              as Duration,
      cycleRemaining: null == cycleRemaining
          ? _self.cycleRemaining
          : cycleRemaining // ignore: cast_nullable_to_non_nullable
              as Duration,
      availableTomorrow: null == availableTomorrow
          ? _self.availableTomorrow
          : availableTomorrow // ignore: cast_nullable_to_non_nullable
              as Duration,
      days: null == days
          ? _self._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RecapDay>,
    ));
  }
}

/// @nodoc
mixin _$RecapDay {
  DateTime get date;
  String get dayOfWeek;
  Duration get driving;
  Duration get onDuty;
  Duration get totalWork;

  /// Create a copy of RecapDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecapDayCopyWith<RecapDay> get copyWith =>
      _$RecapDayCopyWithImpl<RecapDay>(this as RecapDay, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecapDay &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.driving, driving) || other.driving == driving) &&
            (identical(other.onDuty, onDuty) || other.onDuty == onDuty) &&
            (identical(other.totalWork, totalWork) ||
                other.totalWork == totalWork));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, date, dayOfWeek, driving, onDuty, totalWork);

  @override
  String toString() {
    return 'RecapDay(date: $date, dayOfWeek: $dayOfWeek, driving: $driving, onDuty: $onDuty, totalWork: $totalWork)';
  }
}

/// @nodoc
abstract mixin class $RecapDayCopyWith<$Res> {
  factory $RecapDayCopyWith(RecapDay value, $Res Function(RecapDay) _then) =
      _$RecapDayCopyWithImpl;
  @useResult
  $Res call(
      {DateTime date,
      String dayOfWeek,
      Duration driving,
      Duration onDuty,
      Duration totalWork});
}

/// @nodoc
class _$RecapDayCopyWithImpl<$Res> implements $RecapDayCopyWith<$Res> {
  _$RecapDayCopyWithImpl(this._self, this._then);

  final RecapDay _self;
  final $Res Function(RecapDay) _then;

  /// Create a copy of RecapDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? dayOfWeek = null,
    Object? driving = null,
    Object? onDuty = null,
    Object? totalWork = null,
  }) {
    return _then(_self.copyWith(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayOfWeek: null == dayOfWeek
          ? _self.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as String,
      driving: null == driving
          ? _self.driving
          : driving // ignore: cast_nullable_to_non_nullable
              as Duration,
      onDuty: null == onDuty
          ? _self.onDuty
          : onDuty // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalWork: null == totalWork
          ? _self.totalWork
          : totalWork // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// @nodoc

class _RecapDay implements RecapDay {
  const _RecapDay(
      {required this.date,
      required this.dayOfWeek,
      required this.driving,
      required this.onDuty,
      required this.totalWork});

  @override
  final DateTime date;
  @override
  final String dayOfWeek;
  @override
  final Duration driving;
  @override
  final Duration onDuty;
  @override
  final Duration totalWork;

  /// Create a copy of RecapDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecapDayCopyWith<_RecapDay> get copyWith =>
      __$RecapDayCopyWithImpl<_RecapDay>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecapDay &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.driving, driving) || other.driving == driving) &&
            (identical(other.onDuty, onDuty) || other.onDuty == onDuty) &&
            (identical(other.totalWork, totalWork) ||
                other.totalWork == totalWork));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, date, dayOfWeek, driving, onDuty, totalWork);

  @override
  String toString() {
    return 'RecapDay(date: $date, dayOfWeek: $dayOfWeek, driving: $driving, onDuty: $onDuty, totalWork: $totalWork)';
  }
}

/// @nodoc
abstract mixin class _$RecapDayCopyWith<$Res>
    implements $RecapDayCopyWith<$Res> {
  factory _$RecapDayCopyWith(_RecapDay value, $Res Function(_RecapDay) _then) =
      __$RecapDayCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime date,
      String dayOfWeek,
      Duration driving,
      Duration onDuty,
      Duration totalWork});
}

/// @nodoc
class __$RecapDayCopyWithImpl<$Res> implements _$RecapDayCopyWith<$Res> {
  __$RecapDayCopyWithImpl(this._self, this._then);

  final _RecapDay _self;
  final $Res Function(_RecapDay) _then;

  /// Create a copy of RecapDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? date = null,
    Object? dayOfWeek = null,
    Object? driving = null,
    Object? onDuty = null,
    Object? totalWork = null,
  }) {
    return _then(_RecapDay(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayOfWeek: null == dayOfWeek
          ? _self.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as String,
      driving: null == driving
          ? _self.driving
          : driving // ignore: cast_nullable_to_non_nullable
              as Duration,
      onDuty: null == onDuty
          ? _self.onDuty
          : onDuty // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalWork: null == totalWork
          ? _self.totalWork
          : totalWork // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

// dart format on
