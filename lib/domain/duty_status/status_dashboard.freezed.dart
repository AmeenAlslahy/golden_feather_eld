// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusDashboard {
  DriverRef get driver;
  OperationalAlerts get operationalAlerts;
  DutyStatusCode get currentDutyStatus;
  RemainingCircle get remainingCircle;
  HosIndicators get hosIndicators;
  RegulatoryConstraints get regulatoryConstraints;

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatusDashboardCopyWith<StatusDashboard> get copyWith =>
      _$StatusDashboardCopyWithImpl<StatusDashboard>(
          this as StatusDashboard, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatusDashboard &&
            (identical(other.driver, driver) || other.driver == driver) &&
            (identical(other.operationalAlerts, operationalAlerts) ||
                other.operationalAlerts == operationalAlerts) &&
            (identical(other.currentDutyStatus, currentDutyStatus) ||
                other.currentDutyStatus == currentDutyStatus) &&
            (identical(other.remainingCircle, remainingCircle) ||
                other.remainingCircle == remainingCircle) &&
            (identical(other.hosIndicators, hosIndicators) ||
                other.hosIndicators == hosIndicators) &&
            (identical(other.regulatoryConstraints, regulatoryConstraints) ||
                other.regulatoryConstraints == regulatoryConstraints));
  }

  @override
  int get hashCode => Object.hash(runtimeType, driver, operationalAlerts,
      currentDutyStatus, remainingCircle, hosIndicators, regulatoryConstraints);

  @override
  String toString() {
    return 'StatusDashboard(driver: $driver, operationalAlerts: $operationalAlerts, currentDutyStatus: $currentDutyStatus, remainingCircle: $remainingCircle, hosIndicators: $hosIndicators, regulatoryConstraints: $regulatoryConstraints)';
  }
}

/// @nodoc
abstract mixin class $StatusDashboardCopyWith<$Res> {
  factory $StatusDashboardCopyWith(
          StatusDashboard value, $Res Function(StatusDashboard) _then) =
      _$StatusDashboardCopyWithImpl;
  @useResult
  $Res call(
      {DriverRef driver,
      OperationalAlerts operationalAlerts,
      DutyStatusCode currentDutyStatus,
      RemainingCircle remainingCircle,
      HosIndicators hosIndicators,
      RegulatoryConstraints regulatoryConstraints});

  $DriverRefCopyWith<$Res> get driver;
  $OperationalAlertsCopyWith<$Res> get operationalAlerts;
  $RemainingCircleCopyWith<$Res> get remainingCircle;
  $HosIndicatorsCopyWith<$Res> get hosIndicators;
  $RegulatoryConstraintsCopyWith<$Res> get regulatoryConstraints;
}

/// @nodoc
class _$StatusDashboardCopyWithImpl<$Res>
    implements $StatusDashboardCopyWith<$Res> {
  _$StatusDashboardCopyWithImpl(this._self, this._then);

  final StatusDashboard _self;
  final $Res Function(StatusDashboard) _then;

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driver = null,
    Object? operationalAlerts = null,
    Object? currentDutyStatus = null,
    Object? remainingCircle = null,
    Object? hosIndicators = null,
    Object? regulatoryConstraints = null,
  }) {
    return _then(_self.copyWith(
      driver: null == driver
          ? _self.driver
          : driver // ignore: cast_nullable_to_non_nullable
              as DriverRef,
      operationalAlerts: null == operationalAlerts
          ? _self.operationalAlerts
          : operationalAlerts // ignore: cast_nullable_to_non_nullable
              as OperationalAlerts,
      currentDutyStatus: null == currentDutyStatus
          ? _self.currentDutyStatus
          : currentDutyStatus // ignore: cast_nullable_to_non_nullable
              as DutyStatusCode,
      remainingCircle: null == remainingCircle
          ? _self.remainingCircle
          : remainingCircle // ignore: cast_nullable_to_non_nullable
              as RemainingCircle,
      hosIndicators: null == hosIndicators
          ? _self.hosIndicators
          : hosIndicators // ignore: cast_nullable_to_non_nullable
              as HosIndicators,
      regulatoryConstraints: null == regulatoryConstraints
          ? _self.regulatoryConstraints
          : regulatoryConstraints // ignore: cast_nullable_to_non_nullable
              as RegulatoryConstraints,
    ));
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverRefCopyWith<$Res> get driver {
    return $DriverRefCopyWith<$Res>(_self.driver, (value) {
      return _then(_self.copyWith(driver: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OperationalAlertsCopyWith<$Res> get operationalAlerts {
    return $OperationalAlertsCopyWith<$Res>(_self.operationalAlerts, (value) {
      return _then(_self.copyWith(operationalAlerts: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RemainingCircleCopyWith<$Res> get remainingCircle {
    return $RemainingCircleCopyWith<$Res>(_self.remainingCircle, (value) {
      return _then(_self.copyWith(remainingCircle: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorsCopyWith<$Res> get hosIndicators {
    return $HosIndicatorsCopyWith<$Res>(_self.hosIndicators, (value) {
      return _then(_self.copyWith(hosIndicators: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegulatoryConstraintsCopyWith<$Res> get regulatoryConstraints {
    return $RegulatoryConstraintsCopyWith<$Res>(_self.regulatoryConstraints,
        (value) {
      return _then(_self.copyWith(regulatoryConstraints: value));
    });
  }
}

/// @nodoc

class _StatusDashboard implements StatusDashboard {
  const _StatusDashboard(
      {required this.driver,
      required this.operationalAlerts,
      required this.currentDutyStatus,
      required this.remainingCircle,
      required this.hosIndicators,
      required this.regulatoryConstraints});

  @override
  final DriverRef driver;
  @override
  final OperationalAlerts operationalAlerts;
  @override
  final DutyStatusCode currentDutyStatus;
  @override
  final RemainingCircle remainingCircle;
  @override
  final HosIndicators hosIndicators;
  @override
  final RegulatoryConstraints regulatoryConstraints;

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatusDashboardCopyWith<_StatusDashboard> get copyWith =>
      __$StatusDashboardCopyWithImpl<_StatusDashboard>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatusDashboard &&
            (identical(other.driver, driver) || other.driver == driver) &&
            (identical(other.operationalAlerts, operationalAlerts) ||
                other.operationalAlerts == operationalAlerts) &&
            (identical(other.currentDutyStatus, currentDutyStatus) ||
                other.currentDutyStatus == currentDutyStatus) &&
            (identical(other.remainingCircle, remainingCircle) ||
                other.remainingCircle == remainingCircle) &&
            (identical(other.hosIndicators, hosIndicators) ||
                other.hosIndicators == hosIndicators) &&
            (identical(other.regulatoryConstraints, regulatoryConstraints) ||
                other.regulatoryConstraints == regulatoryConstraints));
  }

  @override
  int get hashCode => Object.hash(runtimeType, driver, operationalAlerts,
      currentDutyStatus, remainingCircle, hosIndicators, regulatoryConstraints);

  @override
  String toString() {
    return 'StatusDashboard(driver: $driver, operationalAlerts: $operationalAlerts, currentDutyStatus: $currentDutyStatus, remainingCircle: $remainingCircle, hosIndicators: $hosIndicators, regulatoryConstraints: $regulatoryConstraints)';
  }
}

/// @nodoc
abstract mixin class _$StatusDashboardCopyWith<$Res>
    implements $StatusDashboardCopyWith<$Res> {
  factory _$StatusDashboardCopyWith(
          _StatusDashboard value, $Res Function(_StatusDashboard) _then) =
      __$StatusDashboardCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DriverRef driver,
      OperationalAlerts operationalAlerts,
      DutyStatusCode currentDutyStatus,
      RemainingCircle remainingCircle,
      HosIndicators hosIndicators,
      RegulatoryConstraints regulatoryConstraints});

  @override
  $DriverRefCopyWith<$Res> get driver;
  @override
  $OperationalAlertsCopyWith<$Res> get operationalAlerts;
  @override
  $RemainingCircleCopyWith<$Res> get remainingCircle;
  @override
  $HosIndicatorsCopyWith<$Res> get hosIndicators;
  @override
  $RegulatoryConstraintsCopyWith<$Res> get regulatoryConstraints;
}

/// @nodoc
class __$StatusDashboardCopyWithImpl<$Res>
    implements _$StatusDashboardCopyWith<$Res> {
  __$StatusDashboardCopyWithImpl(this._self, this._then);

  final _StatusDashboard _self;
  final $Res Function(_StatusDashboard) _then;

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? driver = null,
    Object? operationalAlerts = null,
    Object? currentDutyStatus = null,
    Object? remainingCircle = null,
    Object? hosIndicators = null,
    Object? regulatoryConstraints = null,
  }) {
    return _then(_StatusDashboard(
      driver: null == driver
          ? _self.driver
          : driver // ignore: cast_nullable_to_non_nullable
              as DriverRef,
      operationalAlerts: null == operationalAlerts
          ? _self.operationalAlerts
          : operationalAlerts // ignore: cast_nullable_to_non_nullable
              as OperationalAlerts,
      currentDutyStatus: null == currentDutyStatus
          ? _self.currentDutyStatus
          : currentDutyStatus // ignore: cast_nullable_to_non_nullable
              as DutyStatusCode,
      remainingCircle: null == remainingCircle
          ? _self.remainingCircle
          : remainingCircle // ignore: cast_nullable_to_non_nullable
              as RemainingCircle,
      hosIndicators: null == hosIndicators
          ? _self.hosIndicators
          : hosIndicators // ignore: cast_nullable_to_non_nullable
              as HosIndicators,
      regulatoryConstraints: null == regulatoryConstraints
          ? _self.regulatoryConstraints
          : regulatoryConstraints // ignore: cast_nullable_to_non_nullable
              as RegulatoryConstraints,
    ));
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverRefCopyWith<$Res> get driver {
    return $DriverRefCopyWith<$Res>(_self.driver, (value) {
      return _then(_self.copyWith(driver: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OperationalAlertsCopyWith<$Res> get operationalAlerts {
    return $OperationalAlertsCopyWith<$Res>(_self.operationalAlerts, (value) {
      return _then(_self.copyWith(operationalAlerts: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RemainingCircleCopyWith<$Res> get remainingCircle {
    return $RemainingCircleCopyWith<$Res>(_self.remainingCircle, (value) {
      return _then(_self.copyWith(remainingCircle: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorsCopyWith<$Res> get hosIndicators {
    return $HosIndicatorsCopyWith<$Res>(_self.hosIndicators, (value) {
      return _then(_self.copyWith(hosIndicators: value));
    });
  }

  /// Create a copy of StatusDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegulatoryConstraintsCopyWith<$Res> get regulatoryConstraints {
    return $RegulatoryConstraintsCopyWith<$Res>(_self.regulatoryConstraints,
        (value) {
      return _then(_self.copyWith(regulatoryConstraints: value));
    });
  }
}

/// @nodoc
mixin _$DriverRef {
  DriverId get id;
  String get name;
  String get displayText;

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DriverRefCopyWith<DriverRef> get copyWith =>
      _$DriverRefCopyWithImpl<DriverRef>(this as DriverRef, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DriverRef &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayText, displayText) ||
                other.displayText == displayText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, displayText);

  @override
  String toString() {
    return 'DriverRef(id: $id, name: $name, displayText: $displayText)';
  }
}

/// @nodoc
abstract mixin class $DriverRefCopyWith<$Res> {
  factory $DriverRefCopyWith(DriverRef value, $Res Function(DriverRef) _then) =
      _$DriverRefCopyWithImpl;
  @useResult
  $Res call({DriverId id, String name, String displayText});

  $DriverIdCopyWith<$Res> get id;
}

/// @nodoc
class _$DriverRefCopyWithImpl<$Res> implements $DriverRefCopyWith<$Res> {
  _$DriverRefCopyWithImpl(this._self, this._then);

  final DriverRef _self;
  final $Res Function(DriverRef) _then;

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayText = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as DriverId,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayText: null == displayText
          ? _self.displayText
          : displayText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverIdCopyWith<$Res> get id {
    return $DriverIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }
}

/// @nodoc

class _DriverRef implements DriverRef {
  const _DriverRef(
      {required this.id, required this.name, required this.displayText});

  @override
  final DriverId id;
  @override
  final String name;
  @override
  final String displayText;

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DriverRefCopyWith<_DriverRef> get copyWith =>
      __$DriverRefCopyWithImpl<_DriverRef>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DriverRef &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayText, displayText) ||
                other.displayText == displayText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, displayText);

  @override
  String toString() {
    return 'DriverRef(id: $id, name: $name, displayText: $displayText)';
  }
}

/// @nodoc
abstract mixin class _$DriverRefCopyWith<$Res>
    implements $DriverRefCopyWith<$Res> {
  factory _$DriverRefCopyWith(
          _DriverRef value, $Res Function(_DriverRef) _then) =
      __$DriverRefCopyWithImpl;
  @override
  @useResult
  $Res call({DriverId id, String name, String displayText});

  @override
  $DriverIdCopyWith<$Res> get id;
}

/// @nodoc
class __$DriverRefCopyWithImpl<$Res> implements _$DriverRefCopyWith<$Res> {
  __$DriverRefCopyWithImpl(this._self, this._then);

  final _DriverRef _self;
  final $Res Function(_DriverRef) _then;

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayText = null,
  }) {
    return _then(_DriverRef(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as DriverId,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayText: null == displayText
          ? _self.displayText
          : displayText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of DriverRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverIdCopyWith<$Res> get id {
    return $DriverIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }
}

/// @nodoc
mixin _$OperationalAlerts {
  bool get toolIcon;
  bool get warningTriangleIcon;
  ConnectionStatus get connectionStatus;

  /// Create a copy of OperationalAlerts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OperationalAlertsCopyWith<OperationalAlerts> get copyWith =>
      _$OperationalAlertsCopyWithImpl<OperationalAlerts>(
          this as OperationalAlerts, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OperationalAlerts &&
            (identical(other.toolIcon, toolIcon) ||
                other.toolIcon == toolIcon) &&
            (identical(other.warningTriangleIcon, warningTriangleIcon) ||
                other.warningTriangleIcon == warningTriangleIcon) &&
            (identical(other.connectionStatus, connectionStatus) ||
                other.connectionStatus == connectionStatus));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, toolIcon, warningTriangleIcon, connectionStatus);

  @override
  String toString() {
    return 'OperationalAlerts(toolIcon: $toolIcon, warningTriangleIcon: $warningTriangleIcon, connectionStatus: $connectionStatus)';
  }
}

/// @nodoc
abstract mixin class $OperationalAlertsCopyWith<$Res> {
  factory $OperationalAlertsCopyWith(
          OperationalAlerts value, $Res Function(OperationalAlerts) _then) =
      _$OperationalAlertsCopyWithImpl;
  @useResult
  $Res call(
      {bool toolIcon,
      bool warningTriangleIcon,
      ConnectionStatus connectionStatus});
}

/// @nodoc
class _$OperationalAlertsCopyWithImpl<$Res>
    implements $OperationalAlertsCopyWith<$Res> {
  _$OperationalAlertsCopyWithImpl(this._self, this._then);

  final OperationalAlerts _self;
  final $Res Function(OperationalAlerts) _then;

  /// Create a copy of OperationalAlerts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? toolIcon = null,
    Object? warningTriangleIcon = null,
    Object? connectionStatus = null,
  }) {
    return _then(_self.copyWith(
      toolIcon: null == toolIcon
          ? _self.toolIcon
          : toolIcon // ignore: cast_nullable_to_non_nullable
              as bool,
      warningTriangleIcon: null == warningTriangleIcon
          ? _self.warningTriangleIcon
          : warningTriangleIcon // ignore: cast_nullable_to_non_nullable
              as bool,
      connectionStatus: null == connectionStatus
          ? _self.connectionStatus
          : connectionStatus // ignore: cast_nullable_to_non_nullable
              as ConnectionStatus,
    ));
  }
}

/// @nodoc

class _OperationalAlerts implements OperationalAlerts {
  const _OperationalAlerts(
      {required this.toolIcon,
      required this.warningTriangleIcon,
      required this.connectionStatus});

  @override
  final bool toolIcon;
  @override
  final bool warningTriangleIcon;
  @override
  final ConnectionStatus connectionStatus;

  /// Create a copy of OperationalAlerts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OperationalAlertsCopyWith<_OperationalAlerts> get copyWith =>
      __$OperationalAlertsCopyWithImpl<_OperationalAlerts>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OperationalAlerts &&
            (identical(other.toolIcon, toolIcon) ||
                other.toolIcon == toolIcon) &&
            (identical(other.warningTriangleIcon, warningTriangleIcon) ||
                other.warningTriangleIcon == warningTriangleIcon) &&
            (identical(other.connectionStatus, connectionStatus) ||
                other.connectionStatus == connectionStatus));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, toolIcon, warningTriangleIcon, connectionStatus);

  @override
  String toString() {
    return 'OperationalAlerts(toolIcon: $toolIcon, warningTriangleIcon: $warningTriangleIcon, connectionStatus: $connectionStatus)';
  }
}

/// @nodoc
abstract mixin class _$OperationalAlertsCopyWith<$Res>
    implements $OperationalAlertsCopyWith<$Res> {
  factory _$OperationalAlertsCopyWith(
          _OperationalAlerts value, $Res Function(_OperationalAlerts) _then) =
      __$OperationalAlertsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool toolIcon,
      bool warningTriangleIcon,
      ConnectionStatus connectionStatus});
}

/// @nodoc
class __$OperationalAlertsCopyWithImpl<$Res>
    implements _$OperationalAlertsCopyWith<$Res> {
  __$OperationalAlertsCopyWithImpl(this._self, this._then);

  final _OperationalAlerts _self;
  final $Res Function(_OperationalAlerts) _then;

  /// Create a copy of OperationalAlerts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? toolIcon = null,
    Object? warningTriangleIcon = null,
    Object? connectionStatus = null,
  }) {
    return _then(_OperationalAlerts(
      toolIcon: null == toolIcon
          ? _self.toolIcon
          : toolIcon // ignore: cast_nullable_to_non_nullable
              as bool,
      warningTriangleIcon: null == warningTriangleIcon
          ? _self.warningTriangleIcon
          : warningTriangleIcon // ignore: cast_nullable_to_non_nullable
              as bool,
      connectionStatus: null == connectionStatus
          ? _self.connectionStatus
          : connectionStatus // ignore: cast_nullable_to_non_nullable
              as ConnectionStatus,
    ));
  }
}

/// @nodoc
mixin _$RemainingCircle {
  /// Remaining legal time.
  Duration get remaining;

  /// Label shown above the time.
  String get label;

  /// Progress in `[0.0, 1.0]`.
  double get progress;

  /// Create a copy of RemainingCircle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemainingCircleCopyWith<RemainingCircle> get copyWith =>
      _$RemainingCircleCopyWithImpl<RemainingCircle>(
          this as RemainingCircle, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemainingCircle &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, remaining, label, progress);

  @override
  String toString() {
    return 'RemainingCircle(remaining: $remaining, label: $label, progress: $progress)';
  }
}

/// @nodoc
abstract mixin class $RemainingCircleCopyWith<$Res> {
  factory $RemainingCircleCopyWith(
          RemainingCircle value, $Res Function(RemainingCircle) _then) =
      _$RemainingCircleCopyWithImpl;
  @useResult
  $Res call({Duration remaining, String label, double progress});
}

/// @nodoc
class _$RemainingCircleCopyWithImpl<$Res>
    implements $RemainingCircleCopyWith<$Res> {
  _$RemainingCircleCopyWithImpl(this._self, this._then);

  final RemainingCircle _self;
  final $Res Function(RemainingCircle) _then;

  /// Create a copy of RemainingCircle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? remaining = null,
    Object? label = null,
    Object? progress = null,
  }) {
    return _then(_self.copyWith(
      remaining: null == remaining
          ? _self.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as Duration,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _RemainingCircle extends RemainingCircle {
  const _RemainingCircle(
      {required this.remaining, required this.label, required this.progress})
      : super._();

  /// Remaining legal time.
  @override
  final Duration remaining;

  /// Label shown above the time.
  @override
  final String label;

  /// Progress in `[0.0, 1.0]`.
  @override
  final double progress;

  /// Create a copy of RemainingCircle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RemainingCircleCopyWith<_RemainingCircle> get copyWith =>
      __$RemainingCircleCopyWithImpl<_RemainingCircle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RemainingCircle &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, remaining, label, progress);

  @override
  String toString() {
    return 'RemainingCircle(remaining: $remaining, label: $label, progress: $progress)';
  }
}

/// @nodoc
abstract mixin class _$RemainingCircleCopyWith<$Res>
    implements $RemainingCircleCopyWith<$Res> {
  factory _$RemainingCircleCopyWith(
          _RemainingCircle value, $Res Function(_RemainingCircle) _then) =
      __$RemainingCircleCopyWithImpl;
  @override
  @useResult
  $Res call({Duration remaining, String label, double progress});
}

/// @nodoc
class __$RemainingCircleCopyWithImpl<$Res>
    implements _$RemainingCircleCopyWith<$Res> {
  __$RemainingCircleCopyWithImpl(this._self, this._then);

  final _RemainingCircle _self;
  final $Res Function(_RemainingCircle) _then;

  /// Create a copy of RemainingCircle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? remaining = null,
    Object? label = null,
    Object? progress = null,
  }) {
    return _then(_RemainingCircle(
      remaining: null == remaining
          ? _self.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as Duration,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$HosIndicators {
  HosIndicator get drive;
  HosIndicator get shift;
  HosIndicator get breakTime;
  HosIndicator get cycle;

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HosIndicatorsCopyWith<HosIndicators> get copyWith =>
      _$HosIndicatorsCopyWithImpl<HosIndicators>(
          this as HosIndicators, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HosIndicators &&
            (identical(other.drive, drive) || other.drive == drive) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.breakTime, breakTime) ||
                other.breakTime == breakTime) &&
            (identical(other.cycle, cycle) || other.cycle == cycle));
  }

  @override
  int get hashCode => Object.hash(runtimeType, drive, shift, breakTime, cycle);

  @override
  String toString() {
    return 'HosIndicators(drive: $drive, shift: $shift, breakTime: $breakTime, cycle: $cycle)';
  }
}

/// @nodoc
abstract mixin class $HosIndicatorsCopyWith<$Res> {
  factory $HosIndicatorsCopyWith(
          HosIndicators value, $Res Function(HosIndicators) _then) =
      _$HosIndicatorsCopyWithImpl;
  @useResult
  $Res call(
      {HosIndicator drive,
      HosIndicator shift,
      HosIndicator breakTime,
      HosIndicator cycle});

  $HosIndicatorCopyWith<$Res> get drive;
  $HosIndicatorCopyWith<$Res> get shift;
  $HosIndicatorCopyWith<$Res> get breakTime;
  $HosIndicatorCopyWith<$Res> get cycle;
}

/// @nodoc
class _$HosIndicatorsCopyWithImpl<$Res>
    implements $HosIndicatorsCopyWith<$Res> {
  _$HosIndicatorsCopyWithImpl(this._self, this._then);

  final HosIndicators _self;
  final $Res Function(HosIndicators) _then;

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? drive = null,
    Object? shift = null,
    Object? breakTime = null,
    Object? cycle = null,
  }) {
    return _then(_self.copyWith(
      drive: null == drive
          ? _self.drive
          : drive // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      shift: null == shift
          ? _self.shift
          : shift // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      breakTime: null == breakTime
          ? _self.breakTime
          : breakTime // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      cycle: null == cycle
          ? _self.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
    ));
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get drive {
    return $HosIndicatorCopyWith<$Res>(_self.drive, (value) {
      return _then(_self.copyWith(drive: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get shift {
    return $HosIndicatorCopyWith<$Res>(_self.shift, (value) {
      return _then(_self.copyWith(shift: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get breakTime {
    return $HosIndicatorCopyWith<$Res>(_self.breakTime, (value) {
      return _then(_self.copyWith(breakTime: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get cycle {
    return $HosIndicatorCopyWith<$Res>(_self.cycle, (value) {
      return _then(_self.copyWith(cycle: value));
    });
  }
}

/// @nodoc

class _HosIndicators implements HosIndicators {
  const _HosIndicators(
      {required this.drive,
      required this.shift,
      required this.breakTime,
      required this.cycle});

  @override
  final HosIndicator drive;
  @override
  final HosIndicator shift;
  @override
  final HosIndicator breakTime;
  @override
  final HosIndicator cycle;

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HosIndicatorsCopyWith<_HosIndicators> get copyWith =>
      __$HosIndicatorsCopyWithImpl<_HosIndicators>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HosIndicators &&
            (identical(other.drive, drive) || other.drive == drive) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.breakTime, breakTime) ||
                other.breakTime == breakTime) &&
            (identical(other.cycle, cycle) || other.cycle == cycle));
  }

  @override
  int get hashCode => Object.hash(runtimeType, drive, shift, breakTime, cycle);

  @override
  String toString() {
    return 'HosIndicators(drive: $drive, shift: $shift, breakTime: $breakTime, cycle: $cycle)';
  }
}

/// @nodoc
abstract mixin class _$HosIndicatorsCopyWith<$Res>
    implements $HosIndicatorsCopyWith<$Res> {
  factory _$HosIndicatorsCopyWith(
          _HosIndicators value, $Res Function(_HosIndicators) _then) =
      __$HosIndicatorsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {HosIndicator drive,
      HosIndicator shift,
      HosIndicator breakTime,
      HosIndicator cycle});

  @override
  $HosIndicatorCopyWith<$Res> get drive;
  @override
  $HosIndicatorCopyWith<$Res> get shift;
  @override
  $HosIndicatorCopyWith<$Res> get breakTime;
  @override
  $HosIndicatorCopyWith<$Res> get cycle;
}

/// @nodoc
class __$HosIndicatorsCopyWithImpl<$Res>
    implements _$HosIndicatorsCopyWith<$Res> {
  __$HosIndicatorsCopyWithImpl(this._self, this._then);

  final _HosIndicators _self;
  final $Res Function(_HosIndicators) _then;

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? drive = null,
    Object? shift = null,
    Object? breakTime = null,
    Object? cycle = null,
  }) {
    return _then(_HosIndicators(
      drive: null == drive
          ? _self.drive
          : drive // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      shift: null == shift
          ? _self.shift
          : shift // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      breakTime: null == breakTime
          ? _self.breakTime
          : breakTime // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
      cycle: null == cycle
          ? _self.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as HosIndicator,
    ));
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get drive {
    return $HosIndicatorCopyWith<$Res>(_self.drive, (value) {
      return _then(_self.copyWith(drive: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get shift {
    return $HosIndicatorCopyWith<$Res>(_self.shift, (value) {
      return _then(_self.copyWith(shift: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get breakTime {
    return $HosIndicatorCopyWith<$Res>(_self.breakTime, (value) {
      return _then(_self.copyWith(breakTime: value));
    });
  }

  /// Create a copy of HosIndicators
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<$Res> get cycle {
    return $HosIndicatorCopyWith<$Res>(_self.cycle, (value) {
      return _then(_self.copyWith(cycle: value));
    });
  }
}

/// @nodoc
mixin _$HosIndicator {
  /// Backend-supplied label (e.g. "DRIVE").
  String get label;

  /// Duration value.
  Duration get value;

  /// Whether this value is "used" or "remaining".
  IndicatorType get type;

  /// Create a copy of HosIndicator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HosIndicatorCopyWith<HosIndicator> get copyWith =>
      _$HosIndicatorCopyWithImpl<HosIndicator>(
          this as HosIndicator, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HosIndicator &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, label, value, type);

  @override
  String toString() {
    return 'HosIndicator(label: $label, value: $value, type: $type)';
  }
}

/// @nodoc
abstract mixin class $HosIndicatorCopyWith<$Res> {
  factory $HosIndicatorCopyWith(
          HosIndicator value, $Res Function(HosIndicator) _then) =
      _$HosIndicatorCopyWithImpl;
  @useResult
  $Res call({String label, Duration value, IndicatorType type});
}

/// @nodoc
class _$HosIndicatorCopyWithImpl<$Res> implements $HosIndicatorCopyWith<$Res> {
  _$HosIndicatorCopyWithImpl(this._self, this._then);

  final HosIndicator _self;
  final $Res Function(HosIndicator) _then;

  /// Create a copy of HosIndicator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? type = null,
  }) {
    return _then(_self.copyWith(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Duration,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as IndicatorType,
    ));
  }
}

/// @nodoc

class _HosIndicator implements HosIndicator {
  const _HosIndicator(
      {required this.label, required this.value, required this.type});

  /// Backend-supplied label (e.g. "DRIVE").
  @override
  final String label;

  /// Duration value.
  @override
  final Duration value;

  /// Whether this value is "used" or "remaining".
  @override
  final IndicatorType type;

  /// Create a copy of HosIndicator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HosIndicatorCopyWith<_HosIndicator> get copyWith =>
      __$HosIndicatorCopyWithImpl<_HosIndicator>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HosIndicator &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, label, value, type);

  @override
  String toString() {
    return 'HosIndicator(label: $label, value: $value, type: $type)';
  }
}

/// @nodoc
abstract mixin class _$HosIndicatorCopyWith<$Res>
    implements $HosIndicatorCopyWith<$Res> {
  factory _$HosIndicatorCopyWith(
          _HosIndicator value, $Res Function(_HosIndicator) _then) =
      __$HosIndicatorCopyWithImpl;
  @override
  @useResult
  $Res call({String label, Duration value, IndicatorType type});
}

/// @nodoc
class __$HosIndicatorCopyWithImpl<$Res>
    implements _$HosIndicatorCopyWith<$Res> {
  __$HosIndicatorCopyWithImpl(this._self, this._then);

  final _HosIndicator _self;
  final $Res Function(_HosIndicator) _then;

  /// Create a copy of HosIndicator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? type = null,
  }) {
    return _then(_HosIndicator(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Duration,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as IndicatorType,
    ));
  }
}

/// @nodoc
mixin _$RegulatoryConstraints {
  CycleRule get ruleSet;
  List<String> get limits;

  /// Create a copy of RegulatoryConstraints
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RegulatoryConstraintsCopyWith<RegulatoryConstraints> get copyWith =>
      _$RegulatoryConstraintsCopyWithImpl<RegulatoryConstraints>(
          this as RegulatoryConstraints, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RegulatoryConstraints &&
            (identical(other.ruleSet, ruleSet) || other.ruleSet == ruleSet) &&
            const DeepCollectionEquality().equals(other.limits, limits));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, ruleSet, const DeepCollectionEquality().hash(limits));

  @override
  String toString() {
    return 'RegulatoryConstraints(ruleSet: $ruleSet, limits: $limits)';
  }
}

/// @nodoc
abstract mixin class $RegulatoryConstraintsCopyWith<$Res> {
  factory $RegulatoryConstraintsCopyWith(RegulatoryConstraints value,
          $Res Function(RegulatoryConstraints) _then) =
      _$RegulatoryConstraintsCopyWithImpl;
  @useResult
  $Res call({CycleRule ruleSet, List<String> limits});
}

/// @nodoc
class _$RegulatoryConstraintsCopyWithImpl<$Res>
    implements $RegulatoryConstraintsCopyWith<$Res> {
  _$RegulatoryConstraintsCopyWithImpl(this._self, this._then);

  final RegulatoryConstraints _self;
  final $Res Function(RegulatoryConstraints) _then;

  /// Create a copy of RegulatoryConstraints
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ruleSet = null,
    Object? limits = null,
  }) {
    return _then(_self.copyWith(
      ruleSet: null == ruleSet
          ? _self.ruleSet
          : ruleSet // ignore: cast_nullable_to_non_nullable
              as CycleRule,
      limits: null == limits
          ? _self.limits
          : limits // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _RegulatoryConstraints implements RegulatoryConstraints {
  const _RegulatoryConstraints(
      {required this.ruleSet, required final List<String> limits})
      : _limits = limits;

  @override
  final CycleRule ruleSet;
  final List<String> _limits;
  @override
  List<String> get limits {
    if (_limits is EqualUnmodifiableListView) return _limits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_limits);
  }

  /// Create a copy of RegulatoryConstraints
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RegulatoryConstraintsCopyWith<_RegulatoryConstraints> get copyWith =>
      __$RegulatoryConstraintsCopyWithImpl<_RegulatoryConstraints>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RegulatoryConstraints &&
            (identical(other.ruleSet, ruleSet) || other.ruleSet == ruleSet) &&
            const DeepCollectionEquality().equals(other._limits, _limits));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, ruleSet, const DeepCollectionEquality().hash(_limits));

  @override
  String toString() {
    return 'RegulatoryConstraints(ruleSet: $ruleSet, limits: $limits)';
  }
}

/// @nodoc
abstract mixin class _$RegulatoryConstraintsCopyWith<$Res>
    implements $RegulatoryConstraintsCopyWith<$Res> {
  factory _$RegulatoryConstraintsCopyWith(_RegulatoryConstraints value,
          $Res Function(_RegulatoryConstraints) _then) =
      __$RegulatoryConstraintsCopyWithImpl;
  @override
  @useResult
  $Res call({CycleRule ruleSet, List<String> limits});
}

/// @nodoc
class __$RegulatoryConstraintsCopyWithImpl<$Res>
    implements _$RegulatoryConstraintsCopyWith<$Res> {
  __$RegulatoryConstraintsCopyWithImpl(this._self, this._then);

  final _RegulatoryConstraints _self;
  final $Res Function(_RegulatoryConstraints) _then;

  /// Create a copy of RegulatoryConstraints
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ruleSet = null,
    Object? limits = null,
  }) {
    return _then(_RegulatoryConstraints(
      ruleSet: null == ruleSet
          ? _self.ruleSet
          : ruleSet // ignore: cast_nullable_to_non_nullable
              as CycleRule,
      limits: null == limits
          ? _self._limits
          : limits // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
