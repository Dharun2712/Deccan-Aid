// lib/config/api_config.dart
// Note: No dart:io imports here to keep this file web-compatible; edit base URL below.

/// API Configuration for Smart Ambulance App
/// 
/// Update the [baseUrl] to your deployed backend URL in production.
/// For local development with ngrok: https://your-ngrok-subdomain.ngrok.io
/// For production: https://api.yourdomain.com
class ApiConfig {
  // Set API_BASE_URL using --dart-define for Cloud Run or other deployments.
  // Example:
  // flutter run --dart-define=API_BASE_URL=https://your-service-url.a.run.app
  static const String _defaultBaseUrl =
      "http://20.47.72.43:8000";
  static const String _apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: _defaultBaseUrl,
  );

  // Returns the configured API URL for all app environments.
  static String get baseUrl {
    return _apiBaseUrl;
  }

  // API Endpoints (computed to honor dynamic baseUrl)
  static String get loginClient => "$baseUrl/api/login/client";
  static String get loginDriver => "$baseUrl/api/login/driver";
  static String get loginAdmin => "$baseUrl/api/login/admin";
  static String get registerClient => "$baseUrl/api/register/client";
  static String get health => "$baseUrl/health";
  
  // ESP32 Accident Detection Endpoints
  static String get accident => "$baseUrl/api/accident";
  static String get accidents => "$baseUrl/api/accidents";
  
  // AI Image Analysis Endpoint
  static String get accidentImageAnalyze => "$baseUrl/api/accident-image/analyze";

  // First-aid chatbot
  static String get firstAidChat => "$baseUrl/api/first-aid/chat";

  // Voice AI (STT + TTS via Groq — no API keys in Flutter)
  static String get voiceStt => "$baseUrl/api/voice/stt";
  static String get voiceTts => "$baseUrl/api/voice/tts";
  static String get voiceHealth => "$baseUrl/api/voice/health";

  // Timeout configuration
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration voiceTimeout = Duration(seconds: 30); // STT + TTS can be slower

  // Storage keys
  static const String tokenKey = "auth_token";
  static const String roleKey = "user_role";
  static const String userIdKey = "user_id";
}
