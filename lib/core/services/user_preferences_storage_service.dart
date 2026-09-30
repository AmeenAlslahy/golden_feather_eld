import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _onboardingSeenKey = 'onboarding_seen';

  bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeenKey, true);

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
