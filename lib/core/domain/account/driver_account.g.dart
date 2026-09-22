// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverAccount _$DriverAccountFromJson(Map<String, dynamic> json) =>
    _DriverAccount(
      driverId: (json['driverId'] as num).toInt(),
      email: json['email'] as String,
      phone: json['phone'] as String,
      license: LicenseInfo.fromJson(json['license'] as Map<String, dynamic>),
      carrier: json['carrier'] as String,
      mainOfficeAddress: json['mainOfficeAddress'] as String,
      homeTerminalAddress: json['homeTerminalAddress'] as String,
      timeZone: json['timeZone'] as String,
      language: json['language'] as String,
      odometer: json['odometer'] as String,
      availableLanguages: (json['availableLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['English', 'Spanish', 'Arabic'],
      availableOdometerUnits: (json['availableOdometerUnits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['mi', 'km'],
      notice: json['notice'] as String?,
    );

Map<String, dynamic> _$DriverAccountToJson(_DriverAccount instance) =>
    <String, dynamic>{
      'driverId': instance.driverId,
      'email': instance.email,
      'phone': instance.phone,
      'license': instance.license,
      'carrier': instance.carrier,
      'mainOfficeAddress': instance.mainOfficeAddress,
      'homeTerminalAddress': instance.homeTerminalAddress,
      'timeZone': instance.timeZone,
      'language': instance.language,
      'odometer': instance.odometer,
      'availableLanguages': instance.availableLanguages,
      'availableOdometerUnits': instance.availableOdometerUnits,
      'notice': instance.notice,
    };

_LicenseInfo _$LicenseInfoFromJson(Map<String, dynamic> json) => _LicenseInfo(
      state: json['state'] as String,
      number: json['number'] as String,
      formatted: json['formatted'] as String,
    );

Map<String, dynamic> _$LicenseInfoToJson(_LicenseInfo instance) =>
    <String, dynamic>{
      'state': instance.state,
      'number': instance.number,
      'formatted': instance.formatted,
    };
