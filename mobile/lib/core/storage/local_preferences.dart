import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';

class LocalPreferences {
  final SharedPreferences _prefs;

  LocalPreferences(this._prefs);

  static Future<LocalPreferences> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalPreferences(prefs);
  }

  bool get isOnboardingCompleted =>
      _prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(AppConstants.keyOnboardingCompleted, value);
  }

  String get themeMode =>
      _prefs.getString(AppConstants.keyThemeMode) ?? 'dark';

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(AppConstants.keyThemeMode, value);
  }

  String get apiBaseUrl {
    final saved = _prefs.getString(AppConstants.keyApiBaseUrl);
    // Ignore legacy or expired ngrok tunnels and empty strings
    if (saved == null ||
        saved.isEmpty ||
        saved.contains('utter-settle-sedation.ngrok-free.dev')) {
      return ApiConstants.defaultBaseUrl;
    }
    return saved;
  }

  Future<void> setApiBaseUrl(String value) async {
    await _prefs.setString(AppConstants.keyApiBaseUrl, value);
  }

  String? get cachedAccountsJson =>
      _prefs.getString(AppConstants.keyCachedAccounts);

  Future<void> setCachedAccountsJson(String value) async {
    await _prefs.setString(AppConstants.keyCachedAccounts, value);
  }

  Future<void> clearCachedAccounts() async {
    await _prefs.remove(AppConstants.keyCachedAccounts);
  }
}
