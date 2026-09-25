import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_service.dart';

class UserPreferencesStorageService {
  final SharedPreferencesWithCache _prefs;

  UserPreferencesStorageService(this._prefs);

  // Keys
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';
  static const String _selectedVehicleKey = 'selected_vehicle';
  static const String _currentDutyStatusKey = 'current_duty_status';
  static const String _stationarySinceKey = 'stationary_since';

  // Getters
  String get language => _prefs.getString(_languageKey) ?? 'ar';
  String get theme => _prefs.getString(_themeKey) ?? 'system';
  String get currentDutyStatus =>
      _prefs.getString(_currentDutyStatusKey) ?? 'off_duty';
  String? get stationarySince => _prefs.getString(_stationarySinceKey);
  String? get selectedVehicleId => _prefs.getString(_selectedVehicleKey);

  // Setters
  Future<void> setLanguage(String value) =>
      _prefs.setString(_languageKey, value);
  Future<void> setTheme(String value) => _prefs.setString(_themeKey, value);
  Future<void> setCurrentDutyStatus(String value) =>
      _prefs.setString(_currentDutyStatusKey, value);
  Future<void> setStationarySince(String value) =>
      _prefs.setString(_stationarySinceKey, value);

  Future<void> saveSelectedVehicleId(String id) =>
      _prefs.setString(_selectedVehicleKey, id);
  Future<void> clearSelectedVehicle() => _prefs.remove(_selectedVehicleKey);
}

final userPreferencesStorageProvider =
    Provider<UserPreferencesStorageService>((ref) {
  // We temporarily read from the existing local storage provider to get the shared prefs instance.
  final localStorage = ref.watch(localStorageProvider);
  return UserPreferencesStorageService(localStorage.prefs);
});
