import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../contracts/account_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [AccountBackend].
class EldAccountBackend implements AccountBackend {
  final ApiClient _apiClient;

  const EldAccountBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getProfile(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.profile(driverId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> updateProfile({
    required DriverId driverId,
    required RawJson update,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.profile(driverId.value),
      data: update,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  Map<String, dynamic> _mapAccountJson(Map<String, dynamic> json, {DriverId? fallbackDriverId}) {
    // 1. معالجة المعرف driverId
    if (json['driverId'] == null) {
      json['driverId'] = json['id'] ?? fallbackDriverId?.value ?? 0;
    }

    // 2. معالجة الرخصة license
    // السيرفر الحقيقي يعيد نصاً مثل "MI, A350622298913" بينما الموديل يحتاج Map
    if (json['license'] is String) {
      final licenseStr = json['license'] as String;
      final parts = licenseStr.split(',');
      final state = parts.isNotEmpty ? parts[0].trim() : '';
      final number = parts.length > 1 ? parts[1].trim() : licenseStr;
      
      json['license'] = {
        'state': state,
        'number': number,
        'formatted': licenseStr,
      };
    } else if (json['license'] == null) {
      json['license'] = {
        'state': '',
        'number': '',
        'formatted': 'N/A',
      };
    }

    // 3. معالجة المنطقة الزمنية timeZone
    if (json['timeZone'] == null) {
      json['timeZone'] = json['timezone'] ?? 'Unknown';
    }

    return json;
  }

  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.account,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) {
      final mappedJson = _mapAccountJson(r.data ?? <String, dynamic>{}, fallbackDriverId: driverId);
      return DriverAccount.fromJson(mappedJson);
    });
  }

  @override
  Future<Result<DriverAccount>> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.accountPreferences,
      data: {
        'language': language,
        'odometer': odometerUnit,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) {
      final mappedJson = _mapAccountJson(r.data ?? <String, dynamic>{});
      return DriverAccount.fromJson(mappedJson);
    });
  }
}
