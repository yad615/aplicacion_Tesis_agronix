// lib/presentation/view_models/auth_view_model.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  // Login
  Future<void> login(String username, String password) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      _currentUser = await _authRepository.login(username, password);
      _setState(AuthState.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
      rethrow;
    }
  }

  // Register
  Future<void> register(Map<String, dynamic> userData) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      _currentUser = await _authRepository.register(userData);
      _setState(AuthState.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
    }
  }

  // Check if user is logged in
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        _currentUser = await _authRepository.getCurrentUser();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);
    }
  }

  // Update Profile
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      _currentUser = await _authRepository.updateProfile(userData);
      _setState(AuthState.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
      rethrow;
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
