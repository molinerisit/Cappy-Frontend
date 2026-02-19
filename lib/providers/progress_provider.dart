import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../models/progress_model.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressModel _progress = const ProgressModel(
    xp: 0,
    level: 1,
    streak: 0,
    unlockedLessons: [],
    completedLessons: [],
  );

  bool _isLoading = false;
  Map<String, dynamic>? _lastNodeCompletion;

  ProgressModel get progress => _progress;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastNodeCompletion => _lastNodeCompletion;

  Future<void> loadProgress(String pathId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getProgress(pathId);
      _progress = ProgressModel.fromJson(data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el progreso desde la respuesta de completar un nodo
  void updateFromNodeCompletion(Map<String, dynamic> data) {
    _lastNodeCompletion = data;
    _progress = ProgressModel.fromJson(data['progress'] ?? data);
    notifyListeners();
  }

  void updateFromResponse(Map<String, dynamic> data) {
    _progress = ProgressModel.fromJson(data);
    notifyListeners();
  }
}
