import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  // Initialize authentication state
  Future<void> initializeAuth() async {
    _setLoading(true);

    try {
      final isAuth = await AuthService.isAuthenticated();
      if (isAuth) {
        final storedUser = await AuthService.getStoredUser();
        if (storedUser != null) {
          _user = storedUser;
          _isAuthenticated = true;

          // Try to refresh user data
          await _refreshUserData();
        } else {
          await _clearAuthState();
        }
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      await _clearAuthState();
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    UserRole role = UserRole.WARGA,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        role: role,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await AuthService.logout();
      await _clearAuthState();
    } catch (e) {
      await _clearAuthState();
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    try {
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile');
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    await _refreshUserData();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    await AuthService.clearAuth();
    notifyListeners();
  }

  Future<void> _refreshUserData() async {
    try {
      final response = await AuthService.getCurrentUser();
      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _clearAuthState();
      }
    } catch (e) {
      // Don't clear auth state on network errors, just log
      print('Failed to refresh user data: $e');
    }
  }

  // Check if user is citizen
  bool get isCitizen => _user?.role == UserRole.WARGA;

  // Check if user is officer
  bool get isOfficer => _user?.role == UserRole.PETUGAS;

  // Check if user is admin
  bool get isAdmin => _user?.role == UserRole.ADMIN;
}
