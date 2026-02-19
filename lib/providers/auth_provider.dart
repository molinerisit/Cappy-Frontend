import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = "cooklevel_jwt";
  static const _roleKey = "cooklevel_role";
  static const _totalXPKey = "cooklevel_totalxp";
  static const _levelKey = "cooklevel_level";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String _role = "user";
  int _totalXP = 0;
  int _level = 1;
  bool _isLoading = false;
  bool _isInitializing = true;

  String? get token => _token;
  String get role => _role;
  int get totalXP => _totalXP;
  int get level => _level;
  bool get isAdmin => _role == "admin";
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// ==============================
  /// INITIALIZE (usado por Splash)
  /// ==============================
  Future<void> initialize() async {
    try {
      _isInitializing = true;
      notifyListeners();

      // Read stored token, role, and user stats
      _token = await _storage.read(key: _tokenKey);
      _role = await _storage.read(key: _roleKey) ?? "user";
      final savedXP = await _storage.read(key: _totalXPKey);
      final savedLevel = await _storage.read(key: _levelKey);

      if (savedXP != null) {
        _totalXP = int.tryParse(savedXP) ?? 0;
      }
      if (savedLevel != null) {
        _level = int.tryParse(savedLevel) ?? 1;
      }

      // If token exists, set it in API service for later requests
      if (_token != null && _token!.isNotEmpty) {
        ApiService.setToken(_token!);
        // NOTE: Backend validation happens on first API call, not during splash
      } else {
        _token = null;
      }

      // Initialize complete - show login or main screen
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      // Log error locally if needed
      _token = null;
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// ==============================
  /// LOGIN
  /// ==============================
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await ApiService.login(email, password);

      final token = data["token"]?.toString() ?? "";
      final role = data["role"]?.toString() ?? "user";

      if (token.isEmpty) {
        throw Exception("No se recibió token del servidor");
      }

      _token = token;
      _role = role;

      ApiService.setToken(token);

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _roleKey, value: role);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ==============================
  /// REGISTER
  /// ==============================
  Future<void> register(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await ApiService.register(email, password);
      await login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ==============================
  /// LOGOUT
  /// ==============================
  Future<void> logout() async {
    await _clearSession();
  }

  /// ==============================
  /// UPDATE USER XP AND LEVEL
  /// ==============================
  Future<void> updateXPAndLevel(int xp, int level) async {
    _totalXP = xp;
    _level = level;

    await _storage.write(key: _totalXPKey, value: xp.toString());
    await _storage.write(key: _levelKey, value: level.toString());

    notifyListeners();
  }

  /// ==============================
  /// CLEAR SESSION (interno)
  /// ==============================
  Future<void> _clearSession() async {
    _token = null;
    _role = "user";
    _totalXP = 0;
    _level = 1;

    ApiService.logout();

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _totalXPKey);
    await _storage.delete(key: _levelKey);

    notifyListeners();
  }
}
