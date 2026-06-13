enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
  });

  static late EnvConfig _instance;
  static EnvConfig get instance => _instance;

  static void initialize(Environment env) {
    switch (env) {
      case Environment.dev:
        _instance = const EnvConfig(
          environment: Environment.dev,
          apiBaseUrl: 'http://localhost:8000/api/v1',
        );
        break;
      case Environment.staging:
        _instance = const EnvConfig(
          environment: Environment.staging,
          apiBaseUrl: 'https://staging-api.smartaid.com/api/v1',
        );
        break;
      case Environment.prod:
        _instance = const EnvConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.smartaid.com/api/v1',
        );
        break;
    }
  }
}
