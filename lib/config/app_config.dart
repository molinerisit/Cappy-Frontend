// Multi-environment configuration for Cappy app.
// Supports dev, staging, and production with per-environment API settings.

enum AppEnvironment { dev, staging, production }

class AppConfig {
  static AppEnvironment _currentEnvironment = AppEnvironment.dev;
  static String? _apiBaseUrlOverride;
  static Duration? _apiTimeoutOverride;
  static bool? _enableLoggingOverride;

  /// Configuración por ambiente
  static final Map<AppEnvironment, _EnvironmentConfig> _configs = {
    AppEnvironment.dev: _EnvironmentConfig(
      apiBaseUrl: 'http://localhost:3000/api',
      apiTimeout: Duration(seconds: 30),
      enableLogging: true,
      name: 'Development',
      debugBanner: true,
    ),
    AppEnvironment.staging: _EnvironmentConfig(
      apiBaseUrl: 'https://api-staging.cooklevel.app/api',
      apiTimeout: Duration(seconds: 45),
      enableLogging: true,
      name: 'Staging',
      debugBanner: true,
    ),
    AppEnvironment.production: _EnvironmentConfig(
      apiBaseUrl: 'https://api.cooklevel.app/api',
      apiTimeout: Duration(seconds: 60),
      enableLogging: false,
      name: 'Production',
      debugBanner: false,
    ),
  };

  /// ✅ Inicializar configuración (llamar en main.dart)
  static void initialize({required AppEnvironment environment}) {
    _currentEnvironment = environment;
  }

  /// Inicializa AppConfig usando --dart-define o --dart-define-from-file.
  static void initializeFromDartDefine() {
    const rawEnvironment = String.fromEnvironment(
      'APP_ENVIRONMENT',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const rawTimeoutSeconds = String.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: '',
    );
    const rawDebugLogging = String.fromEnvironment(
      'DEBUG_LOGGING',
      defaultValue: '',
    );

    initialize(environment: _parseEnvironment(rawEnvironment));

    if (apiBaseUrl.isNotEmpty) {
      _apiBaseUrlOverride = apiBaseUrl;
    }

    if (rawTimeoutSeconds.isNotEmpty) {
      final timeoutSeconds = int.tryParse(rawTimeoutSeconds);
      if (timeoutSeconds != null && timeoutSeconds > 0) {
        _apiTimeoutOverride = Duration(seconds: timeoutSeconds);
      }
    }

    if (rawDebugLogging.isNotEmpty) {
      final normalized = rawDebugLogging.toLowerCase();
      if (normalized == 'true' || normalized == 'false') {
        _enableLoggingOverride = normalized == 'true';
      }
    }
  }

  static AppEnvironment _parseEnvironment(String rawEnvironment) {
    switch (rawEnvironment.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.dev;
    }
  }

  /// Obtener configuración del ambiente actual
  static _EnvironmentConfig get _config => _configs[_currentEnvironment]!;

  /// Obtener ambiente actual
  static AppEnvironment get currentEnvironment => _currentEnvironment;

  /// Cambiar ambiente (útil para testing/debugging)
  static void setEnvironment(AppEnvironment environment) {
    _currentEnvironment = environment;
  }

  /// Obtener URL base de API
  static String get apiBaseUrl => _apiBaseUrlOverride ?? _config.apiBaseUrl;

  /// Obtener timeout de requests
  static Duration get apiTimeout => _apiTimeoutOverride ?? _config.apiTimeout;

  /// ¿Loguear requests/responses?
  static bool get isLoggingEnabled =>
      _enableLoggingOverride ?? _config.enableLogging;

  /// Nombre del ambiente actual
  static String get environmentName => _config.name;

  /// ¿Mostrar debug banner?
  static bool get showDebugBanner => _config.debugBanner;

  /// ¿Es producción?
  static bool get isProduction =>
      _currentEnvironment == AppEnvironment.production;

  /// ¿Es desarrollo?
  static bool get isDevelopment => _currentEnvironment == AppEnvironment.dev;

  /// ¿Es staging?
  static bool get isStaging => _currentEnvironment == AppEnvironment.staging;
}

/// Configuración interna por ambiente
class _EnvironmentConfig {
  final String apiBaseUrl;
  final Duration apiTimeout;
  final bool enableLogging;
  final String name;
  final bool debugBanner;

  _EnvironmentConfig({
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.enableLogging,
    required this.name,
    required this.debugBanner,
  });
}
