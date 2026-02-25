import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/onboarding_selection_provider.dart';

/// ============================================
/// APP INITIALIZER
/// ============================================
///
/// Maneja la inicialización de la aplicación
/// Ejecuta todas las operaciones paralelas necesarias
/// antes de que la app muestre UI.
///
/// Reemplaza múltiples splash screens y loading states
/// con UN ÚNICO punto de orquestación.

class AppInitializer {
  static const Duration _initializationTimeout = Duration(seconds: 30);

  /// Ejecuta TODAS las inicializaciones en paralelo
  static Future<void> initialize(BuildContext context) async {
    try {
      // Ejecutar todas las operaciones EN PARALELO
      await Future.wait<void>(
        [
          _initializeAuth(context),
          _initializeProgress(context),
          _initializeOnboarding(context),
          _preloadCriticalResources(context),
        ],
        eagerError: true, // Si una falla, fallan todas (fail fast)
      ).timeout(
        _initializationTimeout,
        onTimeout: () => throw TimeoutException(
          'AppInitializer exceeded ${_initializationTimeout.inSeconds}s',
        ),
      );

      debugPrint('✅ AppInitializer: Todas las inicializaciones completadas');
    } on TimeoutException catch (e) {
      debugPrint('❌ AppInitializer: Timeout - $e');
      rethrow;
    } catch (e, st) {
      debugPrint('❌ AppInitializer: Error - $e\n$st');
      rethrow;
    }
  }

  /// 1. Inicializar Auth (más crítico)
  static Future<void> _initializeAuth(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    debugPrint('✅ Auth initialized');
  }

  /// 2. Inicializar Progress
  static Future<void> _initializeProgress(BuildContext context) async {
    final progressProvider = context.read<ProgressProvider>();
    await progressProvider.initialize();
    debugPrint('✅ Progress initialized');
  }

  /// 3. Inicializar Onboarding
  static Future<void> _initializeOnboarding(BuildContext context) async {
    final onboardingProvider = context.read<OnboardingSelectionProvider>();
    await onboardingProvider.initialize();
    debugPrint('✅ Onboarding initialized');
  }

  /// 4. Precargar recursos críticos (imágenes, fuentes, etc)
  static Future<void> _preloadCriticalResources(BuildContext context) async {
    try {
      // Aquí irían precach de imágenes, fuentes, etc
      // Por ahora es placeholder pero importante dejar la estructura

      // Ejemplo: Precache de imágenes comunes
      // await precacheImage(AssetImage('assets/splash.png'), context);

      debugPrint('✅ Critical resources preloaded');
    } catch (e) {
      // No bloquear la app si fallan recursos secundarios
      debugPrint('⚠️ Warning: Preload recursos fallado - $e');
    }
  }
}

/// Excepción personalizada para timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
