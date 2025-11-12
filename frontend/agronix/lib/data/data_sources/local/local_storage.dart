// lib/data/data_sources/local/local_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _prefs?.setString('auth_token', token);
  }

  String? getToken() {
    return _prefs?.getString('auth_token');
  }

  Future<void> removeToken() async {
    await _prefs?.remove('auth_token');
  }

  // User Data Management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs?.setString('user_data', jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final userDataString = _prefs?.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> removeUserData() async {
    await _prefs?.remove('user_data');
  }

  // Generic Methods
  Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }
}
