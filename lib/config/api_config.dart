import 'package:image_app/utils/app_preferences.dart';

class ApiConfig {
  // Method to get the stored API key
  static Future<String?> getGeminiApiKey() async {
    return AppPreferences.getApiKey();
  }

  // Enable additional debug logging
  static const bool enableDetailedLogging = true;
}
