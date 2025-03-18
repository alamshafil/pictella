import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enum for preference keys to ensure type safety and consistency
enum AppPreferenceKey {
  hasSeenOnboarding,
  blurEffectsEnabled,
  hasStoredApiKey,
  // Add more keys here as needed
}

class AppPreferences {
  // Secure storage instance for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _apiKeyKey = 'gemini_api_key';

  // Generic methods to set and get preferences
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // API key management
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
    // Save a flag in regular preferences that we have a stored key
    await setBool(AppPreferenceKey.hasStoredApiKey.name, true);
  }

  static Future<String?> getApiKey() async {
    return _secureStorage.read(key: _apiKeyKey);
  }

  static Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
    await setBool(AppPreferenceKey.hasStoredApiKey.name, false);
  }

  static Future<bool> hasApiKey() async {
    return getBool(AppPreferenceKey.hasStoredApiKey.name, defaultValue: false);
  }

  // Specific methods for onboarding
  static Future<void> setOnboardingComplete() async {
    await setBool(AppPreferenceKey.hasSeenOnboarding.name, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    return getBool(
      AppPreferenceKey.hasSeenOnboarding.name,
      defaultValue: false,
    );
  }

  // Blur effects settings
  static Future<void> setBlurEffectsEnabled(bool enabled) async {
    await setBool(AppPreferenceKey.blurEffectsEnabled.name, enabled);
  }

  static Future<bool> blurEffectsEnabled() async {
    return getBool(
      AppPreferenceKey.blurEffectsEnabled.name,
      defaultValue: true,
    );
  }

  // Reset data
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Note: We don't clear the API key by default when resetting preferences
    // This would require explicit deleteApiKey() call
  }
}
