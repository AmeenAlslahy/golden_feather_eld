// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerConfig {
  /// Full base URL including the `/api` path.
  /// **No trailing slash.**
  String get baseUrl;
  BackendType get backendType;

  /// When the URL was last verified via a probe.
  DateTime get lastTestedAt;

  /// Whether the last probe succeeded.
  bool get isVerified;

  /// Create a copy of ServerConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ServerConfigCopyWith<ServerConfig> get copyWith =>
      _$ServerConfigCopyWithImpl<ServerConfig>(
          this as ServerConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ServerConfig &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.backendType, backendType) ||
                other.backendType == backendType) &&
            (identical(other.lastTestedAt, lastTestedAt) ||
                other.lastTestedAt == lastTestedAt) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, baseUrl, backendType, lastTestedAt, isVerified);

  @override
  String toString() {
    return 'ServerConfig(baseUrl: $baseUrl, backendType: $backendType, lastTestedAt: $lastTestedAt, isVerified: $isVerified)';
  }
}

/// @nodoc
abstract mixin class $ServerConfigCopyWith<$Res> {
  factory $ServerConfigCopyWith(
          ServerConfig value, $Res Function(ServerConfig) _then) =
      _$ServerConfigCopyWithImpl;
  @useResult
  $Res call(
      {String baseUrl,
      BackendType backendType,
      DateTime lastTestedAt,
      bool isVerified});
}

/// @nodoc
class _$ServerConfigCopyWithImpl<$Res> implements $ServerConfigCopyWith<$Res> {
  _$ServerConfigCopyWithImpl(this._self, this._then);

  final ServerConfig _self;
  final $Res Function(ServerConfig) _then;

  /// Create a copy of ServerConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseUrl = null,
    Object? backendType = null,
    Object? lastTestedAt = null,
    Object? isVerified = null,
  }) {
    return _then(_self.copyWith(
      baseUrl: null == baseUrl
          ? _self.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      backendType: null == backendType
          ? _self.backendType
          : backendType // ignore: cast_nullable_to_non_nullable
              as BackendType,
      lastTestedAt: null == lastTestedAt
          ? _self.lastTestedAt
          : lastTestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVerified: null == isVerified
          ? _self.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _ServerConfig extends ServerConfig {
  const _ServerConfig(
      {required this.baseUrl,
      required this.backendType,
      required this.lastTestedAt,
      required this.isVerified})
      : super._();

  /// Full base URL including the `/api` path.
  /// **No trailing slash.**
  @override
  final String baseUrl;
  @override
  final BackendType backendType;

  /// When the URL was last verified via a probe.
  @override
  final DateTime lastTestedAt;

  /// Whether the last probe succeeded.
  @override
  final bool isVerified;

  /// Create a copy of ServerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ServerConfigCopyWith<_ServerConfig> get copyWith =>
      __$ServerConfigCopyWithImpl<_ServerConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ServerConfig &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.backendType, backendType) ||
                other.backendType == backendType) &&
            (identical(other.lastTestedAt, lastTestedAt) ||
                other.lastTestedAt == lastTestedAt) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, baseUrl, backendType, lastTestedAt, isVerified);

  @override
  String toString() {
    return 'ServerConfig(baseUrl: $baseUrl, backendType: $backendType, lastTestedAt: $lastTestedAt, isVerified: $isVerified)';
  }
}

/// @nodoc
abstract mixin class _$ServerConfigCopyWith<$Res>
    implements $ServerConfigCopyWith<$Res> {
  factory _$ServerConfigCopyWith(
          _ServerConfig value, $Res Function(_ServerConfig) _then) =
      __$ServerConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String baseUrl,
      BackendType backendType,
      DateTime lastTestedAt,
      bool isVerified});
}

/// @nodoc
class __$ServerConfigCopyWithImpl<$Res>
    implements _$ServerConfigCopyWith<$Res> {
  __$ServerConfigCopyWithImpl(this._self, this._then);

  final _ServerConfig _self;
  final $Res Function(_ServerConfig) _then;

  /// Create a copy of ServerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? baseUrl = null,
    Object? backendType = null,
    Object? lastTestedAt = null,
    Object? isVerified = null,
  }) {
    return _then(_ServerConfig(
      baseUrl: null == baseUrl
          ? _self.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      backendType: null == backendType
          ? _self.backendType
          : backendType // ignore: cast_nullable_to_non_nullable
              as BackendType,
      lastTestedAt: null == lastTestedAt
          ? _self.lastTestedAt
          : lastTestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVerified: null == isVerified
          ? _self.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
