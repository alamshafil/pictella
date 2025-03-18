import 'app_preferences.dart';

/// Singleton class to manage app settings in memory
class AppSettings {
  // Private constructor
  AppSettings._();

  // Singleton instance
  static final AppSettings _instance = AppSettings._();

  // Getter for the instance
  static AppSettings get instance => _instance;

  // Settings properties
  bool _blurEffectsEnabled = true;

  // Getters for settings
  bool get blurEffectsEnabled => _blurEffectsEnabled;

  // Method to initialize settings from storage
  Future<void> initialize() async {
    _blurEffectsEnabled = await AppPreferences.getBool(
      AppPreferenceKey.blurEffectsEnabled.name,
      defaultValue: true,
    );
  }

  // Method to update blur effects setting
  Future<void> setBlurEffectsEnabled(bool value) async {
    _blurEffectsEnabled = value;
    await AppPreferences.setBool(
      AppPreferenceKey.blurEffectsEnabled.name,
      value,
    );
  }

  // Method to reset all settings
  Future<void> resetAll() async {
    _blurEffectsEnabled = true;
    await AppPreferences.resetAll();
  }
}
