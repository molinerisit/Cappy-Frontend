import 'package:flutter/foundation.dart';
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

  ProgressModel get progress => _progress;
  bool get isLoading => _isLoading;

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

  void updateFromResponse(Map<String, dynamic> data) {
    _progress = ProgressModel.fromJson(data);
    notifyListeners();
  }
}
