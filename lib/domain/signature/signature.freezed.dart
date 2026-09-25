// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signature.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignatureCertificate {
  String get signatureId;
  DriverId get driverId;
  String get logDate;
  String get signatureHash;
  DateTime get signedAt;
  CertificateStatus get status;

  /// Create a copy of SignatureCertificate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SignatureCertificateCopyWith<SignatureCertificate> get copyWith =>
      _$SignatureCertificateCopyWithImpl<SignatureCertificate>(
          this as SignatureCertificate, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SignatureCertificate &&
            (identical(other.signatureId, signatureId) ||
                other.signatureId == signatureId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.logDate, logDate) || other.logDate == logDate) &&
            (identical(other.signatureHash, signatureHash) ||
                other.signatureHash == signatureHash) &&
            (identical(other.signedAt, signedAt) ||
                other.signedAt == signedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signatureId, driverId, logDate,
      signatureHash, signedAt, status);

  @override
  String toString() {
    return 'SignatureCertificate(signatureId: $signatureId, driverId: $driverId, logDate: $logDate, signatureHash: $signatureHash, signedAt: $signedAt, status: $status)';
  }
}

/// @nodoc
abstract mixin class $SignatureCertificateCopyWith<$Res> {
  factory $SignatureCertificateCopyWith(SignatureCertificate value,
          $Res Function(SignatureCertificate) _then) =
      _$SignatureCertificateCopyWithImpl;
  @useResult
  $Res call(
      {String signatureId,
      DriverId driverId,
      String logDate,
      String signatureHash,
      DateTime signedAt,
      CertificateStatus status});

  $DriverIdCopyWith<$Res> get driverId;
}

/// @nodoc
class _$SignatureCertificateCopyWithImpl<$Res>
    implements $SignatureCertificateCopyWith<$Res> {
  _$SignatureCertificateCopyWithImpl(this._self, this._then);

  final SignatureCertificate _self;
  final $Res Function(SignatureCertificate) _then;

  /// Create a copy of SignatureCertificate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signatureId = null,
    Object? driverId = null,
    Object? logDate = null,
    Object? signatureHash = null,
    Object? signedAt = null,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      signatureId: null == signatureId
          ? _self.signatureId
          : signatureId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _self.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as DriverId,
      logDate: null == logDate
          ? _self.logDate
          : logDate // ignore: cast_nullable_to_non_nullable
              as String,
      signatureHash: null == signatureHash
          ? _self.signatureHash
          : signatureHash // ignore: cast_nullable_to_non_nullable
              as String,
      signedAt: null == signedAt
          ? _self.signedAt
          : signedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as CertificateStatus,
    ));
  }

  /// Create a copy of SignatureCertificate
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

class _SignatureCertificate implements SignatureCertificate {
  const _SignatureCertificate(
      {required this.signatureId,
      required this.driverId,
      required this.logDate,
      required this.signatureHash,
      required this.signedAt,
      required this.status});

  @override
  final String signatureId;
  @override
  final DriverId driverId;
  @override
  final String logDate;
  @override
  final String signatureHash;
  @override
  final DateTime signedAt;
  @override
  final CertificateStatus status;

  /// Create a copy of SignatureCertificate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SignatureCertificateCopyWith<_SignatureCertificate> get copyWith =>
      __$SignatureCertificateCopyWithImpl<_SignatureCertificate>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SignatureCertificate &&
            (identical(other.signatureId, signatureId) ||
                other.signatureId == signatureId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.logDate, logDate) || other.logDate == logDate) &&
            (identical(other.signatureHash, signatureHash) ||
                other.signatureHash == signatureHash) &&
            (identical(other.signedAt, signedAt) ||
                other.signedAt == signedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signatureId, driverId, logDate,
      signatureHash, signedAt, status);

  @override
  String toString() {
    return 'SignatureCertificate(signatureId: $signatureId, driverId: $driverId, logDate: $logDate, signatureHash: $signatureHash, signedAt: $signedAt, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$SignatureCertificateCopyWith<$Res>
    implements $SignatureCertificateCopyWith<$Res> {
  factory _$SignatureCertificateCopyWith(_SignatureCertificate value,
          $Res Function(_SignatureCertificate) _then) =
      __$SignatureCertificateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String signatureId,
      DriverId driverId,
      String logDate,
      String signatureHash,
      DateTime signedAt,
      CertificateStatus status});

  @override
  $DriverIdCopyWith<$Res> get driverId;
}

/// @nodoc
class __$SignatureCertificateCopyWithImpl<$Res>
    implements _$SignatureCertificateCopyWith<$Res> {
  __$SignatureCertificateCopyWithImpl(this._self, this._then);

  final _SignatureCertificate _self;
  final $Res Function(_SignatureCertificate) _then;

  /// Create a copy of SignatureCertificate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? signatureId = null,
    Object? driverId = null,
    Object? logDate = null,
    Object? signatureHash = null,
    Object? signedAt = null,
    Object? status = null,
  }) {
    return _then(_SignatureCertificate(
      signatureId: null == signatureId
          ? _self.signatureId
          : signatureId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _self.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as DriverId,
      logDate: null == logDate
          ? _self.logDate
          : logDate // ignore: cast_nullable_to_non_nullable
              as String,
      signatureHash: null == signatureHash
          ? _self.signatureHash
          : signatureHash // ignore: cast_nullable_to_non_nullable
              as String,
      signedAt: null == signedAt
          ? _self.signedAt
          : signedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as CertificateStatus,
    ));
  }

  /// Create a copy of SignatureCertificate
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
