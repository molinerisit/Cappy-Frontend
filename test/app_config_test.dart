import 'package:cooklevel_app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('can switch to staging environment', () {
      AppConfig.setEnvironment(AppEnvironment.staging);

      expect(AppConfig.isStaging, isTrue);
      expect(AppConfig.apiBaseUrl, 'https://api-staging.cooklevel.app/api');
      expect(AppConfig.apiTimeout, const Duration(seconds: 45));
      expect(AppConfig.isLoggingEnabled, isTrue);
    });

    test('can switch to production environment', () {
      AppConfig.setEnvironment(AppEnvironment.production);

      expect(AppConfig.isProduction, isTrue);
      expect(AppConfig.apiBaseUrl, 'https://api.cooklevel.app/api');
      expect(AppConfig.apiTimeout, const Duration(seconds: 60));
      expect(AppConfig.isLoggingEnabled, isFalse);
      expect(AppConfig.showDebugBanner, isFalse);
    });
  });
}
