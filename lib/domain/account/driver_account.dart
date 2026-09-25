import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_account.freezed.dart';
part 'driver_account.g.dart';

@freezed
abstract class DriverAccount with _$DriverAccount {
  const factory DriverAccount({
    required int driverId,
    required String email,
    required String phone,
    required LicenseInfo license,
    required String carrier,
    required String mainOfficeAddress,
    required String homeTerminalAddress,
    required String timeZone,
    required String language,
    required String odometer,
    @Default(['English', 'Spanish', 'Arabic']) List<String> availableLanguages,
    @Default(['mi', 'km']) List<String> availableOdometerUnits,
    String? notice,
  }) = _DriverAccount;

  factory DriverAccount.fromJson(Map<String, dynamic> json) => _$DriverAccountFromJson(json);
}

@freezed
abstract class LicenseInfo with _$LicenseInfo {
  const factory LicenseInfo({
    required String state,
    required String number,
    required String formatted,
  }) = _LicenseInfo;

  factory LicenseInfo.fromJson(Map<String, dynamic> json) => _$LicenseInfoFromJson(json);
}
