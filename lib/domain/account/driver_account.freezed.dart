// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverAccount {
  int get driverId;
  String get email;
  String get phone;
  LicenseInfo get license;
  String get carrier;
  String get mainOfficeAddress;
  String get homeTerminalAddress;
  String get timeZone;
  String get language;
  String get odometer;
  List<String> get availableLanguages;
  List<String> get availableOdometerUnits;
  String? get notice;

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DriverAccountCopyWith<DriverAccount> get copyWith =>
      _$DriverAccountCopyWithImpl<DriverAccount>(
          this as DriverAccount, _$identity);

  /// Serializes this DriverAccount to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DriverAccount &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.license, license) || other.license == license) &&
            (identical(other.carrier, carrier) || other.carrier == carrier) &&
            (identical(other.mainOfficeAddress, mainOfficeAddress) ||
                other.mainOfficeAddress == mainOfficeAddress) &&
            (identical(other.homeTerminalAddress, homeTerminalAddress) ||
                other.homeTerminalAddress == homeTerminalAddress) &&
            (identical(other.timeZone, timeZone) ||
                other.timeZone == timeZone) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            const DeepCollectionEquality()
                .equals(other.availableLanguages, availableLanguages) &&
            const DeepCollectionEquality()
                .equals(other.availableOdometerUnits, availableOdometerUnits) &&
            (identical(other.notice, notice) || other.notice == notice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      driverId,
      email,
      phone,
      license,
      carrier,
      mainOfficeAddress,
      homeTerminalAddress,
      timeZone,
      language,
      odometer,
      const DeepCollectionEquality().hash(availableLanguages),
      const DeepCollectionEquality().hash(availableOdometerUnits),
      notice);

  @override
  String toString() {
    return 'DriverAccount(driverId: $driverId, email: $email, phone: $phone, license: $license, carrier: $carrier, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, timeZone: $timeZone, language: $language, odometer: $odometer, availableLanguages: $availableLanguages, availableOdometerUnits: $availableOdometerUnits, notice: $notice)';
  }
}

/// @nodoc
abstract mixin class $DriverAccountCopyWith<$Res> {
  factory $DriverAccountCopyWith(
          DriverAccount value, $Res Function(DriverAccount) _then) =
      _$DriverAccountCopyWithImpl;
  @useResult
  $Res call(
      {int driverId,
      String email,
      String phone,
      LicenseInfo license,
      String carrier,
      String mainOfficeAddress,
      String homeTerminalAddress,
      String timeZone,
      String language,
      String odometer,
      List<String> availableLanguages,
      List<String> availableOdometerUnits,
      String? notice});

  $LicenseInfoCopyWith<$Res> get license;
}

/// @nodoc
class _$DriverAccountCopyWithImpl<$Res>
    implements $DriverAccountCopyWith<$Res> {
  _$DriverAccountCopyWithImpl(this._self, this._then);

  final DriverAccount _self;
  final $Res Function(DriverAccount) _then;

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = null,
    Object? email = null,
    Object? phone = null,
    Object? license = null,
    Object? carrier = null,
    Object? mainOfficeAddress = null,
    Object? homeTerminalAddress = null,
    Object? timeZone = null,
    Object? language = null,
    Object? odometer = null,
    Object? availableLanguages = null,
    Object? availableOdometerUnits = null,
    Object? notice = freezed,
  }) {
    return _then(_self.copyWith(
      driverId: null == driverId
          ? _self.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      license: null == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as LicenseInfo,
      carrier: null == carrier
          ? _self.carrier
          : carrier // ignore: cast_nullable_to_non_nullable
              as String,
      mainOfficeAddress: null == mainOfficeAddress
          ? _self.mainOfficeAddress
          : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
              as String,
      homeTerminalAddress: null == homeTerminalAddress
          ? _self.homeTerminalAddress
          : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
              as String,
      timeZone: null == timeZone
          ? _self.timeZone
          : timeZone // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as String,
      availableLanguages: null == availableLanguages
          ? _self.availableLanguages
          : availableLanguages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableOdometerUnits: null == availableOdometerUnits
          ? _self.availableOdometerUnits
          : availableOdometerUnits // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notice: freezed == notice
          ? _self.notice
          : notice // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LicenseInfoCopyWith<$Res> get license {
    return $LicenseInfoCopyWith<$Res>(_self.license, (value) {
      return _then(_self.copyWith(license: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _DriverAccount implements DriverAccount {
  const _DriverAccount(
      {required this.driverId,
      required this.email,
      required this.phone,
      required this.license,
      required this.carrier,
      required this.mainOfficeAddress,
      required this.homeTerminalAddress,
      required this.timeZone,
      required this.language,
      required this.odometer,
      final List<String> availableLanguages = const [
        'English',
        'Spanish',
        'Arabic'
      ],
      final List<String> availableOdometerUnits = const ['mi', 'km'],
      this.notice})
      : _availableLanguages = availableLanguages,
        _availableOdometerUnits = availableOdometerUnits;
  factory _DriverAccount.fromJson(Map<String, dynamic> json) =>
      _$DriverAccountFromJson(json);

  @override
  final int driverId;
  @override
  final String email;
  @override
  final String phone;
  @override
  final LicenseInfo license;
  @override
  final String carrier;
  @override
  final String mainOfficeAddress;
  @override
  final String homeTerminalAddress;
  @override
  final String timeZone;
  @override
  final String language;
  @override
  final String odometer;
  final List<String> _availableLanguages;
  @override
  @JsonKey()
  List<String> get availableLanguages {
    if (_availableLanguages is EqualUnmodifiableListView)
      return _availableLanguages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableLanguages);
  }

  final List<String> _availableOdometerUnits;
  @override
  @JsonKey()
  List<String> get availableOdometerUnits {
    if (_availableOdometerUnits is EqualUnmodifiableListView)
      return _availableOdometerUnits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableOdometerUnits);
  }

  @override
  final String? notice;

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DriverAccountCopyWith<_DriverAccount> get copyWith =>
      __$DriverAccountCopyWithImpl<_DriverAccount>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DriverAccountToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DriverAccount &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.license, license) || other.license == license) &&
            (identical(other.carrier, carrier) || other.carrier == carrier) &&
            (identical(other.mainOfficeAddress, mainOfficeAddress) ||
                other.mainOfficeAddress == mainOfficeAddress) &&
            (identical(other.homeTerminalAddress, homeTerminalAddress) ||
                other.homeTerminalAddress == homeTerminalAddress) &&
            (identical(other.timeZone, timeZone) ||
                other.timeZone == timeZone) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            const DeepCollectionEquality()
                .equals(other._availableLanguages, _availableLanguages) &&
            const DeepCollectionEquality().equals(
                other._availableOdometerUnits, _availableOdometerUnits) &&
            (identical(other.notice, notice) || other.notice == notice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      driverId,
      email,
      phone,
      license,
      carrier,
      mainOfficeAddress,
      homeTerminalAddress,
      timeZone,
      language,
      odometer,
      const DeepCollectionEquality().hash(_availableLanguages),
      const DeepCollectionEquality().hash(_availableOdometerUnits),
      notice);

  @override
  String toString() {
    return 'DriverAccount(driverId: $driverId, email: $email, phone: $phone, license: $license, carrier: $carrier, mainOfficeAddress: $mainOfficeAddress, homeTerminalAddress: $homeTerminalAddress, timeZone: $timeZone, language: $language, odometer: $odometer, availableLanguages: $availableLanguages, availableOdometerUnits: $availableOdometerUnits, notice: $notice)';
  }
}

/// @nodoc
abstract mixin class _$DriverAccountCopyWith<$Res>
    implements $DriverAccountCopyWith<$Res> {
  factory _$DriverAccountCopyWith(
          _DriverAccount value, $Res Function(_DriverAccount) _then) =
      __$DriverAccountCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int driverId,
      String email,
      String phone,
      LicenseInfo license,
      String carrier,
      String mainOfficeAddress,
      String homeTerminalAddress,
      String timeZone,
      String language,
      String odometer,
      List<String> availableLanguages,
      List<String> availableOdometerUnits,
      String? notice});

  @override
  $LicenseInfoCopyWith<$Res> get license;
}

/// @nodoc
class __$DriverAccountCopyWithImpl<$Res>
    implements _$DriverAccountCopyWith<$Res> {
  __$DriverAccountCopyWithImpl(this._self, this._then);

  final _DriverAccount _self;
  final $Res Function(_DriverAccount) _then;

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? driverId = null,
    Object? email = null,
    Object? phone = null,
    Object? license = null,
    Object? carrier = null,
    Object? mainOfficeAddress = null,
    Object? homeTerminalAddress = null,
    Object? timeZone = null,
    Object? language = null,
    Object? odometer = null,
    Object? availableLanguages = null,
    Object? availableOdometerUnits = null,
    Object? notice = freezed,
  }) {
    return _then(_DriverAccount(
      driverId: null == driverId
          ? _self.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      license: null == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as LicenseInfo,
      carrier: null == carrier
          ? _self.carrier
          : carrier // ignore: cast_nullable_to_non_nullable
              as String,
      mainOfficeAddress: null == mainOfficeAddress
          ? _self.mainOfficeAddress
          : mainOfficeAddress // ignore: cast_nullable_to_non_nullable
              as String,
      homeTerminalAddress: null == homeTerminalAddress
          ? _self.homeTerminalAddress
          : homeTerminalAddress // ignore: cast_nullable_to_non_nullable
              as String,
      timeZone: null == timeZone
          ? _self.timeZone
          : timeZone // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as String,
      availableLanguages: null == availableLanguages
          ? _self._availableLanguages
          : availableLanguages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableOdometerUnits: null == availableOdometerUnits
          ? _self._availableOdometerUnits
          : availableOdometerUnits // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notice: freezed == notice
          ? _self.notice
          : notice // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of DriverAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LicenseInfoCopyWith<$Res> get license {
    return $LicenseInfoCopyWith<$Res>(_self.license, (value) {
      return _then(_self.copyWith(license: value));
    });
  }
}

/// @nodoc
mixin _$LicenseInfo {
  String get state;
  String get number;
  String get formatted;

  /// Create a copy of LicenseInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LicenseInfoCopyWith<LicenseInfo> get copyWith =>
      _$LicenseInfoCopyWithImpl<LicenseInfo>(this as LicenseInfo, _$identity);

  /// Serializes this LicenseInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LicenseInfo &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.formatted, formatted) ||
                other.formatted == formatted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, number, formatted);

  @override
  String toString() {
    return 'LicenseInfo(state: $state, number: $number, formatted: $formatted)';
  }
}

/// @nodoc
abstract mixin class $LicenseInfoCopyWith<$Res> {
  factory $LicenseInfoCopyWith(
          LicenseInfo value, $Res Function(LicenseInfo) _then) =
      _$LicenseInfoCopyWithImpl;
  @useResult
  $Res call({String state, String number, String formatted});
}

/// @nodoc
class _$LicenseInfoCopyWithImpl<$Res> implements $LicenseInfoCopyWith<$Res> {
  _$LicenseInfoCopyWithImpl(this._self, this._then);

  final LicenseInfo _self;
  final $Res Function(LicenseInfo) _then;

  /// Create a copy of LicenseInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? number = null,
    Object? formatted = null,
  }) {
    return _then(_self.copyWith(
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      formatted: null == formatted
          ? _self.formatted
          : formatted // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LicenseInfo implements LicenseInfo {
  const _LicenseInfo(
      {required this.state, required this.number, required this.formatted});
  factory _LicenseInfo.fromJson(Map<String, dynamic> json) =>
      _$LicenseInfoFromJson(json);

  @override
  final String state;
  @override
  final String number;
  @override
  final String formatted;

  /// Create a copy of LicenseInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LicenseInfoCopyWith<_LicenseInfo> get copyWith =>
      __$LicenseInfoCopyWithImpl<_LicenseInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LicenseInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LicenseInfo &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.formatted, formatted) ||
                other.formatted == formatted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, number, formatted);

  @override
  String toString() {
    return 'LicenseInfo(state: $state, number: $number, formatted: $formatted)';
  }
}

/// @nodoc
abstract mixin class _$LicenseInfoCopyWith<$Res>
    implements $LicenseInfoCopyWith<$Res> {
  factory _$LicenseInfoCopyWith(
          _LicenseInfo value, $Res Function(_LicenseInfo) _then) =
      __$LicenseInfoCopyWithImpl;
  @override
  @useResult
  $Res call({String state, String number, String formatted});
}

/// @nodoc
class __$LicenseInfoCopyWithImpl<$Res> implements _$LicenseInfoCopyWith<$Res> {
  __$LicenseInfoCopyWithImpl(this._self, this._then);

  final _LicenseInfo _self;
  final $Res Function(_LicenseInfo) _then;

  /// Create a copy of LicenseInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? state = null,
    Object? number = null,
    Object? formatted = null,
  }) {
    return _then(_LicenseInfo(
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      formatted: null == formatted
          ? _self.formatted
          : formatted // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
