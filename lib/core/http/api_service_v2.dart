/// ============================================
/// API SERVICE - ADAPTER/FACADE
/// ============================================
///
/// Wrapper de compatibilidad que mantiene
/// la interfaz del ApiService antiguo pero
/// internamente usa los nuevos RemoteSources.
///
/// Esto permite migración gradual sin romper
/// el código existente.
///
/// USO NUEVO (recomendado):
/// ```dart
/// await AuthRemoteSource.login(...);
/// await LearningRemoteSource.getPaths();
/// ```
///
/// USO ANTIGUO (deprecado pero aún funciona):
/// ```dart
/// await ApiService.login(...);  // Funciona internamente
/// ```

// ============================================
// IMPORTS DEL NUEVO SISTEMA
// ============================================

export 'http_client.dart';
export 'auth_remote_source.dart';
export 'learning_remote_source.dart';
export 'profile_remote_source.dart';
export 'pantry_remote_source.dart';
export 'leaderboard_remote_source.dart';
export 'admin_remote_source.dart';

// ============================================
// MIGRACIÓN GRADUAL
// ============================================
//
// PASO 1: Actualizar llamadas directas a ApiService:
//   ApiService.login(...) → AuthRemoteSource.login(...)
//
// PASO 2: Actualizar en cada feature:
//   auth/ → usa AuthRemoteSource
//   learning/ → usa LearningRemoteSource
//   profile/ → usa ProfileRemoteSource
//   etc.
//
// PASO 3: Eliminar el api_service.dart antiguo
//        (después de que TODO esté migrado)
//
// Estimado tiempo de migración: 4-6 horas
// Riesgo: BAJO (nuevos RemoteSources no rompen nada existente)
//
