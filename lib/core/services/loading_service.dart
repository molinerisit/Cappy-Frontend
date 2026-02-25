import 'package:flutter/foundation.dart';

/// ============================================
/// LOADING SERVICE
/// ============================================
///
/// Servicio centralizado para gestionar
/// estados de carga en la aplicación.
///
/// Reemplaza spinners dispersos por
/// UN ÚNICO punto de verdad.
///
/// Uso:
/// ```dart
/// final loadingService = LoadingService();
///
/// // Marcar como cargando
/// loadingService.setLoading('auth', true);
///
/// // Leer estado
/// final isLoading = loadingService.isLoading('auth');
///
/// // Limpiar
/// loadingService.clearLoading('auth');
/// ```

class LoadingService extends ChangeNotifier {
  // Diccionario de estados de carga por key
  // Permite múltiples operaciones simultáneas independientes
  final Map<String, bool> _loadingStates = {};

  // Estados globales
  bool _isAppInitializing = true;
  bool _isNetworkBusy = false;

  /// La app está inicializándose
  bool get isAppInitializing => _isAppInitializing;

  /// Hay cualquier operación de red activa
  bool get isNetworkBusy => _isNetworkBusy;

  /// Complejidad actual (útil para debugging)
  int get _activeLoads => _loadingStates.values.where((v) => v).length;

  /// ====== PUBLIC METHODS ======

  /// Completar inicialización de la app
  void completeAppInitialization() {
    _isAppInitializing = false;
    notifyListeners();
    _debugLog('completeAppInitialization');
  }

  /// Establecer estado de carga para una operación específica
  void setLoading(String key, bool isLoading) {
    _loadingStates[key] = isLoading;

    // Actualizar estado global de red
    _isNetworkBusy = _loadingStates.values.any((v) => v);

    notifyListeners();
    _debugLog('setLoading($key, $isLoading)');
  }

  /// Verificar si una operación específica está cargando
  bool isLoading(String key) => _loadingStates[key] ?? false;

  /// Limpiar estado de carga (marcar como completo)
  void clearLoading(String key) {
    _loadingStates.remove(key);
    _isNetworkBusy = _loadingStates.values.any((v) => v);
    notifyListeners();
    _debugLog('clearLoading($key)');
  }

  /// Limpiar TODOS los estados de carga
  void clearAll() {
    _loadingStates.clear();
    _isNetworkBusy = false;
    notifyListeners();
    _debugLog('clearAll');
  }

  /// Ejecutar una función con loading automático
  /// Maneja la lógica de try/catch/finally internamente
  Future<T> withLoading<T>(
    String key,
    Future<T> Function() operation, {
    void Function(Object error, StackTrace st)? onError,
  }) async {
    try {
      setLoading(key, true);
      final result = await operation();
      return result;
    } catch (error, st) {
      onError?.call(error, st);
      _debugLog('Error in $key: $error');
      rethrow;
    } finally {
      clearLoading(key);
    }
  }

  /// Contar cuántas operaciones están activas
  /// Útil para debugging
  int get activeLoadingCount => _activeLoads;

  /// Obtener todas las operaciones activas
  /// Útil para logging
  List<String> get activeLoads =>
      _loadingStates.entries.where((e) => e.value).map((e) => e.key).toList();

  /// ====== PRIVATE METHODS ======

  void _debugLog(String message) {
    final active = activeLoads;
    final status = active.isEmpty ? 'idle' : 'active (${active.join(", ")})';
    if (kDebugMode) {
      print('🔄 LoadingService: $message | Status: $status');
    }
  }
}

/// ============================================
/// EXTENSIÓN HELPER PARA CONTEXT
/// ============================================
///
/// Permite acceder fácilmente a LoadingService
/// desde cualquier widget:
/// ```dart
/// context.loadingService.setLoading('key', true);
/// ```

extension LoadingServiceExtension on BuildContext {
  LoadingService get loadingService => read<LoadingService>();
}
