import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado para feedback auditivo en la aplicación
/// Implementa el patrón Singleton para reutilización global
/// Pre-carga sonidos en memoria para latencia cero
class AudioFeedbackService {
  // Singleton pattern
  static final AudioFeedbackService _instance =
      AudioFeedbackService._internal();
  factory AudioFeedbackService() => _instance;
  AudioFeedbackService._internal();

  // Audio players separados para evitar conflictos de reproducción
  late AudioPlayer _pushPlayer;
  late AudioPlayer _removePlayer;
  late AudioPlayer _failPlayer;
  late AudioPlayer _alarmPlayer;

  bool _initialized = false;
  bool _initializing = false;
  // Marker to verify at runtime that the newest web bundle is running.
  static const String _debugBuildTag = 'AFS_20260309_push_mp3';
  static const String _pushAsset = 'sounds/push.mp3';
  static const String _failPrimaryAsset = 'sounds/fail.mp3';
  static const String _failFallbackAsset = 'sounds/alarma.mp3';
  static const String _alarmAsset = 'sounds/alarma.mp3';
  String _activeFailAsset = _failPrimaryAsset;

  /// Inicializa el servicio y pre-carga los assets de audio
  /// Debe ser llamado en main() antes de runApp()
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) return; // Evitar múltiples inicializaciones simultáneas

    _initializing = true;
    if (kDebugMode) {
      print(
        '[AudioFeedbackService][$_debugBuildTag] Inicializando service de audio',
      );
    }

    try {
      _pushPlayer = AudioPlayer();
      _removePlayer = AudioPlayer();
      _failPlayer = AudioPlayer();
      _alarmPlayer = AudioPlayer();

      // Configurar para mantener source después de reproducir
      await _pushPlayer.setReleaseMode(ReleaseMode.stop);
      await _removePlayer.setReleaseMode(ReleaseMode.stop);
      await _failPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);

      // Volumen máximo
      await _pushPlayer.setVolume(1.0);
      await _removePlayer.setVolume(1.0);
      await _failPlayer.setVolume(1.0);
      await _alarmPlayer.setVolume(1.0);

      _activeFailAsset = _failPrimaryAsset;
      _initialized = true;

      if (kDebugMode) {
        print(
          '[AudioFeedbackService][$_debugBuildTag] ✅ Inicialización exitosa',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[AudioFeedbackService][$_debugBuildTag] ❌ Error de inicialización: $e',
        );
      }
      _initialized = false;
    } finally {
      _initializing = false;
    }
  }

  /// Reproduce sonido al agregar un objeto interactivo
  Future<void> playAddObject() async {
    // Reintentar inicializar si no está disponible
    if (!_initialized && !_initializing) {
      await initialize();
    }

    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[AudioFeedbackService] ⚠️ No inicializado, ignorando playAddObject',
        );
      }
      return;
    }

    try {
      // play() con source automáticamente interrumpe reproducción en curso
      unawaited(
        _pushPlayer.play(AssetSource(_pushAsset)).catchError((Object error) {
          if (kDebugMode) {
            print('[AudioFeedbackService] ❌ Error reproduciendo ADD: $error');
          }
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ❌ Error al reproducir ADD: $e');
      }
    }
  }

  /// Reproduce sonido al remover un objeto interactivo
  /// Usa el mismo sonido que agregar, pero en player separado
  Future<void> playRemoveObject() async {
    // Reintentar inicializar si no está disponible
    if (!_initialized && !_initializing) {
      await initialize();
    }

    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[AudioFeedbackService] ⚠️ No inicializado, ignorando playRemoveObject',
        );
      }
      return;
    }

    try {
      unawaited(
        _removePlayer.play(AssetSource(_pushAsset)).catchError((Object error) {
          if (kDebugMode) {
            print(
              '[AudioFeedbackService] ❌ Error reproduciendo REMOVE: $error',
            );
          }
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ❌ Error al reproducir REMOVE: $e');
      }
    }
  }

  /// Reproduce sonido de error/fallo (quiz incorrecto, vida perdida)
  Future<void> playFail() async {
    // Reintentar inicializar si no está disponible
    if (!_initialized && !_initializing) {
      await initialize();
    }

    if (!_initialized) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ⚠️ No inicializado, ignorando playFail');
      }
      return;
    }

    try {
      unawaited(
        _failPlayer.play(AssetSource(_activeFailAsset)).catchError((
          Object error,
        ) async {
          if (kDebugMode) {
            print(
              '[AudioFeedbackService] ⚠️ Error al reproducir FAIL con $_activeFailAsset: $error',
            );
          }

          // Fallback a alarma.mp3 si fail.mp3 falla
          if (_activeFailAsset == _failPrimaryAsset) {
            _activeFailAsset = _failFallbackAsset;
            await _failPlayer.stop();
            await _failPlayer.play(AssetSource(_failFallbackAsset));
            if (kDebugMode) {
              print(
                '[AudioFeedbackService] 🔁 FAIL reproducido con fallback alarma.mp3',
              );
            }
          }
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ❌ Error al reproducir FAIL: $e');
      }
    }
  }

  /// Reproduce alarma al finalizar timers.
  Future<void> playAlarm() async {
    if (!_initialized && !_initializing) {
      await initialize();
    }

    if (!_initialized) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ⚠️ No inicializado, ignorando playAlarm');
      }
      return;
    }

    try {
      unawaited(
        _alarmPlayer.play(AssetSource(_alarmAsset)).catchError((Object error) {
          if (kDebugMode) {
            print(
              '[AudioFeedbackService] ❌ Error al reproducir ALARM con $_alarmAsset: $error',
            );
          }
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AudioFeedbackService] ❌ Error al reproducir ALARM: $e');
      }
    }
  }

  /// Limpia recursos de audio
  /// Debe ser llamado al cerrar la aplicación
  void dispose() {
    if (_initialized) {
      _pushPlayer.dispose();
      _removePlayer.dispose();
      _failPlayer.dispose();
      _alarmPlayer.dispose();
      _initialized = false;
      if (kDebugMode) {
        print('[AudioFeedbackService] 🧹 Recursos liberados');
      }
    }
  }
}
