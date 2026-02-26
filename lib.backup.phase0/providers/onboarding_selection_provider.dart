import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider para guardar la selección del onboarding
/// (qué modo eligió: objetivo o país, y cuál específico)
class OnboardingSelectionProvider extends ChangeNotifier {
  static const String _modeKey =
      'cooklevel_onboarding_mode'; // 'goals' o 'countries'
  static const String _selectionIdKey = 'cooklevel_onboarding_selection_id';
  static const String _selectionNameKey = 'cooklevel_onboarding_selection_name';

  final _storage = const FlutterSecureStorage();

  String? _mode; // 'goals' o 'countries'
  String? _selectionId; // ID del objetivo o país
  String? _selectionName; // Nombre del objetivo o país

  String? get mode => _mode;
  String? get selectionId => _selectionId;
  String? get selectionName => _selectionName;

  /// Guarda la selección del usuario
  Future<void> saveSelection({
    required String mode, // 'goals' o 'countries'
    required String selectionId,
    required String selectionName,
  }) async {
    _mode = mode;
    _selectionId = selectionId;
    _selectionName = selectionName;

    await Future.wait([
      _storage.write(key: _modeKey, value: mode),
      _storage.write(key: _selectionIdKey, value: selectionId),
      _storage.write(key: _selectionNameKey, value: selectionName),
    ]);

    notifyListeners();
  }

  /// Recupera la selección guardada
  Future<void> loadSelection() async {
    _mode = await _storage.read(key: _modeKey);
    _selectionId = await _storage.read(key: _selectionIdKey);
    _selectionName = await _storage.read(key: _selectionNameKey);
    notifyListeners();
  }

  /// Limpia la selección (llamar después de completar el registro)
  Future<void> clearSelection() async {
    _mode = null;
    _selectionId = null;
    _selectionName = null;

    await Future.wait([
      _storage.delete(key: _modeKey),
      _storage.delete(key: _selectionIdKey),
      _storage.delete(key: _selectionNameKey),
    ]);

    notifyListeners();
  }

  /// Verifica si hay una selección guardada
  bool hasSelection() => _mode != null && _selectionId != null;
}
